#!/usr/bin/env bash
set -e
mkdir -p src/inventory
cat > src/inventory/Reservation.java <<'JAVA'
package inventory;

import java.time.Clock;
import java.time.Instant;

public record Reservation(String id, String sku, int quantity, Instant expiresAt) {

    boolean expired(Clock clock) {
        return !clock.instant().isBefore(expiresAt);
    }
}
JAVA
cat > src/inventory/StockLedger.java <<'JAVA'
package inventory;

import java.time.Clock;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Ledger class.
 */
public class StockLedger {
    // map of sku to quantity
    final Map<String, Integer> q = new HashMap<>();
    // reservations
    final List<Reservation> res = new ArrayList<>();
    private final Clock clock;

    private String currentSku;
    private int wanted;
    private int available;

    public StockLedger(Clock clock) {
        this.clock = clock;
    }

    // add stock
    public void add(String sku, int n) {
        q.merge(sku, n, Integer::sum);
    }

    // remove stock
    public void remove(int n, String sku) {
        q.merge(sku, -n, Integer::sum);
    }

    // reserve stock
    public Reservation reserve(String sku, int n) {
        currentSku = sku;
        wanted = n;
        computeAvailable();
        checkAvailable();
        return book();
    }

    private void computeAvailable() {
        int held = 0;
        for (Reservation r : res) {
            if (r.sku().equals(currentSku) && !r.expired(clock)) {
                held += r.quantity();
            }
        }
        available = q.getOrDefault(currentSku, 0) - held;
    }

    private void checkAvailable() {
        if (available < wanted) {
            throw new IllegalStateException("not enough stock for " + currentSku);
        }
    }

    private Reservation book() {
        Reservation r = new Reservation(UUID.randomUUID().toString(), currentSku, wanted,
                clock.instant().plusSeconds(900));
        res.add(r);
        return r;
    }

    public Integer getStock(String sku) {
        res.removeIf(r -> r.expired(clock));
        return q.get(sku);
    }

    public Optional<Reservation> fetchReservation(String id) {
        return res.stream().filter(r -> r.id().equals(id)).findFirst();
    }

    public Reservation loadHold(String id) {
        return res.stream()
                .filter(r -> r.id().equals(id))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("unknown hold " + id));
    }
}
JAVA
cat > src/inventory/StockLedgerTest.java <<'JAVA'
package inventory;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class StockLedgerTest {
    private final Clock clock = Clock.fixed(Instant.parse("2026-03-02T10:00:00Z"), ZoneOffset.UTC);
    private StockLedger ledger;

    @BeforeEach
    void setUp() {
        ledger = new StockLedger(clock);
        ledger.add("A1", 10);
    }

    @Test
    void addMergesQuantities() {
        ledger.add("A1", 5);
        assertEquals(15, ledger.q.get("A1"));
    }

    @Test
    void reserveRecordsAHold() {
        ledger.reserve("A1", 4);
        assertEquals(1, ledger.res.size());
        assertEquals(4, ledger.res.get(0).quantity());
        assertEquals(10, ledger.q.get("A1"));
    }

    @Test
    void reserveMoreThanAvailableFails() {
        assertThrows(IllegalStateException.class, () -> ledger.reserve("A1", 11));
        assertTrue(ledger.res.isEmpty());
    }
}
JAVA
