#!/usr/bin/env bash
set -e
mkdir -p src/export
cat > src/export/rates.go <<'GO'
package export

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"
)

var rates = map[string]float64{}

// StartRefresh reloads the euro exchange rates every ten minutes until ctx is cancelled.
func StartRefresh(ctx context.Context, url string) {
	go func() {
		for {
			refresh(url)
			select {
			case <-ctx.Done():
				return
			case <-time.After(10 * time.Minute):
			}
		}
	}()
}

func refresh(url string) {
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("rates refresh: %v", err)
		return
	}
	defer resp.Body.Close()

	var fresh map[string]float64
	if err := json.NewDecoder(resp.Body).Decode(&fresh); err != nil {
		log.Printf("rates refresh: %v", err)
		return
	}

	for currency := range rates {
		delete(rates, currency)
	}
	for currency, rate := range fresh {
		rates[currency] = rate
	}
}

// ToEUR converts an amount in cents from the given currency into euro cents.
func ToEUR(cents int64, currency string) int64 {
	return int64(float64(cents) * rates[currency])
}
GO
cat > src/export/exporter.go <<'GO'
package export

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

// Exporter writes the invoice files the finance team imports every morning.
type Exporter struct {
	DB *sql.DB
}

// ExportInvoices writes one CSV file per customer with the amounts in euro cents.
func (e *Exporter) ExportInvoices(customerIDs []string) error {
	dir := os.Getenv("EXPORT_DIR")
	stamp := time.Now().Format("20060102-150405")

	for _, id := range customerIDs {
		path := filepath.Join(dir, fmt.Sprintf("%s-%s.csv", id, stamp))
		f, err := os.Create(path)
		if err != nil {
			return fmt.Errorf("export failed")
		}
		w := csv.NewWriter(f)

		rows, err := e.DB.Query(
			"SELECT number, currency, cents, tax_id FROM invoices WHERE customer_id = ?", id)
		if err != nil {
			return fmt.Errorf("export failed")
		}
		for rows.Next() {
			var number, currency string
			var cents, taxID int64
			if err := rows.Scan(&number, &currency, &cents, &taxID); err != nil {
				return fmt.Errorf("export failed")
			}

			var taxCode string
			if err := e.DB.QueryRow("SELECT code FROM tax_codes WHERE id = ?", taxID).Scan(&taxCode); err != nil {
				return fmt.Errorf("export failed")
			}

			w.Write([]string{number, taxCode, strconv.FormatInt(ToEUR(cents, currency), 10)})
		}
		rows.Close()
		w.Flush()
		f.Close()
	}
	return nil
}
GO
cat > src/export/nightly.go <<'GO'
package export

import (
	"log"
	"strings"
)

// RunNightly exports every customer's invoices and tries again when the export timed out.
func RunNightly(e *Exporter, customerIDs []string) {
	for attempt := 1; attempt <= 3; attempt++ {
		err := e.ExportInvoices(customerIDs)
		if err == nil {
			return
		}
		if !strings.Contains(err.Error(), "timeout") {
			log.Printf("nightly export: %v", err)
			return
		}
	}
}
GO
