#!/usr/bin/env bash
set -e
mkdir -p src/lending
cat > src/lending/LoanApplication.java <<'JAVA'
package com.acme.lending;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;

public class LoanApplication {

    public enum Status { DRAFT, SUBMITTED, APPROVED, DECLINED }

    private static final BigDecimal MIN_AMOUNT = new BigDecimal("500");
    private static final BigDecimal MAX_AMOUNT = new BigDecimal("50000");
    private static final int MIN_TERM_MONTHS = 6;
    private static final int MAX_TERM_MONTHS = 84;
    private static final BigDecimal MAX_PAYMENT_SHARE_OF_INCOME = new BigDecimal("0.35");

    private final String applicationId;
    private final String applicantId;
    private final BigDecimal monthlyIncome;
    private final BigDecimal requestedAmount;
    private final int termMonths;
    private Status status = Status.DRAFT;
    private CreditGrade grade;
    private String declineReason;
    private Instant reviewedAt;

    public LoanApplication(String applicationId, String applicantId, BigDecimal monthlyIncome,
                           BigDecimal requestedAmount, int termMonths) {
        if (requestedAmount.compareTo(MIN_AMOUNT) < 0 || requestedAmount.compareTo(MAX_AMOUNT) > 0) {
            throw new IllegalArgumentException("a loan is between " + MIN_AMOUNT + " and " + MAX_AMOUNT);
        }
        if (termMonths < MIN_TERM_MONTHS || termMonths > MAX_TERM_MONTHS) {
            throw new IllegalArgumentException(
                "the term is between " + MIN_TERM_MONTHS + " and " + MAX_TERM_MONTHS + " months");
        }
        if (monthlyIncome.signum() <= 0) {
            throw new IllegalArgumentException("monthly income must be positive");
        }
        this.applicationId = applicationId;
        this.applicantId = applicantId;
        this.monthlyIncome = monthlyIncome;
        this.requestedAmount = requestedAmount;
        this.termMonths = termMonths;
    }

    public void submit(CreditGrade grade) {
        if (status != Status.DRAFT) {
            throw new IllegalStateException("application " + applicationId + " is " + status + " and cannot be submitted");
        }
        this.grade = grade;
        this.status = Status.SUBMITTED;
    }

    public boolean canBeApproved() {
        reviewedAt = Instant.now();
        return status == Status.SUBMITTED && grade != CreditGrade.SUBPRIME && isAffordable();
    }

    public void approve() {
        if (!canBeApproved()) {
            throw new IllegalStateException("application " + applicationId + " cannot be approved");
        }
        status = Status.APPROVED;
    }

    public void decline(String reason) {
        if (status != Status.SUBMITTED) {
            throw new IllegalStateException("application " + applicationId + " is " + status + " and cannot be declined");
        }
        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException("a decline needs a reason");
        }
        this.declineReason = reason;
        this.status = Status.DECLINED;
    }

    public boolean isAffordable() {
        BigDecimal monthlyPayment = requestedAmount.divide(BigDecimal.valueOf(termMonths), 2, RoundingMode.HALF_UP);
        return monthlyPayment.compareTo(monthlyIncome.multiply(MAX_PAYMENT_SHARE_OF_INCOME)) <= 0;
    }

    public String getApplicationId() { return applicationId; }
    public String getApplicantId() { return applicantId; }
    public BigDecimal getRequestedAmount() { return requestedAmount; }
    public int getTermMonths() { return termMonths; }
    public Status getStatus() { return status; }
    public CreditGrade getGrade() { return grade; }
    public String getDeclineReason() { return declineReason; }
    public Instant getReviewedAt() { return reviewedAt; }
}
JAVA
cat > src/lending/CreditGrade.java <<'JAVA'
package com.acme.lending;

public enum CreditGrade {
    PRIME,
    NEAR_PRIME,
    SUBPRIME;

    /** The bureau reports a band from A1 (best) to E5 (worst). */
    public static CreditGrade fromBureauBand(String band) {
        switch (band.charAt(0)) {
            case 'A':
            case 'B':
                return PRIME;
            case 'D':
            case 'E':
                return SUBPRIME;
            default:
                return NEAR_PRIME;
        }
    }
}
JAVA
cat > src/lending/LoanApplicationTest.java <<'JAVA'
package com.acme.lending;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
class LoanApplicationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    private LoanApplication anApplicationFor(String amount, int months) {
        return new LoanApplication("app-1", "cust-9", new BigDecimal("3000"), new BigDecimal(amount), months);
    }

    @Test
    void constructor_setsFields() {
        LoanApplication app = anApplicationFor("6000", 24);
        assertEquals("app-1", app.getApplicationId());
        assertEquals("cust-9", app.getApplicantId());
        assertEquals(new BigDecimal("6000"), app.getRequestedAmount());
        assertEquals(24, app.getTermMonths());
    }

    @Test
    void getStatus_returnsDraftInitially() {
        assertEquals(LoanApplication.Status.DRAFT, anApplicationFor("6000", 24).getStatus());
    }

    @Test
    void submit_setsGradeAndStatus() {
        LoanApplication app = anApplicationFor("6000", 24);
        app.submit(CreditGrade.PRIME);
        assertEquals(LoanApplication.Status.SUBMITTED, app.getStatus());
        assertEquals(CreditGrade.PRIME, app.getGrade());
    }

    @Test
    void approve_setsStatusApproved() {
        LoanApplication app = anApplicationFor("6000", 24);
        app.submit(CreditGrade.PRIME);
        app.approve();
        assertEquals(LoanApplication.Status.APPROVED, app.getStatus());
    }

    @Test
    void decline_setsReasonAndStatus() {
        LoanApplication app = anApplicationFor("6000", 24);
        app.submit(CreditGrade.NEAR_PRIME);
        app.decline("income not verified");
        assertEquals(LoanApplication.Status.DECLINED, app.getStatus());
        assertEquals("income not verified", app.getDeclineReason());
    }

    @Test
    void fromBureauBand_a1ReturnsPrime() {
        assertEquals(CreditGrade.PRIME, CreditGrade.fromBureauBand("A1"));
    }

    @Test
    void fromBureauBand_e5ReturnsSubprime() {
        assertEquals(CreditGrade.SUBPRIME, CreditGrade.fromBureauBand("E5"));
    }
}
JAVA
