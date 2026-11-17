#!/usr/bin/env bash
set -e
mkdir -p src/quotes

cat > src/quotes/consumer.go <<'GO'
package quotes

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"

	"github.com/segmentio/kafka-go"
)

type Consumer struct {
	reader *kafka.Reader
	db     *sql.DB
	quote  *QuoteShipping
}

func NewConsumer(reader *kafka.Reader, db *sql.DB, quote *QuoteShipping) *Consumer {
	return &Consumer{reader: reader, db: db, quote: quote}
}

func (c *Consumer) Run(ctx context.Context) error {
	for {
		msg, err := c.reader.FetchMessage(ctx)
		if err != nil {
			return err
		}
		if err := c.handle(ctx, msg); err != nil {
			log.Printf("quote message at offset %d failed: %v", msg.Offset, err)
		}
		if err := c.reader.CommitMessages(ctx, msg); err != nil {
			return err
		}
	}
}

func (c *Consumer) handle(ctx context.Context, msg kafka.Message) error {
	switch string(msg.Key) {
	case "quote.requested":
		var req struct {
			Account  string  `json:"account"`
			WeightKg float64 `json:"weight_kg"`
			Hazmat   bool    `json:"hazmat"`
		}
		if err := json.Unmarshal(msg.Value, &req); err != nil {
			return err
		}
		if req.WeightKg > 70 {
			log.Printf("parcel for %s is over the carrier limit", req.Account)
			return nil
		}
		service := "FEDEX_GROUND"
		if req.Hazmat && req.WeightKg > 20 {
			service = "FEDEX_FREIGHT"
		}
		offer, err := c.quote.Run(msg, service)
		if err != nil {
			return err
		}
		_, err = c.db.ExecContext(ctx,
			"insert into offers(id, account, expires_at, cents) values ($1, $2, $3, $4)",
			offer.ID, req.Account, offer.ExpiresAt, offer.Rate.TotalCents)
		return err
	case "quote.cancelled":
		var cancel struct {
			OfferID string `json:"offer_id"`
		}
		if err := json.Unmarshal(msg.Value, &cancel); err != nil {
			return err
		}
		_, err := c.db.ExecContext(ctx,
			"update offers set cancelled = true where id = $1", cancel.OfferID)
		return err
	}
	return nil
}
GO

cat > src/quotes/quote_shipping.go <<'GO'
package quotes

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/segmentio/kafka-go"

	"example.com/carriers/fedex"
)

type Offer struct {
	ID        string
	ExpiresAt time.Time
	Rate      *fedex.RateReply
}

type QuoteShipping struct {
	Carrier *fedex.Client
}

func (q *QuoteShipping) Run(msg kafka.Message, service string) (*Offer, error) {
	var req struct {
		Zone     string  `json:"zone"`
		WeightKg float64 `json:"weight_kg"`
	}
	if err := json.Unmarshal(msg.Value, &req); err != nil {
		return nil, err
	}

	reply, err := q.Carrier.GetRates(fedex.RateRequest{
		Service:    service,
		Zone:       req.Zone,
		Weight:     req.WeightKg,
		WeightUnit: "KG",
	})
	if err != nil {
		return nil, err
	}

	return &Offer{
		ID:        uuid.NewString(),
		ExpiresAt: time.Now().Add(15 * time.Minute),
		Rate:      reply,
	}, nil
}
GO

cat > src/quotes/quote_test.go <<'GO'
package quotes

import (
	"context"
	"database/sql"
	"os"
	"testing"
	"time"

	"github.com/segmentio/kafka-go"

	"example.com/carriers/fedex"
)

func TestOfferExpiresAfterFifteenMinutes(t *testing.T) {
	carrier := fedex.NewClient("https://apis-sandbox.fedex.com", os.Getenv("FEDEX_SANDBOX_KEY"))
	quote := &QuoteShipping{Carrier: carrier}
	msg := kafka.Message{
		Key:   []byte("quote.requested"),
		Value: []byte(`{"zone":"EU1","weight_kg":3}`),
	}

	offer, err := quote.Run(msg, "FEDEX_GROUND")
	if err != nil {
		t.Fatal(err)
	}

	remaining := time.Until(offer.ExpiresAt)
	if remaining > 15*time.Minute || remaining < 14*time.Minute {
		t.Fatalf("offer expires in %v, want about 15m", remaining)
	}
}

func TestParcelsOverSeventyKilosAreNotQuoted(t *testing.T) {
	db, err := sql.Open("postgres", os.Getenv("TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	writer := &kafka.Writer{Addr: kafka.TCP("localhost:9092"), Topic: "quote-requests"}
	defer writer.Close()

	err = writer.WriteMessages(context.Background(), kafka.Message{
		Key:   []byte("quote.requested"),
		Value: []byte(`{"account":"acme","zone":"EU1","weight_kg":80}`),
	})
	if err != nil {
		t.Fatal(err)
	}
	time.Sleep(3 * time.Second)

	var count int
	if err := db.QueryRow("select count(*) from offers where account = 'acme'").Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 0 {
		t.Fatalf("found %d offers for an oversize parcel", count)
	}
}
GO
