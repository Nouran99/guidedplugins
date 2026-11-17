#!/usr/bin/env bash
set -e
mkdir -p src/bookings/booking src/bookings/cancel src/bookings/sqlstore src/bookings/web

cat > src/bookings/booking/booking.go <<'GO'
// Package booking holds a room booking and the rules for cancelling it.
package booking

import (
	"errors"
	"time"
)

// CancellationNotice is how long before the start a booking can still be cancelled.
// The venue's terms promise a free cancellation up to 24 hours ahead.
const CancellationNotice = 24 * time.Hour

var (
	// ErrAlreadyCancelled is returned when a cancelled booking is cancelled again.
	ErrAlreadyCancelled = errors.New("booking is already cancelled")
	// ErrTooLate is returned when the start is less than CancellationNotice away.
	ErrTooLate = errors.New("booking can no longer be cancelled")
)

// Status is where a booking is in its life.
type Status string

const (
	Confirmed Status = "confirmed"
	Cancelled Status = "cancelled"
)

// Booking is one room reserved for one guest. Version counts the saved changes; the store
// uses it to notice that two people changed the same booking.
type Booking struct {
	ID      string
	GuestID string
	Room    string
	Starts  time.Time
	Status  Status
	Version int
}

// Cancel marks the booking cancelled. The caller passes the current time, so the rule
// never reads the clock itself.
func (b *Booking) Cancel(now time.Time) error {
	if b.Status == Cancelled {
		return ErrAlreadyCancelled
	}
	if b.Starts.Sub(now) < CancellationNotice {
		return ErrTooLate
	}
	b.Status = Cancelled
	return nil
}
GO

cat > src/bookings/booking/booking_test.go <<'GO'
package booking

import (
	"errors"
	"testing"
	"time"
)

var starts = time.Date(2026, time.March, 10, 15, 0, 0, 0, time.UTC)

func confirmed() *Booking {
	return &Booking{ID: "b-1", GuestID: "g-1", Room: "12", Starts: starts, Status: Confirmed}
}

func TestCancelMarksTheBookingCancelled(t *testing.T) {
	b := confirmed()
	if err := b.Cancel(starts.Add(-48 * time.Hour)); err != nil {
		t.Fatalf("Cancel = %v; want nil", err)
	}
	if b.Status != Cancelled {
		t.Fatalf("Status = %q; want %q", b.Status, Cancelled)
	}
}

func TestCancelIsAllowedExactlyAtTheNoticeLimit(t *testing.T) {
	b := confirmed()
	if err := b.Cancel(starts.Add(-CancellationNotice)); err != nil {
		t.Fatalf("Cancel = %v; want nil", err)
	}
}

func TestCancelInsideTheNoticePeriodIsRefusedAndChangesNothing(t *testing.T) {
	b := confirmed()
	err := b.Cancel(starts.Add(-CancellationNotice + time.Minute))
	if !errors.Is(err, ErrTooLate) {
		t.Fatalf("Cancel = %v; want ErrTooLate", err)
	}
	if b.Status != Confirmed {
		t.Fatalf("Status = %q; want it unchanged", b.Status)
	}
}

func TestCancelTwiceIsRefused(t *testing.T) {
	b := confirmed()
	if err := b.Cancel(starts.Add(-72 * time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err := b.Cancel(starts.Add(-72 * time.Hour)); !errors.Is(err, ErrAlreadyCancelled) {
		t.Fatalf("second Cancel = %v; want ErrAlreadyCancelled", err)
	}
}
GO

cat > src/bookings/cancel/cancel.go <<'GO'
// Package cancel is the use case "cancel a booking". It coordinates the steps and owns the
// transaction; the rules themselves live in package booking.
package cancel

import (
	"context"
	"errors"
	"time"

	"example.com/hotel/bookings/booking"
)

var (
	// ErrNotFound is returned when no booking has the given id.
	ErrNotFound = errors.New("booking not found")
	// ErrConflict is returned when the booking was saved by someone else after it was read.
	// Nothing is written; the caller reloads the booking and decides again.
	ErrConflict = errors.New("booking was changed by someone else")
)

// Store is the storage this use case needs. The Transactor hands out a Store bound to its
// transaction, so a Store never commits.
type Store interface {
	ByID(ctx context.Context, id string) (*booking.Booking, error)
	Save(ctx context.Context, b *booking.Booking) error
}

// Transactor runs fn in one transaction: it commits when fn returns nil and rolls back otherwise.
type Transactor interface {
	InTx(ctx context.Context, fn func(Store) error) error
}

// Notifier tells the guest. It is only called after the cancellation has been committed.
type Notifier interface {
	Cancelled(ctx context.Context, b booking.Booking) error
}

// Service cancels bookings.
type Service struct {
	tx       Transactor
	notifier Notifier
	now      func() time.Time
}

// NewService wires the use case; now is the clock.
func NewService(tx Transactor, notifier Notifier, now func() time.Time) *Service {
	return &Service{tx: tx, notifier: notifier, now: now}
}

// Result is what a cancellation returns. NoticeErr is set when the booking was cancelled but the
// guest could not be told; the cancellation stands either way.
type Result struct {
	Booking   booking.Booking
	NoticeErr error
}

// Cancel cancels the booking in one transaction, then notifies the guest.
func (s *Service) Cancel(ctx context.Context, id string) (Result, error) {
	var cancelled booking.Booking
	err := s.tx.InTx(ctx, func(store Store) error {
		b, err := store.ByID(ctx, id)
		if err != nil {
			return err
		}
		if err := b.Cancel(s.now()); err != nil {
			return err
		}
		if err := store.Save(ctx, b); err != nil {
			return err
		}
		cancelled = *b
		return nil
	})
	if err != nil {
		return Result{}, err
	}
	return Result{Booking: cancelled, NoticeErr: s.notifier.Cancelled(ctx, cancelled)}, nil
}
GO

cat > src/bookings/cancel/cancel_test.go <<'GO'
package cancel

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"example.com/hotel/bookings/booking"
)

var starts = time.Date(2026, time.March, 10, 15, 0, 0, 0, time.UTC)

// journal records what happened, in order.
type journal struct{ events []string }

func (j *journal) add(event string) { j.events = append(j.events, event) }

type fakeStore struct {
	journal  *journal
	bookings map[string]*booking.Booking
	saveErr  error
}

func (s *fakeStore) ByID(_ context.Context, id string) (*booking.Booking, error) {
	stored, ok := s.bookings[id]
	if !ok {
		return nil, ErrNotFound
	}
	loaded := *stored
	return &loaded, nil
}

func (s *fakeStore) Save(_ context.Context, b *booking.Booking) error {
	if s.saveErr != nil {
		return s.saveErr
	}
	s.journal.add("save")
	s.bookings[b.ID] = b
	return nil
}

type fakeTx struct{ store *fakeStore }

func (t fakeTx) InTx(_ context.Context, fn func(Store) error) error {
	if err := fn(t.store); err != nil {
		t.store.journal.add("rollback")
		return err
	}
	t.store.journal.add("commit")
	return nil
}

type fakeNotifier struct {
	journal *journal
	err     error
}

func (n fakeNotifier) Cancelled(_ context.Context, b booking.Booking) error {
	n.journal.add("notify " + b.ID)
	return n.err
}

func setup(now time.Time, saveErr, notifyErr error) (*Service, *journal) {
	j := &journal{}
	store := &fakeStore{
		journal: j,
		saveErr: saveErr,
		bookings: map[string]*booking.Booking{
			"b-1": {ID: "b-1", GuestID: "g-1", Room: "12", Starts: starts, Status: booking.Confirmed},
		},
	}
	return NewService(fakeTx{store}, fakeNotifier{j, notifyErr}, func() time.Time { return now }), j
}

func assertEvents(t *testing.T, j *journal, want ...string) {
	t.Helper()
	if !reflect.DeepEqual(j.events, want) {
		t.Fatalf("events = %v; want %v", j.events, want)
	}
}

func TestCancelSavesCommitsOnceAndThenNotifies(t *testing.T) {
	svc, j := setup(starts.Add(-72*time.Hour), nil, nil)
	got, err := svc.Cancel(context.Background(), "b-1")
	if err != nil || got.Booking.Status != booking.Cancelled || got.NoticeErr != nil {
		t.Fatalf("Cancel = %+v, %v; want a cancelled booking and no notice error", got, err)
	}
	assertEvents(t, j, "save", "commit", "notify b-1")
}

func TestCancelRollsBackAndStaysQuietWhenTheSaveFails(t *testing.T) {
	boom := errors.New("disk full")
	svc, j := setup(starts.Add(-72*time.Hour), boom, nil)
	if _, err := svc.Cancel(context.Background(), "b-1"); !errors.Is(err, boom) {
		t.Fatalf("Cancel = %v; want the save error", err)
	}
	assertEvents(t, j, "rollback")
}

func TestCancelInsideTheNoticePeriodSavesAndNotifiesNothing(t *testing.T) {
	svc, j := setup(starts.Add(-2*time.Hour), nil, nil)
	if _, err := svc.Cancel(context.Background(), "b-1"); !errors.Is(err, booking.ErrTooLate) {
		t.Fatalf("Cancel = %v; want ErrTooLate", err)
	}
	assertEvents(t, j, "rollback")
}

func TestCancelUnknownBooking(t *testing.T) {
	svc, _ := setup(starts.Add(-72*time.Hour), nil, nil)
	if _, err := svc.Cancel(context.Background(), "nope"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("Cancel = %v; want ErrNotFound", err)
	}
}

func TestCancelKeepsTheCancellationWhenTheNoticeFails(t *testing.T) {
	down := errors.New("mail server down")
	svc, j := setup(starts.Add(-72*time.Hour), nil, down)
	got, err := svc.Cancel(context.Background(), "b-1")
	if err != nil || got.Booking.Status != booking.Cancelled || !errors.Is(got.NoticeErr, down) {
		t.Fatalf("Cancel = %+v, %v; want a cancelled booking that carries the notice error", got, err)
	}
	assertEvents(t, j, "save", "commit", "notify b-1")
}
GO

cat > src/bookings/sqlstore/store.go <<'GO'
// Package sqlstore keeps bookings in SQL. The store it hands out takes part in the
// transaction that the Transactor opened and never commits on its own.
package sqlstore

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"example.com/hotel/bookings/booking"
	"example.com/hotel/bookings/cancel"
)

var _ cancel.Transactor = (*Transactor)(nil)

// Transactor implements cancel.Transactor on a *sql.DB.
type Transactor struct {
	db *sql.DB
}

// NewTransactor returns a Transactor for db.
func NewTransactor(db *sql.DB) *Transactor {
	return &Transactor{db: db}
}

// InTx begins a transaction, runs fn with a store bound to it and commits or rolls back.
func (t *Transactor) InTx(ctx context.Context, fn func(cancel.Store) error) error {
	tx, err := t.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	if err := fn(&store{tx: tx}); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}

type store struct {
	tx *sql.Tx
}

func (s *store) ByID(ctx context.Context, id string) (*booking.Booking, error) {
	b := booking.Booking{ID: id}
	var status string
	err := s.tx.QueryRowContext(ctx,
		`select guest_id, room, starts_at, status, version from bookings where id = ?`, id,
	).Scan(&b.GuestID, &b.Room, &b.Starts, &status, &b.Version)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, cancel.ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("load booking %s: %w", id, err)
	}
	b.Status = booking.Status(status)
	return &b, nil
}

// Save writes the status of the booking, and only if nobody saved it since it was read, that is, if
// its version is unchanged. The other fields are fixed when the booking is made. Two staff members
// rarely change the same booking at the same moment, so an optimistic check is enough and no row
// is locked.
func (s *store) Save(ctx context.Context, b *booking.Booking) error {
	res, err := s.tx.ExecContext(ctx,
		`update bookings set status = ?, version = version + 1 where id = ? and version = ?`,
		string(b.Status), b.ID, b.Version)
	if err != nil {
		return fmt.Errorf("save booking %s: %w", b.ID, err)
	}
	changed, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("save booking %s: %w", b.ID, err)
	}
	if changed != 1 {
		return cancel.ErrConflict
	}
	b.Version++
	return nil
}
GO

cat > src/bookings/sqlstore/store_test.go <<'GO'
package sqlstore

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	_ "modernc.org/sqlite"

	"example.com/hotel/bookings/booking"
	"example.com/hotel/bookings/cancel"
)

var starts = time.Date(2026, time.March, 10, 15, 0, 0, 0, time.UTC)

func newTransactor(t *testing.T) *Transactor {
	t.Helper()
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	db.SetMaxOpenConns(1)
	t.Cleanup(func() { db.Close() })
	_, err = db.Exec(`create table bookings (
		id text primary key, guest_id text, room text, starts_at timestamp, status text, version integer)`)
	if err != nil {
		t.Fatal(err)
	}
	_, err = db.Exec(`insert into bookings values ('b-1', 'g-1', '12', ?, 'confirmed', 0)`, starts)
	if err != nil {
		t.Fatal(err)
	}
	return NewTransactor(db)
}

func load(t *testing.T, tr *Transactor) *booking.Booking {
	t.Helper()
	var b *booking.Booking
	err := tr.InTx(context.Background(), func(s cancel.Store) (err error) {
		b, err = s.ByID(context.Background(), "b-1")
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func save(tr *Transactor, b *booking.Booking) error {
	return tr.InTx(context.Background(), func(s cancel.Store) error {
		return s.Save(context.Background(), b)
	})
}

func TestSavedBookingComesBackWithTheNextVersion(t *testing.T) {
	tr := newTransactor(t)
	b := load(t, tr)
	b.Status = booking.Cancelled
	if err := save(tr, b); err != nil {
		t.Fatal(err)
	}
	got := load(t, tr)
	if got.Status != booking.Cancelled || got.Version != 1 || !got.Starts.Equal(starts) {
		t.Fatalf("loaded %+v; want a cancelled booking at version 1 starting %v", got, starts)
	}
}

func TestSecondEditorWhoReadTheSameVersionGetsAConflict(t *testing.T) {
	tr := newTransactor(t)
	first, second := load(t, tr), load(t, tr)
	first.Status = booking.Cancelled
	if err := save(tr, first); err != nil {
		t.Fatal(err)
	}
	second.Status = booking.Cancelled
	if err := save(tr, second); !errors.Is(err, cancel.ErrConflict) {
		t.Fatalf("second save = %v; want ErrConflict", err)
	}
}

func TestFailureInsideTheTransactionRollsTheSaveBack(t *testing.T) {
	tr := newTransactor(t)
	boom := errors.New("later step failed")
	err := tr.InTx(context.Background(), func(s cancel.Store) error {
		b, err := s.ByID(context.Background(), "b-1")
		if err != nil {
			return err
		}
		b.Status = booking.Cancelled
		if err := s.Save(context.Background(), b); err != nil {
			return err
		}
		return boom
	})
	if !errors.Is(err, boom) {
		t.Fatalf("InTx = %v; want the later error", err)
	}
	if got := load(t, tr); got.Status != booking.Confirmed || got.Version != 0 {
		t.Fatalf("loaded %+v; want the booking untouched", got)
	}
}

func TestUnknownBookingIsNotFound(t *testing.T) {
	tr := newTransactor(t)
	err := tr.InTx(context.Background(), func(s cancel.Store) error {
		_, err := s.ByID(context.Background(), "nope")
		return err
	})
	if !errors.Is(err, cancel.ErrNotFound) {
		t.Fatalf("ByID = %v; want ErrNotFound", err)
	}
}
GO

cat > src/bookings/web/handler.go <<'GO'
// Package web is the HTTP edge: it reads the request, calls the use case and turns the
// outcome into a response.
package web

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"example.com/hotel/bookings/booking"
	"example.com/hotel/bookings/cancel"
)

// Canceller is the use case the handler calls.
type Canceller interface {
	Cancel(ctx context.Context, id string) (cancel.Result, error)
}

type cancelResponse struct {
	ID         string `json:"id"`
	Status     string `json:"status"`
	NoticeSent bool   `json:"noticeSent"`
}

// CancelHandler handles POST /bookings/{id}/cancel.
func CancelHandler(c Canceller) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		res, err := c.Cancel(r.Context(), r.PathValue("id"))
		if err != nil {
			writeError(w, err)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(cancelResponse{
			ID:         res.Booking.ID,
			Status:     string(res.Booking.Status),
			NoticeSent: res.NoticeErr == nil,
		})
	}
}

// writeError is the one place where use case errors become status codes.
func writeError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, cancel.ErrNotFound):
		http.Error(w, "unknown booking", http.StatusNotFound)
	case errors.Is(err, booking.ErrAlreadyCancelled), errors.Is(err, cancel.ErrConflict):
		http.Error(w, err.Error(), http.StatusConflict)
	case errors.Is(err, booking.ErrTooLate):
		http.Error(w, err.Error(), http.StatusUnprocessableEntity)
	default:
		http.Error(w, "internal error", http.StatusInternalServerError)
	}
}
GO

cat > src/bookings/web/handler_test.go <<'GO'
package web

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"example.com/hotel/bookings/booking"
	"example.com/hotel/bookings/cancel"
)

type fakeCanceller struct {
	res cancel.Result
	err error
}

func (f fakeCanceller) Cancel(_ context.Context, _ string) (cancel.Result, error) {
	return f.res, f.err
}

func post(c Canceller) *httptest.ResponseRecorder {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /bookings/{id}/cancel", CancelHandler(c))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/bookings/b-1/cancel", nil))
	return rec
}

func TestCancelHandlerTurnsEachOutcomeIntoAStatusCode(t *testing.T) {
	cases := []struct {
		name string
		err  error
		want int
	}{
		{"cancelled", nil, http.StatusOK},
		{"unknown booking", cancel.ErrNotFound, http.StatusNotFound},
		{"already cancelled", booking.ErrAlreadyCancelled, http.StatusConflict},
		{"changed by someone else", cancel.ErrConflict, http.StatusConflict},
		{"too late", booking.ErrTooLate, http.StatusUnprocessableEntity},
		{"unexpected failure", errors.New("boom"), http.StatusInternalServerError},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rec := post(fakeCanceller{err: tc.err})
			if rec.Code != tc.want {
				t.Fatalf("status = %d; want %d", rec.Code, tc.want)
			}
		})
	}
}

func TestCancelHandlerSaysWhenTheNoticeWasNotSent(t *testing.T) {
	stored := booking.Booking{ID: "b-1", Status: booking.Cancelled}
	rec := post(fakeCanceller{res: cancel.Result{Booking: stored, NoticeErr: errors.New("mail server down")}})
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d; want 200", rec.Code)
	}
	var body cancelResponse
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	if body.Status != "cancelled" || body.NoticeSent {
		t.Fatalf("body = %+v; want cancelled with noticeSent false", body)
	}
}
GO
