#!/usr/bin/env bash
set -e
mkdir -p src/models src/services src/repositories src/integration
cat > src/integration/CrmCustomerRecord.java <<'JAVA'
package acme.app.integration;

/** One row of the CRM team's customer table. */
public class CrmCustomerRecord {
    private String custNo;
    private String custName;
    private String emailAddr;
    private String vatNo;
    private int payDays;
    private String stat;

    public String getCustNo() { return custNo; }
    public void setCustNo(String custNo) { this.custNo = custNo; }
    public String getCustName() { return custName; }
    public void setCustName(String custName) { this.custName = custName; }
    public String getEmailAddr() { return emailAddr; }
    public void setEmailAddr(String emailAddr) { this.emailAddr = emailAddr; }
    public String getVatNo() { return vatNo; }
    public void setVatNo(String vatNo) { this.vatNo = vatNo; }
    public int getPayDays() { return payDays; }
    public void setPayDays(int payDays) { this.payDays = payDays; }
    public String getStat() { return stat; }
    public void setStat(String stat) { this.stat = stat; }
}
JAVA
cat > src/models/Customer.java <<'JAVA'
package acme.app.models;

import acme.app.integration.CrmCustomerRecord;

import java.util.ArrayList;
import java.util.List;

public class Customer {
    private String id;
    private String name;
    private String email;

    private String taxId;
    private int paymentTermsDays;
    private String crmStat;

    private String supportTier;
    private int slaHours;
    private final List<String> openTicketIds = new ArrayList<>();

    public static Customer fromCrm(CrmCustomerRecord record) {
        Customer customer = new Customer();
        customer.id = record.getCustNo();
        customer.name = record.getCustName();
        customer.email = record.getEmailAddr();
        customer.taxId = record.getVatNo();
        customer.paymentTermsDays = record.getPayDays();
        customer.crmStat = record.getStat();
        return customer;
    }

    public boolean isBillable() {
        return "A".equals(crmStat) || "S".equals(crmStat);
    }

    public boolean isOnHold() {
        return "H".equals(crmStat);
    }

    public boolean breachesSla(int hoursOpen) {
        return hoursOpen > slaHours;
    }

    public String getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public String getTaxId() { return taxId; }
    public int getPaymentTermsDays() { return paymentTermsDays; }
    public String getSupportTier() { return supportTier; }
    public void setSupportTier(String supportTier) { this.supportTier = supportTier; }
    public int getSlaHours() { return slaHours; }
    public void setSlaHours(int slaHours) { this.slaHours = slaHours; }
    public List<String> getOpenTicketIds() { return openTicketIds; }
}
JAVA
cat > src/models/Invoice.java <<'JAVA'
package acme.app.models;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class Invoice {
    private final String id;
    private final String customerId;
    private final LocalDate issuedOn;
    private final LocalDate dueOn;
    private final List<Line> lines = new ArrayList<>();
    private String ledgerRef;
    private String status = "OPEN";

    public Invoice(String id, String customerId, LocalDate issuedOn, int termsDays) {
        this.id = id;
        this.customerId = customerId;
        this.issuedOn = issuedOn;
        this.dueOn = issuedOn.plusDays(termsDays);
    }

    public void addLine(String description, BigDecimal amount) {
        lines.add(new Line(description, amount));
    }

    public BigDecimal total() {
        BigDecimal sum = BigDecimal.ZERO;
        for (Line line : lines) {
            sum = sum.add(line.getAmount());
        }
        return sum;
    }

    public void markPaid() {
        this.status = "PAID";
    }

    public String getId() { return id; }
    public String getCustomerId() { return customerId; }
    public LocalDate getIssuedOn() { return issuedOn; }
    public LocalDate getDueOn() { return dueOn; }
    public List<Line> getLines() { return lines; }
    public String getLedgerRef() { return ledgerRef; }
    public void setLedgerRef(String ledgerRef) { this.ledgerRef = ledgerRef; }
    public String getStatus() { return status; }

    public static class Line {
        private final String description;
        private final BigDecimal amount;

        public Line(String description, BigDecimal amount) {
            this.description = description;
            this.amount = amount;
        }

        public String getDescription() { return description; }
        public BigDecimal getAmount() { return amount; }
    }
}
JAVA
cat > src/repositories/InvoiceRepository.java <<'JAVA'
package acme.app.repositories;

import acme.app.integration.CrmCustomerRecord;
import acme.app.models.Invoice;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;

public class InvoiceRepository {
    private final JdbcTemplate jdbc;

    public InvoiceRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public CrmCustomerRecord findCrmRecord(String custNo) {
        return jdbc.queryForObject(
            "SELECT cust_no, cust_name, email_addr, vat_no, pay_days, stat FROM crm.customer WHERE cust_no = ?",
            (rs, rowNum) -> {
                CrmCustomerRecord record = new CrmCustomerRecord();
                record.setCustNo(rs.getString("cust_no"));
                record.setCustName(rs.getString("cust_name"));
                record.setEmailAddr(rs.getString("email_addr"));
                record.setVatNo(rs.getString("vat_no"));
                record.setPayDays(rs.getInt("pay_days"));
                record.setStat(rs.getString("stat"));
                return record;
            },
            custNo);
    }

    public List<Invoice> findDueForRenewal(LocalDate today) {
        List<Invoice> due = jdbc.query(
            "SELECT i.id, i.customer_id, i.issued_on, c.pay_days FROM billing_invoice i "
                + "JOIN crm.customer c ON c.cust_no = i.customer_id "
                + "WHERE c.stat IN ('A', 'S') AND i.status = 'PAID' AND i.issued_on + c.pay_days < ?",
            (rs, rowNum) -> new Invoice(
                rs.getString("id"),
                rs.getString("customer_id"),
                rs.getDate("issued_on").toLocalDate(),
                rs.getInt("pay_days")),
            Date.valueOf(today));
        for (Invoice invoice : due) {
            jdbc.query(
                "SELECT description, amount FROM billing_invoice_line WHERE invoice_id = ?",
                rs -> {
                    invoice.addLine(rs.getString("description"), rs.getBigDecimal("amount"));
                },
                invoice.getId());
        }
        return due;
    }

    public void save(Invoice invoice) {
        jdbc.update(
            "INSERT INTO billing_invoice (id, customer_id, issued_on, due_on, status, ledger_ref) VALUES (?, ?, ?, ?, ?, ?)",
            invoice.getId(), invoice.getCustomerId(), Date.valueOf(invoice.getIssuedOn()),
            Date.valueOf(invoice.getDueOn()), invoice.getStatus(), invoice.getLedgerRef());
        for (Invoice.Line line : invoice.getLines()) {
            jdbc.update(
                "INSERT INTO billing_invoice_line (invoice_id, description, amount) VALUES (?, ?, ?)",
                invoice.getId(), line.getDescription(), line.getAmount());
        }
    }
}
JAVA
cat > src/integration/InvoiceBroadcaster.java <<'JAVA'
package acme.app.integration;

import acme.app.models.Invoice;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.core.KafkaTemplate;

public class InvoiceBroadcaster {
    private static final String TOPIC = "invoices";

    private final KafkaTemplate<String, String> kafka;
    private final ObjectMapper mapper;

    public InvoiceBroadcaster(KafkaTemplate<String, String> kafka, ObjectMapper mapper) {
        this.kafka = kafka;
        this.mapper = mapper;
    }

    public void send(Invoice invoice) {
        try {
            kafka.send(TOPIC, invoice.getCustomerId(), mapper.writeValueAsString(invoice));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("could not serialize invoice " + invoice.getId(), e);
        }
    }
}
JAVA
cat > src/services/InvoiceManager.java <<'JAVA'
package acme.app.services;

import acme.app.integration.InvoiceBroadcaster;
import acme.app.models.Customer;
import acme.app.models.Invoice;
import acme.app.repositories.InvoiceRepository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class InvoiceManager {
    private final InvoiceRepository invoices;
    private final InvoiceBroadcaster broadcaster;

    public InvoiceManager(InvoiceRepository invoices, InvoiceBroadcaster broadcaster) {
        this.invoices = invoices;
        this.broadcaster = broadcaster;
    }

    public Invoice process(String custNo, Map<String, BigDecimal> items) {
        Customer customer = Customer.fromCrm(invoices.findCrmRecord(custNo));
        if (customer.isOnHold()) {
            throw new IllegalStateException("customer " + custNo + " is on hold");
        }
        if (!customer.isBillable()) {
            throw new IllegalStateException("customer " + custNo + " is not billable");
        }
        Invoice invoice = new Invoice(
            UUID.randomUUID().toString(), customer.getId(), LocalDate.now(), customer.getPaymentTermsDays());
        items.forEach(invoice::addLine);
        invoices.save(invoice);
        broadcaster.send(invoice);
        return invoice;
    }

    public List<Invoice> handleRenewals() {
        List<Invoice> issued = new ArrayList<>();
        for (Invoice previous : invoices.findDueForRenewal(LocalDate.now())) {
            Map<String, BigDecimal> items = new LinkedHashMap<>();
            for (Invoice.Line line : previous.getLines()) {
                items.put(line.getDescription(), line.getAmount());
            }
            issued.add(process(previous.getCustomerId(), items));
        }
        return issued;
    }
}
JAVA
cat > src/services/SupportDesk.java <<'JAVA'
package acme.app.services;

import acme.app.models.Customer;

public class SupportDesk {
    public String queueFor(Customer customer, String ticketId) {
        customer.getOpenTicketIds().add(ticketId);
        return "GOLD".equals(customer.getSupportTier()) ? "priority" : "standard";
    }

    public boolean isOverdueForReply(Customer customer, int hoursOpen) {
        return customer.breachesSla(hoursOpen);
    }
}
JAVA
