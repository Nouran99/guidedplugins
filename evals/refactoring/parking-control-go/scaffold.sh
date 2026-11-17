#!/usr/bin/env bash
set -e
mkdir -p src/parking

cat > src/parking/tariff.go <<'GO'
package parking

import (
	"errors"
	"fmt"
	"time"
)

// Grace is the free period after entry. It is our own pricing policy.
const Grace = 15 * time.Minute

// ExitWindow is how long a driver has to leave after paying. The city sets it. It is 15 minutes
// today, like Grace, but the two change for different reasons and are kept apart on purpose.
const ExitWindow = 15 * time.Minute

// MaxStay is the longest stay that is priced. The ticket machine refuses longer stays upstream.
const MaxStay = 14 * 24 * time.Hour

// Hourly rates in cents, charged per started hour.
const (
	carRateCents       int64 = 300
	motorbikeRateCents int64 = 150
	vanRateCents       int64 = 450
)

var (
	ErrExitBeforeEntry = errors.New("exit is before entry")
	ErrStayTooLong     = errors.New("stay is longer than the maximum")
)

// VehicleKind decides the hourly rate.
type VehicleKind int

const (
	Car VehicleKind = iota
	Motorbike
	Van
)

// freeDays are the public holidays on which a stay that starts on that day is free,
// as month-day in the garage's local calendar. The table is read-only.
var freeDays = map[string]bool{
	"01-01": true, // New Year's Day
	"05-01": true, // Labour Day
	"10-03": true, // Day of German Unity
	"11-01": true, // All Saints' Day
	"12-24": true, // Christmas Eve
	"12-25": true, // Christmas Day
	"12-26": true, // Boxing Day
	"12-31": true, // New Year's Eve
}

// Fee returns the parking fee in cents for a stay. A stay inside Grace is free, and so is a stay
// that starts on a free day. Anything else costs the hourly rate for every started hour.
func Fee(entry, exit time.Time, kind VehicleKind) (int64, error) {
	stay := exit.Sub(entry)
	if stay < 0 {
		return 0, ErrExitBeforeEntry
	}
	if stay > MaxStay {
		return 0, ErrStayTooLong
	}
	if stay <= Grace || isFreeDay(entry) {
		return 0, nil
	}
	rate, err := hourlyRateCents(kind)
	if err != nil {
		return 0, err
	}
	return rate * startedHours(stay), nil
}

func hourlyRateCents(kind VehicleKind) (int64, error) {
	switch kind {
	case Car:
		return carRateCents, nil
	case Motorbike:
		return motorbikeRateCents, nil
	case Van:
		return vanRateCents, nil
	default:
		return 0, fmt.Errorf("unknown vehicle kind %d", kind)
	}
}

func startedHours(stay time.Duration) int64 {
	hours := int64(stay / time.Hour)
	if stay%time.Hour != 0 {
		hours++
	}
	return hours
}

func isFreeDay(day time.Time) bool {
	return freeDays[day.Format("01-02")]
}
GO

cat > src/parking/checkout.go <<'GO'
package parking

import (
	"errors"
	"fmt"
	"time"
)

// ErrDeclined is returned when the card processor declines the charge.
var ErrDeclined = errors.New("payment declined")

// Gateway takes the payment for a ticket.
type Gateway interface {
	Charge(ticketRef string, cents int64) error
}

// ProcessorRequest and ProcessorResponse mirror the card processor's wire types.
type ProcessorRequest struct {
	Reference   string
	AmountMinor int64
	Currency    string
}

type ProcessorResponse struct {
	Status string // "approved" or "declined"
}

// statusApproved is the only status that means the money was taken.
const statusApproved = "approved"

// Processor is the part of the card processor's client that this package calls.
type Processor interface {
	Submit(ProcessorRequest) (ProcessorResponse, error)
}

// CardGateway adapts the processor's client to Gateway, so the processor's request types and
// status strings stay out of the pricing and kiosk code.
type CardGateway struct {
	processor Processor
	currency  string
}

func NewCardGateway(processor Processor, currency string) *CardGateway {
	return &CardGateway{processor: processor, currency: currency}
}

func (g *CardGateway) Charge(ticketRef string, cents int64) error {
	resp, err := g.processor.Submit(ProcessorRequest{Reference: ticketRef, AmountMinor: cents, Currency: g.currency})
	if err != nil {
		return fmt.Errorf("submit: %w", err)
	}
	if resp.Status != statusApproved {
		return ErrDeclined
	}
	return nil
}

// Kiosk takes the payment for a stay.
type Kiosk struct {
	gateway Gateway
	now     func() time.Time
}

// NewKiosk returns a kiosk that charges through gateway and reads the time from now.
func NewKiosk(gateway Gateway, now func() time.Time) *Kiosk {
	return &Kiosk{gateway: gateway, now: now}
}

// Pay charges the fee for a stay that started at entry and returns the time by which the car has
// to leave. A stay inside Grace costs nothing and never reaches the gateway.
func (k *Kiosk) Pay(ticketRef string, entry time.Time, kind VehicleKind) (time.Time, error) {
	paidAt := k.now()
	fee, err := Fee(entry, paidAt, kind)
	if err != nil {
		return time.Time{}, fmt.Errorf("ticket %s: %w", ticketRef, err)
	}
	if fee > 0 {
		if err := k.gateway.Charge(ticketRef, fee); err != nil {
			return time.Time{}, fmt.Errorf("ticket %s: charge: %w", ticketRef, err)
		}
	}
	return paidAt.Add(ExitWindow), nil
}
GO

cat > src/parking/tariff_test.go <<'GO'
package parking

import (
	"errors"
	"testing"
	"time"
)

var monday = time.Date(2026, time.March, 2, 9, 0, 0, 0, time.UTC)

func TestFeeIsFreeUpToAndIncludingTheGracePeriod(t *testing.T) {
	got, err := Fee(monday, monday.Add(Grace), Car)
	if err != nil || got != 0 {
		t.Fatalf("Fee = %d, %v; want 0, nil", got, err)
	}
}

func TestFeeChargesEveryStartedHour(t *testing.T) {
	cases := []struct {
		name string
		stay time.Duration
		want int64
	}{
		{"one minute past the grace period", Grace + time.Minute, 300},
		{"exactly one hour", time.Hour, 300},
		{"one hour and a minute", time.Hour + time.Minute, 600},
		{"three hours", 3 * time.Hour, 900},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, err := Fee(monday, monday.Add(c.stay), Car)
			if err != nil || got != c.want {
				t.Fatalf("Fee = %d, %v; want %d, nil", got, err, c.want)
			}
		})
	}
}

func TestFeeUsesTheRateOfTheVehicleKind(t *testing.T) {
	rates := map[VehicleKind]int64{Car: 300, Motorbike: 150, Van: 450}
	for kind, want := range rates {
		got, err := Fee(monday, monday.Add(time.Hour), kind)
		if err != nil || got != want {
			t.Fatalf("kind %d: Fee = %d, %v; want %d, nil", kind, got, err, want)
		}
	}
}

func TestFeeIsFreeWhenTheStayStartsOnAPublicHoliday(t *testing.T) {
	christmas := time.Date(2026, time.December, 25, 10, 0, 0, 0, time.UTC)
	got, err := Fee(christmas, christmas.Add(5*time.Hour), Car)
	if err != nil || got != 0 {
		t.Fatalf("Fee = %d, %v; want 0, nil", got, err)
	}
}

func TestFeeRejectsAnExitBeforeEntry(t *testing.T) {
	_, err := Fee(monday, monday.Add(-time.Minute), Car)
	if !errors.Is(err, ErrExitBeforeEntry) {
		t.Fatalf("err = %v; want ErrExitBeforeEntry", err)
	}
}

func TestFeeRejectsAStayLongerThanTheMaximum(t *testing.T) {
	_, err := Fee(monday, monday.Add(MaxStay+time.Minute), Car)
	if !errors.Is(err, ErrStayTooLong) {
		t.Fatalf("err = %v; want ErrStayTooLong", err)
	}
}

func TestFeeAcceptsAStayOfExactlyTheMaximum(t *testing.T) {
	got, err := Fee(monday, monday.Add(MaxStay), Car)
	if err != nil || got != 14*24*300 {
		t.Fatalf("Fee = %d, %v; want %d, nil", got, err, 14*24*300)
	}
}

func TestFeeReportsAnUnknownVehicleKind(t *testing.T) {
	if _, err := Fee(monday, monday.Add(time.Hour), VehicleKind(99)); err == nil {
		t.Fatal("want an error for an unknown vehicle kind")
	}
}
GO

cat > src/parking/checkout_test.go <<'GO'
package parking

import (
	"errors"
	"testing"
	"time"
)

type fakeGateway struct {
	charges []int64
	err     error
}

func (g *fakeGateway) Charge(ticketRef string, cents int64) error {
	if g.err != nil {
		return g.err
	}
	g.charges = append(g.charges, cents)
	return nil
}

type fakeProcessor struct {
	got    ProcessorRequest
	status string
	err    error
}

func (p *fakeProcessor) Submit(req ProcessorRequest) (ProcessorResponse, error) {
	p.got = req
	return ProcessorResponse{Status: p.status}, p.err
}

func clockAt(at time.Time) func() time.Time {
	return func() time.Time { return at }
}

func TestPayChargesTheFeeAndReturnsTheExitDeadline(t *testing.T) {
	gateway := &fakeGateway{}
	paidAt := monday.Add(2 * time.Hour)

	deadline, err := NewKiosk(gateway, clockAt(paidAt)).Pay("T-1", monday, Car)

	if err != nil {
		t.Fatalf("Pay: %v", err)
	}
	if len(gateway.charges) != 1 || gateway.charges[0] != 600 {
		t.Fatalf("charges = %v; want [600]", gateway.charges)
	}
	if want := paidAt.Add(ExitWindow); !deadline.Equal(want) {
		t.Fatalf("deadline = %v; want %v", deadline, want)
	}
}

func TestPayDoesNotChargeInsideTheGracePeriod(t *testing.T) {
	gateway := &fakeGateway{}

	_, err := NewKiosk(gateway, clockAt(monday.Add(10*time.Minute))).Pay("T-2", monday, Car)

	if err != nil || len(gateway.charges) != 0 {
		t.Fatalf("Pay = %v, charges %v; want nil, none", err, gateway.charges)
	}
}

func TestPayKeepsTheCauseWhenTheChargeFails(t *testing.T) {
	gateway := &fakeGateway{err: ErrDeclined}

	_, err := NewKiosk(gateway, clockAt(monday.Add(time.Hour))).Pay("T-3", monday, Car)

	if !errors.Is(err, ErrDeclined) {
		t.Fatalf("err = %v; want ErrDeclined", err)
	}
}

func TestCardGatewayMapsTheTicketToAProcessorRequest(t *testing.T) {
	processor := &fakeProcessor{status: "approved"}

	if err := NewCardGateway(processor, "EUR").Charge("T-4", 450); err != nil {
		t.Fatalf("Charge: %v", err)
	}

	want := ProcessorRequest{Reference: "T-4", AmountMinor: 450, Currency: "EUR"}
	if processor.got != want {
		t.Fatalf("request = %+v; want %+v", processor.got, want)
	}
}

func TestCardGatewayReportsADeclinedPayment(t *testing.T) {
	processor := &fakeProcessor{status: "declined"}

	err := NewCardGateway(processor, "EUR").Charge("T-5", 450)

	if !errors.Is(err, ErrDeclined) {
		t.Fatalf("err = %v; want ErrDeclined", err)
	}
}
GO
