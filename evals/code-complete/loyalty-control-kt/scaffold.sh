#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/LoyaltyTiers.kt <<'KT'
package loyalty

/** Largest point balance an account can hold; the API edge rejects anything above it. */
const val MAX_POINTS = 10_000_000

private val VALID_POINTS = 0..MAX_POINTS

/** Accounts with at least [minPoints] points get [percent] percent off. */
internal data class Tier(val minPoints: Int, val percent: Int)

/** Rows ascend by threshold and the first starts at 0, so every valid balance falls in exactly one tier. */
private val TIERS: List<Tier> = validatedTiers(
    listOf(
        Tier(minPoints = 0, percent = 0),
        Tier(minPoints = 500, percent = 5),
        Tier(minPoints = 2_000, percent = 10),
        Tier(minPoints = 10_000, percent = 15),
    ),
)

/** Returns [tiers] unchanged, or fails naming the broken rule (start at 0 points, strictly ascending thresholds). */
internal fun validatedTiers(tiers: List<Tier>): List<Tier> {
    require(tiers.firstOrNull()?.minPoints == 0) { "the first tier must start at 0 points" }
    require(tiers.zipWithNext().all { (lower, higher) -> lower.minPoints < higher.minPoints }) {
        "tier thresholds must strictly ascend"
    }
    return tiers
}

/**
 * Returns the discount percent (0..100) for an account holding [points].
 *
 * Requires: [points] in 0..[MAX_POINTS]; callers with raw input use [parsePoints].
 * Ensures: the percent never decreases as points grow.
 * Throws [IllegalArgumentException] when [points] is out of range.
 */
fun discountPercent(points: Int): Int {
    require(points in VALID_POINTS) { "points out of range: $points" }
    return TIERS.last { points >= it.minPoints }.percent
}

/**
 * Turns a raw request parameter into a valid point balance.
 * Throws [IllegalArgumentException], with a message that names the input, when it is missing, not a whole
 * number or out of range.
 */
fun parsePoints(raw: String?): Int {
    val points = raw?.trim()?.toIntOrNull()
        ?: throw IllegalArgumentException("points must be a whole number, got '$raw'")
    require(points in VALID_POINTS) { "points must be between 0 and $MAX_POINTS, got $points" }
    return points
}

/**
 * Price in cents after the loyalty discount; the discount is rounded down to a whole cent.
 *
 * Requires: [priceCents] >= 0 and [points] valid as for [discountPercent].
 */
fun discountedPriceCents(priceCents: Long, points: Int): Long {
    require(priceCents >= 0) { "priceCents must be >= 0, got $priceCents" }
    return priceCents - priceCents * discountPercent(points) / 100
}
KT
cat > src/LoyaltyTiersTest.kt <<'KT'
package loyalty

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class LoyaltyTiersTest {
    @Test
    fun `an empty balance gets no discount`() = assertEquals(0, discountPercent(0))

    @Test
    fun `one point below the 5 percent tier gets no discount`() = assertEquals(0, discountPercent(499))

    @Test
    fun `exactly at the 5 percent threshold gets 5 percent`() = assertEquals(5, discountPercent(500))

    @Test
    fun `one point below the 10 percent tier still gets 5 percent`() = assertEquals(5, discountPercent(1_999))

    @Test
    fun `exactly at the 10 percent threshold gets 10 percent`() = assertEquals(10, discountPercent(2_000))

    @Test
    fun `one point below the 15 percent tier still gets 10 percent`() = assertEquals(10, discountPercent(9_999))

    @Test
    fun `exactly at the 15 percent threshold gets 15 percent`() = assertEquals(15, discountPercent(10_000))

    @Test
    fun `the maximum balance gets the top discount`() = assertEquals(15, discountPercent(MAX_POINTS))

    @Test
    fun `a negative balance is rejected`() {
        assertFailsWith<IllegalArgumentException> { discountPercent(-1) }
    }

    @Test
    fun `a balance above the maximum is rejected`() {
        assertFailsWith<IllegalArgumentException> { discountPercent(MAX_POINTS + 1) }
    }

    @Test
    fun `the discount never decreases as points grow`() {
        val percents = (0..12_000).map(::discountPercent)
        assertTrue(percents.zipWithNext().all { (lower, higher) -> lower <= higher })
    }

    @Test
    fun `parsePoints trims and accepts a whole number`() = assertEquals(750, parsePoints(" 750 "))

    @Test
    fun `parsePoints rejects text and names the input`() {
        val error = assertFailsWith<IllegalArgumentException> { parsePoints("lots") }
        assertTrue(error.message.orEmpty().contains("lots"))
    }

    @Test
    fun `parsePoints rejects a missing value`() {
        assertFailsWith<IllegalArgumentException> { parsePoints(null) }
    }

    @Test
    fun `parsePoints rejects a negative balance`() {
        assertFailsWith<IllegalArgumentException> { parsePoints("-1") }
    }

    @Test
    fun `parsePoints rejects a balance above the maximum`() {
        assertFailsWith<IllegalArgumentException> { parsePoints((MAX_POINTS + 1).toString()) }
    }

    @Test
    fun `a 10 percent account pays 900 cents for a 1000 cent item`() =
        assertEquals(900L, discountedPriceCents(1_000, 2_000))

    @Test
    fun `the discount is rounded down to a whole cent`() = assertEquals(950L, discountedPriceCents(999, 500))

    @Test
    fun `a free item stays free at the top discount`() = assertEquals(0L, discountedPriceCents(0, 10_000))

    @Test
    fun `a negative price is rejected`() {
        assertFailsWith<IllegalArgumentException> { discountedPriceCents(-1, 0) }
    }

    @Test
    fun `an empty tier table is rejected`() {
        assertFailsWith<IllegalArgumentException> { validatedTiers(emptyList()) }
    }

    @Test
    fun `a tier table that does not start at 0 points is rejected`() {
        assertFailsWith<IllegalArgumentException> { validatedTiers(listOf(Tier(minPoints = 100, percent = 5))) }
    }

    @Test
    fun `a tier table whose thresholds do not strictly ascend is rejected`() {
        val tiers = listOf(
            Tier(minPoints = 0, percent = 0),
            Tier(minPoints = 500, percent = 5),
            Tier(minPoints = 500, percent = 10),
        )
        assertFailsWith<IllegalArgumentException> { validatedTiers(tiers) }
    }
}
KT
