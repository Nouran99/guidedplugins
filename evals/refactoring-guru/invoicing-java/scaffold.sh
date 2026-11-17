#!/usr/bin/env bash
set -e
mkdir -p src/billing
cat > src/billing/Order.java <<'JAVA'
package billing;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public class Order {
    private String id;
    private Instant createdAt;
    private String currency;
    private final List<Line> lines = new ArrayList<>();
    Customer customer;
    String status;

    public static Order open(Customer customer, String currency) {
        Order order = new Order();
        order.setId(UUID.randomUUID().toString());
        order.setCreatedAt(Instant.now());
        order.setCurrency(currency);
        customer.addOrder(order);
        return order;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public Customer getCustomer() {
        return customer;
    }

    public List<Line> getLines() {
        return Collections.unmodifiableList(lines);
    }

    public void addLine(String sku, int quantity, double unitPrice) {
        lines.add(new Line(sku, quantity, unitPrice));
    }

    public double total() {
        double sum = 0;
        for (Line line : lines) {
            sum += line.quantity * line.unitPrice;
        }
        return sum;
    }

    public void cancel() {
        status = "CANCELLED";
        customer.orders.remove(this);
        customer.openBalance -= total();
    }

    public static class Line {
        public final String sku;
        public final int quantity;
        public final double unitPrice;

        Line(String sku, int quantity, double unitPrice) {
            this.sku = sku;
            this.quantity = quantity;
            this.unitPrice = unitPrice;
        }
    }
}
JAVA
cat > src/billing/Customer.java <<'JAVA'
package billing;

import java.util.ArrayList;
import java.util.List;

public class Customer {
    final String name;
    final Account account;
    final List<Order> orders = new ArrayList<>();
    double openBalance;

    public Customer(String name, Account account) {
        this.name = name;
        this.account = account;
    }

    public String getName() {
        return name;
    }

    public Account getAccount() {
        return account;
    }

    void addOrder(Order order) {
        order.customer = this;
        order.status = "OPEN";
        orders.add(order);
        openBalance += order.total();
    }
}

class Account {
    private final String id;
    private final Plan plan;

    Account(String id, Plan plan) {
        this.id = id;
        this.plan = plan;
    }

    String getId() {
        return id;
    }

    Plan getPlan() {
        return plan;
    }
}

class Plan {
    private final double discountRate;
    private final int netDays;

    Plan(double discountRate, int netDays) {
        this.discountRate = discountRate;
        this.netDays = netDays;
    }

    double getDiscountRate() {
        return discountRate;
    }

    int getNetDays() {
        return netDays;
    }
}
JAVA
cat > src/billing/PaymentGateway.java <<'JAVA'
package billing;

public interface PaymentGateway {
    boolean submit(String accountId, double amount, String currency);
}
JAVA
cat > src/billing/InvoiceService.java <<'JAVA'
package billing;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Locale;

public class InvoiceService {
    private final Connection db;
    private final PaymentGateway payments;

    public InvoiceService(Connection db, PaymentGateway payments) {
        this.db = db;
        this.payments = payments;
    }

    public int issue(Order order) {
        if (order.getLines().isEmpty()) {
            return 1;
        }
        double subtotal = order.total();
        double rate = order.getCustomer().getAccount().getPlan().getDiscountRate();
        double due = applyDiscount(subtotal, rate);
        String number = "INV-" + order.getId().substring(0, 8);
        if (save(number, order.getId(), due, order.getCurrency()) != 0) {
            return 2;
        }
        String accountId = order.getCustomer().getAccount().getId();
        if (charge(accountId, due, order.getCurrency()) != 0) {
            return 3;
        }
        return 0;
    }

    public String render(Order order, double amount, String currency) {
        StringBuilder html = new StringBuilder();
        html.append("<h1>Invoice for ").append(order.getCustomer().getName()).append("</h1>");
        html.append("<table>");
        for (Order.Line line : order.getLines()) {
            html.append("<tr><td>").append(line.sku).append("</td><td>")
                .append(line.quantity).append("</td><td>")
                .append(format(line.quantity * line.unitPrice, currency)).append("</td></tr>");
        }
        html.append("</table>");
        html.append("<p>Total: ").append(format(amount, currency)).append("</p>");
        return html.toString();
    }

    private double applyDiscount(double amount, double rate) {
        return amount - amount * rate;
    }

    private int save(String number, String orderId, double amount, String currency) {
        String sql = "INSERT INTO invoices (number, order_id, amount, currency) VALUES (?, ?, ?, ?)";
        try (PreparedStatement st = db.prepareStatement(sql)) {
            st.setString(1, number);
            st.setString(2, orderId);
            st.setDouble(3, amount);
            st.setString(4, currency);
            st.executeUpdate();
            return 0;
        } catch (SQLException e) {
            return 1;
        }
    }

    private int charge(String accountId, double amount, String currency) {
        try {
            return payments.submit(accountId, amount, currency) ? 0 : 1;
        } catch (RuntimeException e) {
            return 2;
        }
    }

    private String format(double amount, String currency) {
        return String.format(Locale.ROOT, "%.2f %s", amount, currency);
    }
}
JAVA
