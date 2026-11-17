#!/usr/bin/env bash
set -e
mkdir -p src/delivery

cat > src/delivery/Parcel.java <<'JAVA'
package delivery;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class Parcel {
    public String id;
    public String carrier;
    public String status = "new";
    public double weightKg;
    public int lengthCm;
    public int widthCm;
    public int heightCm;
    public String recipient;
    public String street;
    public String city;
    public String postalCode;
    public String country;
    public Instant shippedAt;
    private final List<String> events = new ArrayList<>();

    public List<String> getEvents() {
        return events;
    }
}
JAVA

cat > src/delivery/LabelFormatter.java <<'JAVA'
package delivery;

public interface LabelFormatter {
    String label(Parcel parcel, double rate);
}
JAVA

cat > src/delivery/DefaultLabelFormatter.java <<'JAVA'
package delivery;

public class DefaultLabelFormatter implements LabelFormatter {
    @Override
    public String label(Parcel p, double rate) {
        return addressBlock(p.recipient, p.street, p.city, p.postalCode, p.country)
                + "\n" + p.carrier.toUpperCase() + " " + String.format("%.2f", rate);
    }

    String addressBlock(String name, String street, String city, String postalCode, String country) {
        return name + "\n" + street + "\n" + postalCode + " " + city + "\n" + country.trim().toUpperCase();
    }
}
JAVA

cat > src/delivery/DeliveryService.java <<'JAVA'
package delivery;

import java.time.Instant;

public class DeliveryService {
    private final LabelFormatter labels;
    private double currentRate;

    public DeliveryService(LabelFormatter labels) {
        this.labels = labels;
    }

    public double quote(Parcel p) {
        double base = rateFor(p.carrier, p.weightKg) + surcharge(p);
        if (isRemoteArea(p.city, p.postalCode, p.country)) {
            base += 6.0;
        }
        double fuel = Double.parseDouble(System.getenv("FUEL_SURCHARGE"));
        currentRate = base * zoneFor(p.postalCode, p.country) * (1 + fuel);
        return currentRate;
    }

    public String ship(Parcel p) {
        p.status = "shipped";
        p.shippedAt = Instant.now();
        p.getEvents().add("shipped via " + p.carrier + " at " + p.shippedAt);
        return labels.label(p, currentRate);
    }

    public String reship(Parcel p) {
        p.status = "shipped";
        p.shippedAt = Instant.now();
        p.getEvents().add("shipped via " + p.carrier + " at " + p.shippedAt);
        p.getEvents().add("reshipped after return");
        return labels.label(p, currentRate);
    }

    double surcharge(Parcel p) {
        double dimWeight = (p.lengthCm * p.widthCm * p.heightCm) / 5000.0;
        double billable = Math.max(p.weightKg, dimWeight);
        boolean oversize = p.lengthCm > 120 || p.widthCm > 80 || p.heightCm > 80;
        return oversize ? billable * 1.5 : 0;
    }

    private double rateFor(String carrier, double weightKg) {
        switch (carrier) {
            case "dhl":
                return 4.20 + weightKg * 0.90;
            case "ups":
                return 3.90 + weightKg * 1.10;
            case "post":
                return 2.50 + weightKg * 0.60;
            default:
                throw new IllegalArgumentException("unknown carrier " + carrier);
        }
    }

    public String trackingUrl(Parcel p) {
        switch (p.carrier) {
            case "dhl":
                return "https://dhl.example/track?n=" + p.id;
            case "ups":
                return "https://ups.example/t/" + p.id;
            case "post":
                return "https://post.example/parcel/" + p.id;
            default:
                throw new IllegalArgumentException("unknown carrier " + p.carrier);
        }
    }

    public boolean withinWeightLimit(Parcel p) {
        switch (p.carrier) {
            case "dhl":
                return p.weightKg <= 31.5;
            case "ups":
                return p.weightKg <= 32;
            case "post":
                return p.weightKg <= 20;
            default:
                throw new IllegalArgumentException("unknown carrier " + p.carrier);
        }
    }

    private double zoneFor(String postalCode, String country) {
        String code = country.trim().toUpperCase();
        if (code.equals("DE")) {
            return postalCode.startsWith("0") ? 1.1 : 1.0;
        }
        return code.equals("AT") || code.equals("CH") ? 1.6 : 2.4;
    }

    private boolean isRemoteArea(String city, String postalCode, String country) {
        return country.trim().toUpperCase().equals("DE")
                && (postalCode.startsWith("18") || city.equalsIgnoreCase("Helgoland"));
    }
}
JAVA
