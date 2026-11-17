#!/usr/bin/env bash
set -e
mkdir -p src/billing

cat > src/billing/Invoice.java <<'JAVA'
package billing;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "invoices")
@Getter
@Setter
public class Invoice {
    @Id
    @GeneratedValue
    private Long id;

    @Column(name = "customer_email")
    private String customerEmail;

    private String region;

    private String status;

    private double total;

    @Column(name = "payment_ref")
    private String paymentRef;

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<InvoiceLine> lines = new ArrayList<>();

    public String getDisplayTotal() {
        return String.format(Locale.GERMANY, "%,.2f EUR", total);
    }

    public List<Double> splitInstalments(int count) {
        double each = Math.round(total / count * 100) / 100.0;
        List<Double> parts = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            parts.add(each);
        }
        return parts;
    }
}
JAVA

cat > src/billing/InvoiceLine.java <<'JAVA'
package billing;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "invoice_lines")
@Getter
@Setter
public class InvoiceLine {
    @Id
    @GeneratedValue
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id")
    @JsonIgnore
    private Invoice invoice;

    private String sku;

    private int quantity;

    private double unitPrice;
}
JAVA

cat > src/billing/InvoiceRepository.java <<'JAVA'
package billing;

import org.springframework.data.jpa.repository.JpaRepository;

public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
}
JAVA

cat > src/billing/TaxRateClient.java <<'JAVA'
package billing;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "tax-service")
public interface TaxRateClient {
    @GetMapping("/rates")
    double rateFor(@RequestParam("sku") String sku, @RequestParam("region") String region);
}
JAVA

cat > src/billing/PaymentService.java <<'JAVA'
package billing;

import com.nimbuspay.sdk.NimbusClient;
import com.nimbuspay.sdk.NimbusException;
import com.nimbuspay.sdk.PaymentIntent;
import org.springframework.stereotype.Service;

@Service
public class PaymentService {
    private final NimbusClient nimbus;

    public PaymentService(NimbusClient nimbus) {
        this.nimbus = nimbus;
    }

    public PaymentIntent charge(String customerEmail, double amount, String currency) {
        try {
            return nimbus.paymentIntents().create(
                new PaymentIntent.Params()
                    .setAmount(Math.round(amount * 100))
                    .setCurrency(currency)
                    .setReceiptEmail(customerEmail));
        } catch (NimbusException e) {
            throw new IllegalStateException("payment provider rejected the request", e);
        }
    }
}
JAVA

cat > src/billing/InvoiceController.java <<'JAVA'
package billing;

import com.nimbuspay.sdk.PaymentIntent;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/invoices")
public class InvoiceController {
    private final InvoiceRepository invoices;
    private final TaxRateClient taxRates;
    private final PaymentService payments;
    private final JavaMailSender mail;

    public InvoiceController(InvoiceRepository invoices, TaxRateClient taxRates,
                             PaymentService payments, JavaMailSender mail) {
        this.invoices = invoices;
        this.taxRates = taxRates;
        this.payments = payments;
        this.mail = mail;
    }

    @GetMapping("/{id}")
    public Invoice get(@PathVariable Long id) {
        return invoices.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @PostMapping("/{id}/pay")
    @Transactional
    public Invoice pay(@PathVariable Long id) {
        Invoice invoice = invoices.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if ("PAID".equals(invoice.getStatus()) || "VOID".equals(invoice.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "invoice is " + invoice.getStatus());
        }

        double total = 0;
        for (InvoiceLine line : invoice.getLines()) {
            double rate = taxRates.rateFor(line.getSku(), invoice.getRegion());
            total += line.getQuantity() * line.getUnitPrice() * (1 + rate);
        }
        invoice.setTotal(total);

        PaymentIntent intent = payments.charge(invoice.getCustomerEmail(), total, "eur");
        if (!"succeeded".equals(intent.getStatus())) {
            throw new ResponseStatusException(HttpStatus.PAYMENT_REQUIRED, intent.getStatus());
        }
        invoice.setPaymentRef(intent.getId());
        invoice.setStatus("PAID");
        invoices.save(invoice);

        SimpleMailMessage receipt = new SimpleMailMessage();
        receipt.setTo(invoice.getCustomerEmail());
        receipt.setSubject("Receipt for invoice " + invoice.getId());
        receipt.setText("We received " + invoice.getDisplayTotal() + ". Thank you.");
        mail.send(receipt);
        return invoice;
    }
}
JAVA
