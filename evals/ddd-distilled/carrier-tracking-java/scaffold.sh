#!/usr/bin/env bash
set -e
mkdir -p src/shipping
cat > src/shipping/CarrierAcl.java <<'JAVA'
package shipping;

import com.fastfreight.sdk.FastFreightClient;
import com.fastfreight.sdk.TrackingResponse;

/**
 * Anticorruption layer in front of the FastFreight tracking API.
 * Everything that talks to the carrier goes through here.
 */
public class CarrierAcl {
    private final FastFreightClient client;

    public CarrierAcl(FastFreightClient client) {
        this.client = client;
    }

    public TrackingResponse lookup(String consignmentNo) {
        return client.getConsignment(consignmentNo);
    }

    public TrackingResponse lookupByPod(String podRef) {
        return client.getByProofOfDelivery(podRef);
    }
}
JAVA
cat > src/shipping/Shipment.java <<'JAVA'
package shipping;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class Shipment {
    private final String consignmentNo;
    private final String orderRef;
    private String status = "CREATED";
    private Instant podAt;
    private final List<String> events = new ArrayList<>();

    public Shipment(String consignmentNo, String orderRef) {
        this.consignmentNo = consignmentNo;
        this.orderRef = orderRef;
    }

    public String getConsignmentNo() {
        return consignmentNo;
    }

    public String getOrderRef() {
        return orderRef;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Instant getPodAt() {
        return podAt;
    }

    public void setPodAt(Instant podAt) {
        this.podAt = podAt;
    }

    public List<String> getEvents() {
        return events;
    }
}

interface ShipmentStore {
    Shipment byConsignment(String consignmentNo);

    void save(Shipment shipment);
}
JAVA
cat > src/shipping/ShipmentTracker.java <<'JAVA'
package shipping;

import com.fastfreight.sdk.TrackingResponse;

public class ShipmentTracker {
    private final CarrierAcl carrier;
    private final ShipmentStore shipments;

    public ShipmentTracker(CarrierAcl carrier, ShipmentStore shipments) {
        this.carrier = carrier;
        this.shipments = shipments;
    }

    public void refresh(String consignmentNo) {
        Shipment shipment = shipments.byConsignment(consignmentNo);
        TrackingResponse response = carrier.lookup(consignmentNo);
        switch (response.getStat()) {
            case "DLV":
            case "POD":
                shipment.setStatus("DELIVERED");
                shipment.setPodAt(response.getTs());
                break;
            case "HLD":
                shipment.setStatus("HELD");
                break;
            default:
                shipment.setStatus("IN_TRANSIT");
        }
        shipments.save(shipment);
    }
}
JAVA
cat > src/shipping/TrackingWebhook.java <<'JAVA'
package shipping;

import com.fastfreight.sdk.TrackingResponse;
import com.fasterxml.jackson.databind.ObjectMapper;

public class TrackingWebhook {
    private final ShipmentStore shipments;
    private final ObjectMapper mapper = new ObjectMapper();
    private int deliveredToday = 0;

    public TrackingWebhook(ShipmentStore shipments) {
        this.shipments = shipments;
    }

    public void onCarrierMessage(String body) throws Exception {
        TrackingResponse update = mapper.readValue(body, TrackingResponse.class);
        Shipment shipment = shipments.byConsignment(update.getConsignmentNo());
        shipment.getEvents().add(update.getStat() + "@" + update.getTs());
        if ("POD".equals(update.getStat()) || "DLV".equals(update.getStat())) {
            shipment.setStatus("DELIVERED");
            shipment.setPodAt(update.getTs());
            deliveredToday++;
        } else if ("HLD".equals(update.getStat())) {
            shipment.setStatus("HELD");
        } else {
            shipment.setStatus("IN_TRANSIT");
        }
        shipments.save(shipment);
    }

    public String partnerView(String consignmentNo) throws Exception {
        return mapper.writeValueAsString(shipments.byConsignment(consignmentNo));
    }

    public int deliveredToday() {
        return deliveredToday;
    }
}
JAVA
