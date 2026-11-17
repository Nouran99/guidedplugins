#!/usr/bin/env bash
set -e
mkdir -p src/dispatch

cat > src/dispatch/ShipmentDispatcher.java <<'JAVA'
package dispatch;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.sql.DataSource;

public class ShipmentDispatcher {
    public record Shipment(long id, String email, String sku, String address) {}

    public interface CarrierApi { String book(Shipment shipment); }
    public interface WarehouseHook { void notifyBooked(long shipmentId, String tracking); }
    public interface Mailer { void send(String to, String body); }

    private final ExecutorService pool = Executors.newFixedThreadPool(16);
    private final DataSource dataSource;
    private final CarrierApi carrier;
    private final WarehouseHook warehouse;
    private final Mailer mailer;

    public ShipmentDispatcher(DataSource dataSource, CarrierApi carrier, WarehouseHook warehouse, Mailer mailer) {
        this.dataSource = dataSource;
        this.carrier = carrier;
        this.warehouse = warehouse;
        this.mailer = mailer;
    }

    public void submitPending(String warehouseId) {
        pool.submit(() -> dispatchPending(warehouseId));
    }

    private void dispatchPending(String warehouseId) {
        try (Connection conn = dataSource.getConnection()) {
            List<Shipment> pending = new ArrayList<>();
            try (PreparedStatement select = conn.prepareStatement(
                    "select id, email, sku, address from shipments where status = 'PENDING' and warehouse_id = ?")) {
                select.setString(1, warehouseId);
                try (ResultSet rs = select.executeQuery()) {
                    while (rs.next()) {
                        pending.add(new Shipment(rs.getLong("id"), rs.getString("email"),
                                rs.getString("sku"), rs.getString("address")));
                    }
                }
            }
            for (Shipment shipment : pending) {
                String tracking = carrier.book(shipment);
                try (PreparedStatement update = conn.prepareStatement(
                        "update shipments set status = 'BOOKED', tracking = ? where id = ?")) {
                    update.setString(1, tracking);
                    update.setLong(2, shipment.id());
                    update.executeUpdate();
                }
                pool.submit(() -> mailer.send(shipment.email(), "Your parcel is on its way: " + tracking));
                pool.submit(() -> warehouse.notifyBooked(shipment.id(), tracking));
            }
        } catch (SQLException | RuntimeException e) {
            e.printStackTrace();
            pool.submit(() -> dispatchPending(warehouseId));
        }
    }
}
JAVA

cat > src/dispatch/DispatchController.java <<'JAVA'
package dispatch;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DispatchController {
    private final ShipmentDispatcher dispatcher;

    public DispatchController(ShipmentDispatcher dispatcher) {
        this.dispatcher = dispatcher;
    }

    @PostMapping("/warehouses/{id}/dispatch")
    public ResponseEntity<Void> dispatch(@PathVariable("id") String warehouseId) {
        dispatcher.submitPending(warehouseId);
        return ResponseEntity.accepted().build();
    }
}
JAVA
