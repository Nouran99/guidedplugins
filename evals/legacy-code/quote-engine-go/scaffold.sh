#!/usr/bin/env bash
set -e
mkdir -p src/quote

cat > src/quote/quote.go <<'GO'
package quote

import (
	"bytes"
	"encoding/json"
	"log"
	"math"
	"net/http"
	"os"
	"time"
)

var ratePerKg map[string]float64

func init() {
	raw, err := os.ReadFile("/etc/shipping/rates.json")
	if err != nil {
		log.Fatalf("cannot read rates: %v", err)
	}
	if err := json.Unmarshal(raw, &ratePerKg); err != nil {
		log.Fatalf("cannot parse rates: %v", err)
	}
}

// Request describes one parcel to be priced.
type Request struct {
	Zone     string
	WeightKg float64
	Express  bool
	Business bool
}

// Quote returns the shipping price in cents.
func Quote(r Request) int {
	perKg, ok := ratePerKg[r.Zone]
	if !ok {
		log.Fatalf("no rate for zone %q", r.Zone)
	}
	if r.WeightKg <= 0 {
		return 0
	}

	var price float64
	if r.WeightKg <= 2 {
		price = perKg * 2
	} else {
		if r.WeightKg <= 20 {
			price = perKg * r.WeightKg
		} else {
			price = perKg*20 + (r.WeightKg-20)*perKg*0.7
		}
	}

	if r.Express {
		price *= 1.6
		day := time.Now().Weekday()
		if day == time.Saturday || day == time.Sunday {
			price += 450
		}
	}
	if r.Business {
		price *= 0.92
	}

	cents := int(math.Round(price))
	body, _ := json.Marshal(map[string]any{"zone": r.Zone, "cents": cents})
	http.Post("https://metrics.internal/quotes", "application/json", bytes.NewReader(body))
	return cents
}
GO

cat > src/quote/quote_test.go <<'GO'
package quote

import "testing"

func TestQuoteReturnsAPrice(t *testing.T) {
	if got := Quote(Request{Zone: "EU", WeightKg: 1.5}); got <= 0 {
		t.Fatalf("Quote = %d, want a positive price", got)
	}
}

func TestQuoteIsZeroWithoutWeight(t *testing.T) {
	if got := Quote(Request{Zone: "EU", WeightKg: 0}); got != 0 {
		t.Fatalf("Quote = %d, want 0", got)
	}
}
GO
