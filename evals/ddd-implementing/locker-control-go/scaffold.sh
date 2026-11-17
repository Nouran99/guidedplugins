#!/usr/bin/env bash
set -e
mkdir -p src/lockers
cat > src/lockers/README.md <<'MD'
# Lockers

Bounded context for parcel lockers: a carrier deposits a parcel in a compartment, the recipient picks it up with a pickup code, or the parcel goes back to the carrier when the pickup window closes.

- Subdomain: core. How long we hold a parcel and who may take it is why carriers choose our lockers, so this is where the modeling effort goes.
- Layout: the context is small, so the model (deposit.go) and its use cases (service.go) share the package lockers. Adapters live under src/infra.
- Compartment sizes are reference data from the hardware team: plain data, no rules.
- Neighbour, upstream: the locker vendor reports door states over a telemetry feed. We are downstream and translate their status codes in vendor_status.go; their codes appear nowhere else.
- Neighbour, downstream: notifications reads ParcelDeposited and ParcelPickedUp messages, which a publisher in src/infra maps from our events, and messages the recipient. Lockers never calls notifications.
- This change covers picking up and expiring a parcel. Placing a parcel, and choosing a free compartment, arrive in a later change.
- Persistence, and the publisher that maps our events, are adapters under src/infra, reviewed separately; the change that adds them also adds the way to rebuild a stored Deposit.
- Terms: parcel, deposit (a parcel placed in a compartment), compartment, pickup code, pickup window, pick up, expire.
MD
cat > src/lockers/deposit.go <<'GO'
package lockers

import (
	"errors"
	"time"
)

// DepositID identifies one parcel deposit.
type DepositID string

// CompartmentID identifies one compartment in a locker bank.
type CompartmentID string

// PickupWindow is how long a recipient has to pick a parcel up before it goes back to the carrier.
const PickupWindow = 72 * time.Hour

var (
	ErrBadPickupCode = errors.New("pickup code must be six digits")
	ErrNotWaiting    = errors.New("deposit is not waiting for pickup")
	ErrWrongCode     = errors.New("pickup code does not match")
	ErrWindowClosed  = errors.New("pickup window has closed")
	ErrWindowOpen    = errors.New("pickup window is still open")
)

// PickupCode is the six-digit code a recipient types at the locker. NewPickupCode is how one is made.
type PickupCode struct{ digits string }

// NewPickupCode checks a code as it enters the model, so every PickupCode in the system is valid.
func NewPickupCode(s string) (PickupCode, error) {
	if len(s) != 6 {
		return PickupCode{}, ErrBadPickupCode
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return PickupCode{}, ErrBadPickupCode
		}
	}
	return PickupCode{digits: s}, nil
}

// String returns the digits as typed, leading zeros included.
func (c PickupCode) String() string { return c.digits }

// Event is a business fact the model reports after it happened.
type Event interface {
	OccurredAt() time.Time
}

type ParcelDeposited struct {
	EventID     string
	DepositID   DepositID
	Compartment CompartmentID
	At          time.Time
}

type ParcelPickedUp struct {
	EventID     string
	DepositID   DepositID
	Compartment CompartmentID
	At          time.Time
}

type PickupWindowExpired struct {
	EventID     string
	DepositID   DepositID
	Compartment CompartmentID
	At          time.Time
}

func (e ParcelDeposited) OccurredAt() time.Time     { return e.At }
func (e ParcelPickedUp) OccurredAt() time.Time      { return e.At }
func (e PickupWindowExpired) OccurredAt() time.Time { return e.At }

type state int

const (
	waiting state = iota
	pickedUp
	expired
)

// Deposit is a parcel placed in one compartment, held until the recipient picks it up or the window closes.
type Deposit struct {
	id          DepositID
	compartment CompartmentID
	code        PickupCode
	depositedAt time.Time
	state       state
}

// NewDeposit records a carrier placing a parcel in a compartment.
func NewDeposit(id DepositID, compartment CompartmentID, code PickupCode, now time.Time) (*Deposit, ParcelDeposited) {
	d := &Deposit{id: id, compartment: compartment, code: code, depositedAt: now, state: waiting}
	return d, ParcelDeposited{EventID: eventID(id, "deposited"), DepositID: id, Compartment: compartment, At: now}
}

func (d *Deposit) ID() DepositID { return d.id }

// PickUp lets the recipient take the parcel with the right code while the window is open.
func (d *Deposit) PickUp(code PickupCode, now time.Time) (ParcelPickedUp, error) {
	if d.state != waiting {
		return ParcelPickedUp{}, ErrNotWaiting
	}
	if now.After(d.windowClosesAt()) {
		return ParcelPickedUp{}, ErrWindowClosed
	}
	if code != d.code {
		return ParcelPickedUp{}, ErrWrongCode
	}
	d.state = pickedUp
	return ParcelPickedUp{EventID: eventID(d.id, "picked-up"), DepositID: d.id, Compartment: d.compartment, At: now}, nil
}

// Expire sends the parcel back to the carrier once the window has closed.
func (d *Deposit) Expire(now time.Time) (PickupWindowExpired, error) {
	if d.state != waiting {
		return PickupWindowExpired{}, ErrNotWaiting
	}
	if !now.After(d.windowClosesAt()) {
		return PickupWindowExpired{}, ErrWindowOpen
	}
	d.state = expired
	return PickupWindowExpired{EventID: eventID(d.id, "expired"), DepositID: d.id, Compartment: d.compartment, At: now}, nil
}

func (d *Deposit) windowClosesAt() time.Time { return d.depositedAt.Add(PickupWindow) }

// A deposit moves through each of these facts at most once, so the id of the deposit plus the fact identifies the event.
func eventID(id DepositID, fact string) string { return string(id) + "/" + fact }
GO
cat > src/lockers/service.go <<'GO'
package lockers

import (
	"context"
	"time"
)

// Deposits finds and stores deposits. A deposit is the whole aggregate.
type Deposits interface {
	ByID(ctx context.Context, id DepositID) (*Deposit, error)
	Save(ctx context.Context, d *Deposit) error
}

// Events carries the facts a use case produced to whoever listens, after the deposit is saved.
type Events interface {
	Publish(ctx context.Context, events ...Event) error
}

// Clock gives use cases the current time.
type Clock interface {
	Now() time.Time
}

// PickUpCommand is "a recipient typed a code at a locker".
type PickUpCommand struct {
	DepositID DepositID
	Code      string
}

// Service holds the use cases of the lockers context.
type Service struct {
	deposits Deposits
	events   Events
	clock    Clock
}

func NewService(deposits Deposits, events Events, clock Clock) *Service {
	return &Service{deposits: deposits, events: events, clock: clock}
}

// PickUp loads the deposit, lets it decide, saves it and publishes the fact.
func (s *Service) PickUp(ctx context.Context, cmd PickUpCommand) error {
	code, err := NewPickupCode(cmd.Code)
	if err != nil {
		return err
	}
	d, err := s.deposits.ByID(ctx, cmd.DepositID)
	if err != nil {
		return err
	}
	picked, err := d.PickUp(code, s.clock.Now())
	if err != nil {
		return err
	}
	if err := s.deposits.Save(ctx, d); err != nil {
		return err
	}
	return s.events.Publish(ctx, picked)
}

// ExpireWindow is run by the scheduler for a deposit whose pickup window may have closed.
func (s *Service) ExpireWindow(ctx context.Context, id DepositID) error {
	d, err := s.deposits.ByID(ctx, id)
	if err != nil {
		return err
	}
	closed, err := d.Expire(s.clock.Now())
	if err != nil {
		return err
	}
	if err := s.deposits.Save(ctx, d); err != nil {
		return err
	}
	return s.events.Publish(ctx, closed)
}
GO
cat > src/lockers/vendor_status.go <<'GO'
package lockers

import "fmt"

// DoorState is what the locker bank tells us about one compartment door, in our words.
type DoorState int

const (
	DoorClosed DoorState = iota
	DoorOpen
	DoorJammed
)

// UnknownVendorStatusError reports a status code the vendor sent that we have no word for.
type UnknownVendorStatusError struct{ Code string }

func (e UnknownVendorStatusError) Error() string {
	return fmt.Sprintf("unknown vendor door status %q", e.Code)
}

// DoorStateFromVendor translates a status code of the vendor's telemetry feed. The telemetry adapter
// calls it for every message, so a code we do not know surfaces as an error instead of a guess.
func DoorStateFromVendor(code string) (DoorState, error) {
	switch code {
	case "DR_CL":
		return DoorClosed, nil
	case "DR_OP":
		return DoorOpen, nil
	case "DR_JM":
		return DoorJammed, nil
	default:
		return 0, UnknownVendorStatusError{Code: code}
	}
}
GO
cat > src/lockers/sizes.go <<'GO'
package lockers

// CompartmentSize is a size class from the hardware team's catalogue.
type CompartmentSize struct {
	Code     string
	WidthCm  int
	HeightCm int
	DepthCm  int
}

// CompartmentSizes is maintained by the hardware team and changes with each new locker model.
var CompartmentSizes = []CompartmentSize{
	{Code: "S", WidthCm: 35, HeightCm: 10, DepthCm: 45},
	{Code: "M", WidthCm: 35, HeightCm: 20, DepthCm: 45},
	{Code: "L", WidthCm: 35, HeightCm: 40, DepthCm: 45},
}
GO
cat > src/lockers/deposit_test.go <<'GO'
package lockers

import (
	"errors"
	"testing"
	"time"
)

var droppedOffAt = time.Date(2024, 5, 6, 9, 0, 0, 0, time.UTC)

func aPickupCode(t *testing.T, digits string) PickupCode {
	t.Helper()
	code, err := NewPickupCode(digits)
	if err != nil {
		t.Fatalf("NewPickupCode(%q): %v", digits, err)
	}
	return code
}

func aWaitingDeposit(t *testing.T) *Deposit {
	t.Helper()
	d, _ := NewDeposit("dep-1", "bank-A/12", aPickupCode(t, "123456"), droppedOffAt)
	return d
}

func TestDepositingAParcelReportsWhereItWentAndWhen(t *testing.T) {
	_, deposited := NewDeposit("dep-1", "bank-A/12", aPickupCode(t, "123456"), droppedOffAt)
	if deposited.DepositID != "dep-1" || deposited.Compartment != "bank-A/12" || !deposited.At.Equal(droppedOffAt) {
		t.Fatalf("event = %+v", deposited)
	}
}

func TestRecipientWithTheRightCodePicksUpTheParcel(t *testing.T) {
	d := aWaitingDeposit(t)
	picked, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(time.Hour))
	if err != nil {
		t.Fatalf("PickUp: %v", err)
	}
	if picked.EventID != "dep-1/picked-up" || picked.Compartment != "bank-A/12" {
		t.Fatalf("event = %+v", picked)
	}
}

func TestAWrongCodeIsRejectedAndTheParcelStaysWaiting(t *testing.T) {
	d := aWaitingDeposit(t)
	picked, err := d.PickUp(aPickupCode(t, "654321"), droppedOffAt.Add(time.Hour))
	if !errors.Is(err, ErrWrongCode) {
		t.Fatalf("err = %v, want ErrWrongCode", err)
	}
	if picked.DepositID != "" {
		t.Fatalf("a rejected pickup reported %+v", picked)
	}
	if _, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(2*time.Hour)); err != nil {
		t.Fatalf("right code after a rejected one: %v", err)
	}
}

func TestPickingUpAfterTheWindowClosedIsRejected(t *testing.T) {
	d := aWaitingDeposit(t)
	_, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(PickupWindow+time.Minute))
	if !errors.Is(err, ErrWindowClosed) {
		t.Fatalf("err = %v, want ErrWindowClosed", err)
	}
}

func TestAParcelCannotBePickedUpTwice(t *testing.T) {
	d := aWaitingDeposit(t)
	if _, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(time.Hour)); err != nil {
		t.Fatalf("first PickUp: %v", err)
	}
	if _, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(2*time.Hour)); !errors.Is(err, ErrNotWaiting) {
		t.Fatalf("second PickUp err = %v, want ErrNotWaiting", err)
	}
}

func TestARecipientCanStillPickUpAtTheMomentTheWindowCloses(t *testing.T) {
	d := aWaitingDeposit(t)
	if _, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(PickupWindow)); err != nil {
		t.Fatalf("PickUp at the closing instant: %v", err)
	}
}

func TestAfterTheWindowClosesTheDepositExpiresAndReportsIt(t *testing.T) {
	d := aWaitingDeposit(t)
	later := droppedOffAt.Add(PickupWindow + time.Minute)
	expired, err := d.Expire(later)
	if err != nil {
		t.Fatalf("Expire: %v", err)
	}
	if expired.EventID != "dep-1/expired" || expired.Compartment != "bank-A/12" || !expired.At.Equal(later) {
		t.Fatalf("event = %+v", expired)
	}
}

func TestTheWindowCannotBeExpiredWhileItIsStillOpen(t *testing.T) {
	d := aWaitingDeposit(t)
	expired, err := d.Expire(droppedOffAt.Add(PickupWindow))
	if !errors.Is(err, ErrWindowOpen) {
		t.Fatalf("err = %v, want ErrWindowOpen", err)
	}
	if expired.DepositID != "" {
		t.Fatalf("a rejected expiry reported %+v", expired)
	}
}

func TestAnExpiredParcelCannotBePickedUp(t *testing.T) {
	d := aWaitingDeposit(t)
	if _, err := d.Expire(droppedOffAt.Add(PickupWindow + time.Minute)); err != nil {
		t.Fatalf("Expire: %v", err)
	}
	if _, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(PickupWindow+2*time.Minute)); !errors.Is(err, ErrNotWaiting) {
		t.Fatalf("PickUp after expiry err = %v, want ErrNotWaiting", err)
	}
}

func TestAParcelThatWasPickedUpCannotBeExpired(t *testing.T) {
	d := aWaitingDeposit(t)
	if _, err := d.PickUp(aPickupCode(t, "123456"), droppedOffAt.Add(time.Hour)); err != nil {
		t.Fatalf("PickUp: %v", err)
	}
	expired, err := d.Expire(droppedOffAt.Add(PickupWindow + time.Minute))
	if !errors.Is(err, ErrNotWaiting) {
		t.Fatalf("Expire after pickup err = %v, want ErrNotWaiting", err)
	}
	if expired.DepositID != "" {
		t.Fatalf("a rejected expiry reported %+v", expired)
	}
}

func TestAnExpiredParcelCannotBeExpiredAgain(t *testing.T) {
	d := aWaitingDeposit(t)
	if _, err := d.Expire(droppedOffAt.Add(PickupWindow + time.Minute)); err != nil {
		t.Fatalf("first Expire: %v", err)
	}
	if _, err := d.Expire(droppedOffAt.Add(PickupWindow + 2*time.Minute)); !errors.Is(err, ErrNotWaiting) {
		t.Fatalf("second Expire err = %v, want ErrNotWaiting", err)
	}
}
GO
cat > src/lockers/pickup_code_test.go <<'GO'
package lockers

import (
	"errors"
	"testing"
)

func TestAPickupCodeMustBeSixDigits(t *testing.T) {
	for _, bad := range []string{"", "12345", "1234567", "12a456", "12 456"} {
		if _, err := NewPickupCode(bad); !errors.Is(err, ErrBadPickupCode) {
			t.Errorf("NewPickupCode(%q) err = %v, want ErrBadPickupCode", bad, err)
		}
	}
}

func TestSixDigitsIncludingLeadingZerosMakeAPickupCode(t *testing.T) {
	for _, good := range []string{"123456", "000000", "007042"} {
		code, err := NewPickupCode(good)
		if err != nil || code.String() != good {
			t.Errorf("NewPickupCode(%q) = %q, %v; want the same digits, nil", good, code, err)
		}
	}
}

func TestTwoPickupCodesWithTheSameDigitsAreTheSameCode(t *testing.T) {
	if aPickupCode(t, "007042") != aPickupCode(t, "007042") {
		t.Fatal("two codes with the same digits are different")
	}
	if aPickupCode(t, "007042") == aPickupCode(t, "007043") {
		t.Fatal("two codes with different digits are the same")
	}
}
GO
cat > src/lockers/service_test.go <<'GO'
package lockers

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"
)

var errNotFound = errors.New("deposit not found")

// journal records the order in which a use case calls its ports.
type journal struct{ names []string }

func (j *journal) record(name string) { j.names = append(j.names, name) }

type fakeDeposits struct {
	byID  map[DepositID]*Deposit
	calls *journal
}

func (f *fakeDeposits) ByID(_ context.Context, id DepositID) (*Deposit, error) {
	f.calls.record("load")
	d, ok := f.byID[id]
	if !ok {
		return nil, errNotFound
	}
	return d, nil
}

func (f *fakeDeposits) Save(_ context.Context, d *Deposit) error {
	f.calls.record("save")
	f.byID[d.ID()] = d
	return nil
}

type fakeEvents struct {
	published []Event
	calls     *journal
}

func (f *fakeEvents) Publish(_ context.Context, events ...Event) error {
	f.calls.record("publish")
	f.published = append(f.published, events...)
	return nil
}

type fixedClock struct{ at time.Time }

func (c fixedClock) Now() time.Time { return c.at }

func aServiceHoldingOneDeposit(t *testing.T, now time.Time) (*Service, *fakeEvents, *journal) {
	t.Helper()
	calls := &journal{}
	d := aWaitingDeposit(t)
	deposits := &fakeDeposits{byID: map[DepositID]*Deposit{d.ID(): d}, calls: calls}
	events := &fakeEvents{calls: calls}
	return NewService(deposits, events, fixedClock{at: now}), events, calls
}

func TestPickUpLoadsTheDepositSavesItThenPublishesTheFact(t *testing.T) {
	svc, events, calls := aServiceHoldingOneDeposit(t, droppedOffAt.Add(time.Hour))
	if err := svc.PickUp(context.Background(), PickUpCommand{DepositID: "dep-1", Code: "123456"}); err != nil {
		t.Fatalf("PickUp: %v", err)
	}
	if want := []string{"load", "save", "publish"}; !reflect.DeepEqual(calls.names, want) {
		t.Fatalf("calls = %v, want %v", calls.names, want)
	}
	if len(events.published) != 1 {
		t.Fatalf("published %d events, want 1", len(events.published))
	}
	if _, ok := events.published[0].(ParcelPickedUp); !ok {
		t.Fatalf("published %T, want ParcelPickedUp", events.published[0])
	}
}

func TestAFailedPickUpSavesAndPublishesNothing(t *testing.T) {
	svc, events, calls := aServiceHoldingOneDeposit(t, droppedOffAt.Add(time.Hour))
	err := svc.PickUp(context.Background(), PickUpCommand{DepositID: "dep-1", Code: "000000"})
	if !errors.Is(err, ErrWrongCode) {
		t.Fatalf("err = %v, want ErrWrongCode", err)
	}
	if want := []string{"load"}; !reflect.DeepEqual(calls.names, want) || len(events.published) != 0 {
		t.Fatalf("calls = %v, published = %d; want only a load and nothing published", calls.names, len(events.published))
	}
}

func TestPickUpWithAMalformedCodeNeverLoadsTheDeposit(t *testing.T) {
	svc, events, calls := aServiceHoldingOneDeposit(t, droppedOffAt.Add(time.Hour))
	err := svc.PickUp(context.Background(), PickUpCommand{DepositID: "dep-404", Code: "12ab"})
	if !errors.Is(err, ErrBadPickupCode) {
		t.Fatalf("err = %v, want ErrBadPickupCode", err)
	}
	if len(calls.names) != 0 || len(events.published) != 0 {
		t.Fatalf("calls = %v, published = %d; want none", calls.names, len(events.published))
	}
}

func TestPickUpOfAnUnknownDepositIsReported(t *testing.T) {
	svc, events, calls := aServiceHoldingOneDeposit(t, droppedOffAt.Add(time.Hour))
	err := svc.PickUp(context.Background(), PickUpCommand{DepositID: "dep-404", Code: "123456"})
	if !errors.Is(err, errNotFound) {
		t.Fatalf("err = %v, want errNotFound", err)
	}
	if want := []string{"load"}; !reflect.DeepEqual(calls.names, want) || len(events.published) != 0 {
		t.Fatalf("calls = %v, published = %d; want only a load and nothing published", calls.names, len(events.published))
	}
}

func TestExpireWindowLoadsTheDepositSavesItThenPublishesTheExpiry(t *testing.T) {
	svc, events, calls := aServiceHoldingOneDeposit(t, droppedOffAt.Add(PickupWindow+time.Minute))
	if err := svc.ExpireWindow(context.Background(), "dep-1"); err != nil {
		t.Fatalf("ExpireWindow: %v", err)
	}
	if want := []string{"load", "save", "publish"}; !reflect.DeepEqual(calls.names, want) {
		t.Fatalf("calls = %v, want %v", calls.names, want)
	}
	if len(events.published) != 1 {
		t.Fatalf("published %d events, want 1", len(events.published))
	}
	if _, ok := events.published[0].(PickupWindowExpired); !ok {
		t.Fatalf("published %T, want PickupWindowExpired", events.published[0])
	}
}

func TestExpireWindowWhileTheWindowIsOpenSavesAndPublishesNothing(t *testing.T) {
	svc, events, calls := aServiceHoldingOneDeposit(t, droppedOffAt.Add(time.Hour))
	err := svc.ExpireWindow(context.Background(), "dep-1")
	if !errors.Is(err, ErrWindowOpen) {
		t.Fatalf("err = %v, want ErrWindowOpen", err)
	}
	if want := []string{"load"}; !reflect.DeepEqual(calls.names, want) || len(events.published) != 0 {
		t.Fatalf("calls = %v, published = %d; want only a load and nothing published", calls.names, len(events.published))
	}
}
GO
cat > src/lockers/vendor_status_test.go <<'GO'
package lockers

import (
	"errors"
	"testing"
)

func TestKnownVendorStatusesBecomeOurDoorStates(t *testing.T) {
	cases := map[string]DoorState{"DR_CL": DoorClosed, "DR_OP": DoorOpen, "DR_JM": DoorJammed}
	for code, want := range cases {
		got, err := DoorStateFromVendor(code)
		if err != nil || got != want {
			t.Errorf("DoorStateFromVendor(%q) = %v, %v; want %v, nil", code, got, err, want)
		}
	}
}

func TestAStatusTheVendorAddedLaterIsReportedNotGuessed(t *testing.T) {
	_, err := DoorStateFromVendor("DR_ST")
	var unknown UnknownVendorStatusError
	if !errors.As(err, &unknown) || unknown.Code != "DR_ST" {
		t.Fatalf("err = %v, want UnknownVendorStatusError for DR_ST", err)
	}
}

func TestAnEmptyVendorStatusIsReportedToo(t *testing.T) {
	if _, err := DoorStateFromVendor(""); err == nil {
		t.Fatal("an empty status was accepted")
	}
}
GO
