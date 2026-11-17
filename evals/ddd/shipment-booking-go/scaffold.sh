#!/usr/bin/env bash
set -e
mkdir -p src/shipping
cat > src/shipping/booking_handler.go <<'GO'
package shipping

import (
	"encoding/json"
	"net/http"
	"time"
)

type BookingHandler struct {
	manager *ShipmentManager
	store   ShipmentStore
}

func NewBookingHandler(manager *ShipmentManager, store ShipmentStore) *BookingHandler {
	return &BookingHandler{manager: manager, store: store}
}

func (h *BookingHandler) Book(w http.ResponseWriter, r *http.Request) {
	var body Shipment
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid body", http.StatusBadRequest)
		return
	}
	if body.WeightKg <= 0 || body.WeightKg > 1000 {
		http.Error(w, "weight must be between 0 and 1000 kg", http.StatusUnprocessableEntity)
		return
	}
	query := r.URL.Query()
	saved, err := h.manager.Process(&body, query.Get("express") == "1", query.Get("fragile") == "1")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(saved)
}

func (h *BookingHandler) Reschedule(w http.ResponseWriter, r *http.Request) {
	var body Shipment
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid body", http.StatusBadRequest)
		return
	}
	current, err := h.store.Find(r.URL.Query().Get("id"))
	if err != nil || current == nil {
		http.NotFound(w, r)
		return
	}
	if current.Status != "booked" && current.Status != "created" {
		http.Error(w, "only a booked shipment can be rescheduled", http.StatusConflict)
		return
	}
	if current.Hazmat && body.PickupFrom.Weekday() == time.Sunday {
		http.Error(w, "hazardous goods are not collected on Sundays", http.StatusUnprocessableEntity)
		return
	}
	current.PickupFrom = body.PickupFrom
	current.PickupTo = body.PickupTo
	if err := h.store.Update(current); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(current)
}
GO
cat > src/shipping/shipment_manager.go <<'GO'
package shipping

import (
	"fmt"
	"time"
)

type Shipment struct {
	ID         string    `json:"id"`
	CustomerID string    `json:"customerId"`
	Status     string    `json:"status"`
	WeightKg   float64   `json:"weightKg"`
	Hazmat     bool      `json:"hazmat"`
	Depot      string    `json:"depot"`
	PickupFrom time.Time `json:"pickupFrom"`
	PickupTo   time.Time `json:"pickupTo"`
	PriceCents int       `json:"priceCents"`
	SlotNo     int       `json:"slotNo"`
}

type ShipmentStore interface {
	Find(id string) (*Shipment, error)
	Insert(s *Shipment) error
	Update(s *Shipment) error
	PickupsMissedBefore(t time.Time) ([]*Shipment, error)
}

type ShipmentManager struct {
	store  ShipmentStore
	depots *DepotDomainService
	slots  map[string]int
}

func NewShipmentManager(store ShipmentStore, depots *DepotDomainService) *ShipmentManager {
	return &ShipmentManager{store: store, depots: depots, slots: map[string]int{}}
}

func (m *ShipmentManager) Process(data *Shipment, express bool, fragile bool) (*Shipment, error) {
	opens, closes, err := m.depots.OpeningHours(data.Depot)
	if err != nil {
		return nil, err
	}
	if hour := data.PickupFrom.Hour(); hour < opens || hour >= closes {
		return nil, fmt.Errorf("depot %s does not collect at %02d:00", data.Depot, hour)
	}
	price := 450
	if data.WeightKg > 30 {
		price += (int(data.WeightKg-30)/10 + 1) * 120
	}
	if express {
		price = price * 16 / 10
	}
	if fragile {
		price += 300
	}
	data.PriceCents = price
	data.SlotNo = m.GetNextSlot(data.Depot)
	data.Status = "booked"
	if err := m.store.Insert(data); err != nil {
		return nil, err
	}
	return data, nil
}

func (m *ShipmentManager) GetNextSlot(depot string) int {
	m.slots[depot]++
	return m.slots[depot]
}
GO
cat > src/shipping/reschedule_job.go <<'GO'
package shipping

import (
	"log"
	"time"
)

// RebookMissedPickups runs every night at 02:00. A consignment whose pickup window
// passed without a driver is moved to the next working day, same hours.
func RebookMissedPickups(store ShipmentStore, now time.Time) error {
	missed, err := store.PickupsMissedBefore(now)
	if err != nil {
		return err
	}
	for _, c := range missed {
		if c.Status != "booked" {
			continue
		}
		next := now.AddDate(0, 0, 1)
		for next.Weekday() == time.Saturday || next.Weekday() == time.Sunday {
			next = next.AddDate(0, 0, 1)
		}
		length := c.PickupTo.Sub(c.PickupFrom)
		c.PickupFrom = time.Date(next.Year(), next.Month(), next.Day(), c.PickupFrom.Hour(), c.PickupFrom.Minute(), 0, 0, time.UTC)
		c.PickupTo = c.PickupFrom.Add(length)
		if err := store.Update(c); err != nil {
			log.Printf("could not rebook consignment %s: %v", c.ID, err)
		}
	}
	return nil
}
GO
cat > src/shipping/depots.go <<'GO'
package shipping

import "fmt"

type Depot struct {
	code   string
	opens  int
	closes int
}

type DepotRepository interface {
	Save(d *Depot) error
	FindByCode(code string) (*Depot, error)
}

type InMemoryDepotRepository struct {
	items map[string]*Depot
}

func NewInMemoryDepotRepository() *InMemoryDepotRepository {
	return &InMemoryDepotRepository{items: map[string]*Depot{}}
}

func (r *InMemoryDepotRepository) Save(d *Depot) error {
	r.items[d.code] = d
	return nil
}

func (r *InMemoryDepotRepository) FindByCode(code string) (*Depot, error) {
	d, ok := r.items[code]
	if !ok {
		return nil, fmt.Errorf("unknown depot %s", code)
	}
	return d, nil
}

type DepotFactory struct{}

func (DepotFactory) Create(code string, opens, closes int) *Depot {
	return &Depot{code: code, opens: opens, closes: closes}
}

type DepotDomainService struct {
	repository DepotRepository
	factory    DepotFactory
}

func NewDepotDomainService(repository DepotRepository) *DepotDomainService {
	return &DepotDomainService{repository: repository, factory: DepotFactory{}}
}

func (s *DepotDomainService) RegisterDepot(code string, opens, closes int) error {
	return s.repository.Save(s.factory.Create(code, opens, closes))
}

func (s *DepotDomainService) OpeningHours(code string) (int, int, error) {
	d, err := s.repository.FindByCode(code)
	if err != nil {
		return 0, 0, err
	}
	return d.opens, d.closes, nil
}
GO
