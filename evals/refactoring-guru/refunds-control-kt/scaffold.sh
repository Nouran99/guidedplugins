#!/usr/bin/env bash
set -e
mkdir -p src/refunds
cat > src/refunds/Refunds.kt <<'KT'
package refunds

import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Money in minor units. A negative amount is a bug upstream, so it fails fast instead of flowing on.
 * Amounts are small by contract (the API edge rejects anything above 100,000,000), so the products below fit in a Long.
 */
@JvmInline
value class Cents(val value: Long) {
    init {
        require(value >= 0) { "amount must not be negative: $value" }
    }

    operator fun minus(other: Cents): Cents = Cents(value - other.value)

    /** [rate] percent of this amount, rounded down. */
    fun percentage(rate: Long): Cents = Cents(value * rate / 100)

    /** This amount scaled to [part] out of [whole], rounded down. */
    fun prorated(part: Cents, whole: Cents): Cents = Cents(value * part.value / whole.value)
}

enum class Reason { DEFECTIVE, NOT_AS_DESCRIBED, CHANGED_MIND }

const val RETURN_WINDOW_DAYS = 30L
const val RESTOCKING_PERCENT = 15L

data class Purchase(
    val id: String,
    val paid: Cents,
    val tax: Cents,
    val shipping: Cents,
    val boughtOn: LocalDate,
    val opened: Boolean,
) {
    init {
        require(paid.value > 0) { "a purchase must have been paid for" }
    }

    /**
     * The refund owed for this purchase, or null when none is owed.
     * Defective goods are refunded in full even after the window: consumer-protection law requires it.
     */
    fun refundFor(reason: Reason, today: LocalDate): Cents? {
        val withinWindow = ChronoUnit.DAYS.between(boughtOn, today) <= RETURN_WINDOW_DAYS
        return when (reason) {
            Reason.DEFECTIVE -> paid
            Reason.NOT_AS_DESCRIBED -> if (withinWindow) paid else null
            Reason.CHANGED_MIND -> when {
                !withinWindow -> null
                opened -> paid - restockingFee()
                else -> paid
            }
        }
    }

    // The fee is rounded down, in the customer's favor.
    private fun restockingFee(): Cents = paid.percentage(RESTOCKING_PERCENT)

    // taxRefund and shippingRefund look alike on purpose: tax comes back under the jurisdiction's
    // refund rule and shipping under the carrier contract, so they change for different reasons.
    fun taxRefund(refunded: Cents): Cents = tax.prorated(refunded, paid)

    fun shippingRefund(refunded: Cents): Cents = shipping.prorated(refunded, paid)
}

/** The payment provider side of a refund: the real client in production, a fake in the tests. */
interface RefundGateway {
    /** True when the provider accepted the refund. */
    fun send(purchaseId: String, amount: Cents): Boolean
}

sealed interface Outcome {
    data class Refunded(val amount: Cents, val taxPart: Cents, val shippingPart: Cents) : Outcome
    data class Declined(val why: String) : Outcome
}

class RefundService(private val gateway: RefundGateway) {

    fun request(purchase: Purchase, reason: Reason, today: LocalDate): Outcome {
        val amount = purchase.refundFor(reason, today)
            ?: return Outcome.Declined("outside the $RETURN_WINDOW_DAYS-day return window")
        if (!gateway.send(purchase.id, amount)) {
            return Outcome.Declined("the payment provider refused the refund")
        }
        return Outcome.Refunded(amount, purchase.taxRefund(amount), purchase.shippingRefund(amount))
    }
}
KT
cat > src/refunds/RefundsTest.kt <<'KT'
package refunds

import java.time.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

private class FakeGateway(private val accepts: Boolean) : RefundGateway {
    val sent = mutableListOf<Pair<String, Cents>>()

    override fun send(purchaseId: String, amount: Cents): Boolean {
        sent += purchaseId to amount
        return accepts
    }
}

class RefundsTest {
    private val bought = LocalDate.of(2025, 3, 1)

    private fun purchase(paid: Long = 10_000, opened: Boolean = false) =
        Purchase("p-1", Cents(paid), tax = Cents(1_600), shipping = Cents(500), boughtOn = bought, opened = opened)

    @Test
    fun `an unopened purchase is refunded in full on the last day of the window`() {
        assertEquals(Cents(10_000), purchase().refundFor(Reason.CHANGED_MIND, bought.plusDays(30)))
    }

    @Test
    fun `a change of mind one day after the window is not refunded`() {
        assertNull(purchase().refundFor(Reason.CHANGED_MIND, bought.plusDays(31)))
    }

    @Test
    fun `opened goods lose the restocking fee`() {
        assertEquals(Cents(8_500), purchase(opened = true).refundFor(Reason.CHANGED_MIND, bought.plusDays(3)))
    }

    @Test
    fun `the restocking fee is rounded down`() {
        // 15 percent of 999 is 149.85, so the fee is 149 and the refund 850
        assertEquals(Cents(850), purchase(paid = 999, opened = true).refundFor(Reason.CHANGED_MIND, bought))
    }

    @Test
    fun `defective goods are refunded in full after the window`() {
        assertEquals(Cents(10_000), purchase(opened = true).refundFor(Reason.DEFECTIVE, bought.plusDays(90)))
    }

    @Test
    fun `a description mismatch after the window is not refunded`() {
        assertNull(purchase().refundFor(Reason.NOT_AS_DESCRIBED, bought.plusDays(45)))
    }

    @Test
    fun `a description mismatch inside the window is refunded in full`() {
        assertEquals(Cents(10_000), purchase().refundFor(Reason.NOT_AS_DESCRIBED, bought.plusDays(10)))
    }

    @Test
    fun `a negative amount is rejected`() {
        assertFailsWith<IllegalArgumentException> { Cents(-1) }
    }

    @Test
    fun `a purchase that was not paid for is rejected`() {
        assertFailsWith<IllegalArgumentException> { purchase(paid = 0) }
    }

    @Test
    fun `a refund is split between tax and shipping in proportion`() {
        val gateway = FakeGateway(accepts = true)
        val outcome = RefundService(gateway).request(purchase(opened = true), Reason.CHANGED_MIND, bought.plusDays(2))
        val refunded = assertIs<Outcome.Refunded>(outcome)
        assertEquals(Cents(1_360), refunded.taxPart)
        assertEquals(Cents(425), refunded.shippingPart)
        assertEquals(listOf("p-1" to Cents(8_500)), gateway.sent)
    }

    @Test
    fun `a request outside the window never reaches the provider`() {
        val gateway = FakeGateway(accepts = true)
        val outcome = RefundService(gateway).request(purchase(), Reason.CHANGED_MIND, bought.plusDays(60))
        assertIs<Outcome.Declined>(outcome)
        assertTrue(gateway.sent.isEmpty())
    }

    @Test
    fun `a refusal by the provider is reported as declined`() {
        val outcome = RefundService(FakeGateway(accepts = false)).request(purchase(), Reason.DEFECTIVE, bought.plusDays(1))
        assertEquals(Outcome.Declined("the payment provider refused the refund"), outcome)
    }
}
KT
