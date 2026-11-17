#!/usr/bin/env bash
set -e
mkdir -p src/kv

cat > src/kv/ring.go <<'GO'
package kv

import "hash/fnv"

// Node is one storage server.
type Node struct {
	Addr string
}

// Ring decides which nodes hold a key.
type Ring struct {
	nodes    []Node
	replicas int
}

func NewRing(nodes []Node, replicas int) *Ring {
	return &Ring{nodes: nodes, replicas: replicas}
}

func hashKey(key string) int {
	h := fnv.New32a()
	h.Write([]byte(key))
	return int(h.Sum32())
}

// Owners returns the replicas that hold key, starting with its home node.
func (r *Ring) Owners(key string) []Node {
	home := hashKey(key) % len(r.nodes)
	owners := make([]Node, 0, r.replicas)
	for i := 0; i < r.replicas; i++ {
		owners = append(owners, r.nodes[(home+i)%len(r.nodes)])
	}
	return owners
}

// Nodes returns every node in the cluster.
func (r *Ring) Nodes() []Node {
	return r.nodes
}
GO

cat > src/kv/client.go <<'GO'
package kv

import (
	"context"
	"errors"
	"time"
)

var (
	ErrNotEnoughAcks    = errors.New("kv: not enough replicas acknowledged the write")
	ErrNotEnoughReplies = errors.New("kv: not enough replicas answered the read")
)

// Versioned is a value as a node stores it.
type Versioned struct {
	Value     []byte
	UpdatedAt time.Time
	Deleted   bool
}

// Transport talks to one node.
type Transport interface {
	Put(ctx context.Context, n Node, key string, v Versioned) error
	Get(ctx context.Context, n Node, key string) (Versioned, bool, error)
	Scan(ctx context.Context, n Node, prefix string) (map[string]Versioned, error)
	Delete(ctx context.Context, n Node, key string) error
}

// Client writes each key to all N replicas and waits for W acknowledgements;
// it reads from the replicas until R of them have answered. The cluster runs
// with N=3, W=2, R=2. Because W+R > N, a read always sees the most recent write.
type Client struct {
	ring *Ring
	tr   Transport
	w, r int
}

func NewClient(ring *Ring, tr Transport, w, r int) *Client {
	return &Client{ring: ring, tr: tr, w: w, r: r}
}

// Put stores value under key.
func (c *Client) Put(ctx context.Context, key string, value []byte) error {
	v := Versioned{Value: value, UpdatedAt: time.Now()}
	acks := 0
	for _, n := range c.ring.Owners(key) {
		if err := c.tr.Put(ctx, n, key, v); err == nil {
			acks++
		}
	}
	if acks < c.w {
		return ErrNotEnoughAcks
	}
	return nil
}

// Get returns the newest value among the replicas that answer.
func (c *Client) Get(ctx context.Context, key string) ([]byte, bool, error) {
	var newest Versioned
	found, replies := false, 0
	for _, n := range c.ring.Owners(key) {
		v, ok, err := c.tr.Get(ctx, n, key)
		if err != nil {
			continue
		}
		replies++
		if ok && (!found || v.UpdatedAt.After(newest.UpdatedAt)) {
			newest, found = v, true
		}
		if replies == c.r {
			break
		}
	}
	if replies < c.r {
		return nil, false, ErrNotEnoughReplies
	}
	return newest.Value, found && !newest.Deleted, nil
}
GO

cat > src/kv/compactor.go <<'GO'
package kv

import (
	"context"
	"errors"
	"time"
)

var ErrLeaseExpired = errors.New("kv: lease expired during compaction")

// Lease is a time-limited claim on a name, granted by the coordination service.
type Lease struct {
	Name      string
	Token     uint64
	ExpiresAt time.Time
}

type LeaseStore interface {
	Acquire(ctx context.Context, name string, ttl time.Duration) (Lease, error)
	Release(ctx context.Context, l Lease) error
}

// Compactor physically removes deleted entries from a node. Only one
// compactor may work on a node at a time, which the lease guarantees.
type Compactor struct {
	leases LeaseStore
	tr     Transport
}

func (c *Compactor) Run(ctx context.Context, node Node) error {
	lease, err := c.leases.Acquire(ctx, "compact/"+node.Addr, 30*time.Second)
	if err != nil {
		return err
	}
	defer c.leases.Release(ctx, lease)

	entries, err := c.tr.Scan(ctx, node, "")
	if err != nil {
		return err
	}
	for key, v := range entries {
		if !v.Deleted {
			continue
		}
		if time.Now().After(lease.ExpiresAt) {
			return ErrLeaseExpired
		}
		if err := c.tr.Delete(ctx, node, key); err != nil {
			return err
		}
	}
	return nil
}
GO

cat > src/kv/services.go <<'GO'
package kv

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
)

var ErrInsufficientFunds = errors.New("kv: insufficient funds")

// Ledger keeps account balances in the cluster, one key per account.
type Ledger struct {
	client *Client
}

func NewLedger(client *Client) *Ledger {
	return &Ledger{client: client}
}

func (l *Ledger) balance(ctx context.Context, account string) (int64, error) {
	raw, ok, err := l.client.Get(ctx, "acct:"+account)
	if err != nil || !ok {
		return 0, err
	}
	return strconv.ParseInt(string(raw), 10, 64)
}

// Transfer moves cents from one account to another.
func (l *Ledger) Transfer(ctx context.Context, from, to string, cents int64) error {
	src, err := l.balance(ctx, from)
	if err != nil {
		return err
	}
	if src < cents {
		return ErrInsufficientFunds
	}
	dst, err := l.balance(ctx, to)
	if err != nil {
		return err
	}
	if err := l.client.Put(ctx, "acct:"+from, []byte(strconv.FormatInt(src-cents, 10))); err != nil {
		return err
	}
	return l.client.Put(ctx, "acct:"+to, []byte(strconv.FormatInt(dst+cents, 10)))
}

// Order is one entry stored under order:<id>.
type Order struct {
	ID         string `json:"id"`
	CustomerID string `json:"customer_id"`
	TotalCents int64  `json:"total_cents"`
}

type Orders struct {
	client *Client
	ring   *Ring
	tr     Transport
}

func (o *Orders) Save(ctx context.Context, order Order) error {
	raw, err := json.Marshal(order)
	if err != nil {
		return err
	}
	return o.client.Put(ctx, "order:"+order.ID, raw)
}

// ByCustomer lists a customer's orders. It backs the "my orders" page, the
// most visited page of the app.
func (o *Orders) ByCustomer(ctx context.Context, customerID string) ([]Order, error) {
	var out []Order
	seen := map[string]bool{}
	for _, n := range o.ring.Nodes() {
		entries, err := o.tr.Scan(ctx, n, "order:")
		if err != nil {
			return nil, err
		}
		for _, v := range entries {
			var order Order
			if v.Deleted || json.Unmarshal(v.Value, &order) != nil {
				continue
			}
			if order.CustomerID == customerID && !seen[order.ID] {
				seen[order.ID] = true
				out = append(out, order)
			}
		}
	}
	return out, nil
}
GO
