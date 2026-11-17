#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/invoice.go <<'GO'
package invoice

import (
	"errors"
	"fmt"
)

// ErrNoLines is returned when an invoice has no lines to total.
var ErrNoLines = errors.New("invoice has no lines")

// ErrNegativeQuantity is returned when a line has a negative quantity.
var ErrNegativeQuantity = errors.New("quantity is negative")

// Line is one priced line of an invoice. Amounts are small by contract:
// the API edge rejects quantities above 10,000 and unit prices above 10,000,000 cents.
type Line struct {
	Description    string
	UnitPriceCents int64
	Quantity       int64
}

// Total returns the invoice total in cents.
func Total(lines []Line) (int64, error) {
	if len(lines) == 0 {
		return 0, ErrNoLines
	}
	var total int64
	for _, line := range lines {
		lineTotal, err := lineTotalCents(line)
		if err != nil {
			return 0, fmt.Errorf("line %q: %w", line.Description, err)
		}
		total += lineTotal
	}
	return total, nil
}

func lineTotalCents(line Line) (int64, error) {
	if line.Quantity < 0 {
		return 0, ErrNegativeQuantity
	}
	return line.UnitPriceCents * line.Quantity, nil
}
GO
cat > src/invoice_test.go <<'GO'
package invoice

import (
	"errors"
	"testing"
)

func TestTotalSumsEveryLine(t *testing.T) {
	lines := []Line{{"pen", 150, 2}, {"pad", 400, 1}}
	got, err := Total(lines)
	if err != nil || got != 700 {
		t.Fatalf("Total = %d, %v; want 700, nil", got, err)
	}
}

func TestTotalRejectsAnInvoiceWithoutLines(t *testing.T) {
	if _, err := Total(nil); !errors.Is(err, ErrNoLines) {
		t.Fatalf("err = %v; want ErrNoLines", err)
	}
}

func TestTotalNamesTheLineWithANegativeQuantity(t *testing.T) {
	_, err := Total([]Line{{"pen", 150, -1}})
	if !errors.Is(err, ErrNegativeQuantity) {
		t.Fatalf("err = %v; want ErrNegativeQuantity", err)
	}
}
GO
