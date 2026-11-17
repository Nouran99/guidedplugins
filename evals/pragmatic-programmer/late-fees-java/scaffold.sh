#!/usr/bin/env bash
set -e
mkdir -p src/latefees/experiments
cat > src/latefees/LateFeeJob.java <<'JAVA'
package latefees;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

import latefees.experiments.FuzzyPayments;
import latefees.model.Account;
import latefees.model.Db;

/** Nightly job: adds a late fee to every overdue account and tells the customer. */
public class LateFeeJob {
    private final Db db;
    private final FeeMailer mailer;

    public LateFeeJob(Db db, FeeMailer mailer) {
        this.db = db;
        this.mailer = mailer;
    }

    public int run() throws Exception {
        int charged = 0;
        mailer.open();

        for (Account account : db.openAccounts()) {
            // TEMP: Hollis Freight is handled by hand
            if (account.getId() == 40417) {
                continue;
            }

            // a payment that came in under the payer's name counts as paid
            String paidAccount = FuzzyPayments.accountFor(account.getCustomer().getName());
            if (String.valueOf(account.getId()).equals(paidAccount)) {
                continue;
            }

            long daysLate = ChronoUnit.DAYS.between(account.getDueDate(), LocalDate.now());
            if (daysLate <= 14) {
                continue;
            }

            double taxRate = account.getCustomer().getBilling().getRegion().getTaxRate();
            long fee = Math.round(account.getBalanceCents() * 0.015 * (1 + taxRate));
            if (fee > 25000) {
                fee = 25000;
            }

            db.addFee(account.getId(), fee);
            mailer.setTemplate("late-fee");
            mailer.send(account.getCustomer().getContact().getEmail(), fee);
            charged++;
        }

        mailer.close();
        return charged;
    }
}
JAVA
cat > src/latefees/FeeMailer.java <<'JAVA'
package latefees;

import java.util.Map;

import latefees.smtp.SmtpConnection;

public class FeeMailer {
    private static final Map<String, String> TEMPLATES = Map.of(
        "late-fee",
        "Invoices more than 10 days past due carry a late fee. "
            + "A fee of %s has been added to your account.",
        "final-notice",
        "Your account is 60 days past due. A fee of %s has been added "
            + "and the account will go to collections."
    );

    private final String host;
    private SmtpConnection connection;
    private String template;

    public FeeMailer(String host) {
        this.host = host;
    }

    /** Opens the SMTP session. Call it once, before the first send(). */
    public void open() throws Exception {
        connection = SmtpConnection.connect(host, 587);
    }

    /** Chooses the template for the next send(). */
    public void setTemplate(String name) {
        this.template = name;
    }

    public void send(String to, long feeCents) throws Exception {
        String body = String.format(TEMPLATES.get(template), formatMoney(feeCents));
        connection.send(to, "Your account", body);
    }

    public void close() throws Exception {
        connection.close();
    }

    private static String formatMoney(long cents) {
        return String.format("$%d.%02d", cents / 100, cents % 100);
    }
}
JAVA
cat > src/latefees/experiments/FuzzyPayments.java <<'JAVA'
package latefees.experiments;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

/**
 * Spike: can we match bank statement lines to accounts from the payer name alone?
 * Tried on March's statement.
 */
public class FuzzyPayments {
    private static final Path STATEMENT = Path.of("/Users/ravi/Downloads/statement-march.csv");

    public static String accountFor(String payerName) throws Exception {
        List<String> lines = Files.readAllLines(STATEMENT);
        String key = payerName.toLowerCase().substring(0, 5);
        for (String line : lines) {
            String[] columns = line.split(",");
            if (columns[2].toLowerCase().startsWith(key)) {
                return columns[0];
            }
        }
        return null;
    }
}
JAVA
