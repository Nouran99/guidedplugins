#!/usr/bin/env bash
set -e
mkdir -p src/stays
cat > src/stays/README.md <<'MD'
# Stays

Bounded context for reservations: a guest asks for a room type for some nights, and the hotel confirms or cancels it.

- Subdomain: core. How we hold and confirm rooms is why hotels choose us, so this is where the modeling effort goes.
- A reservation is confirmed at most once, never after it was cancelled and never on or after its arrival day. A stay has at least one night.
- Room types are reference data from the revenue team: plain data, no rules.
- Neighbour: billing is downstream and conforms to our events as published. ReservationConfirmed carries the deposit due, so billing never asks back. ReservationCancelled carries ids only, and billing voids the deposit invoice when it arrives. Stays never calls billing.
- EventPublisher is a port. The messaging adapter, outside this folder, maps the events to the versioned messages billing reads.
- Terms: reservation, guest, stay, arrival, departure, confirm, cancel, deposit.
MD
cat > src/stays/Money.kt <<'KT'
package stays

/** An amount in the smallest unit of one currency (cents for EUR). Never negative. */
data class Money(val minorUnits: Long, val currency: String) {
    init {
        require(minorUnits >= 0) { "money cannot be negative" }
        require(currency.length == 3) { "currency must be a three-letter code" }
    }

    operator fun plus(other: Money): Money {
        require(currency == other.currency) { "cannot add $other to $this" }
        return Money(minorUnits + other.minorUnits, currency)
    }

    operator fun times(count: Int): Money = Money(minorUnits * count, currency)

    /** Rounds down to the minor unit. */
    fun percent(percentage: Percentage): Money = Money(minorUnits * percentage.whole / 100, currency)
}

/** A whole percentage from 0 to 100. */
@JvmInline
value class Percentage(val whole: Int) {
    init {
        require(whole in 0..100) { "a percentage is between 0 and 100" }
    }
}
KT
cat > src/stays/StayPeriod.kt <<'KT'
package stays

import java.time.LocalDate
import java.time.temporal.ChronoUnit

/** The nights a guest asks for: from the arrival day up to, but not including, the departure day. */
data class StayPeriod(val arrival: LocalDate, val departure: LocalDate) {
    init {
        require(departure.isAfter(arrival)) { "a stay needs at least one night" }
    }

    val nights: Int get() = ChronoUnit.DAYS.between(arrival, departure).toInt()
}
KT
cat > src/stays/RoomTypes.kt <<'KT'
package stays

@JvmInline
value class RoomTypeCode(val value: String)

data class RoomType(val code: RoomTypeCode, val name: String, val sleeps: Int)

// Reference data kept by the revenue team. It has no rules and no lifecycle of its own.
val ROOM_TYPES = listOf(
    RoomType(RoomTypeCode("STD"), "Standard", 2),
    RoomType(RoomTypeCode("FAM"), "Family", 4),
    RoomType(RoomTypeCode("STE"), "Suite", 3),
)

fun roomTypeFor(code: RoomTypeCode): RoomType? = ROOM_TYPES.firstOrNull { it.code == code }
KT
cat > src/stays/Reservation.kt <<'KT'
package stays

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID

// Stays context. A reservation is a guest's request to hold one room type for a stay.
// The hotel confirms it, and either side can cancel it.

@JvmInline
value class ReservationId(val value: String)

@JvmInline
value class GuestId(val value: String)

enum class ReservationStatus { REQUESTED, CONFIRMED, CANCELLED }

class InvalidTransition(id: ReservationId, status: ReservationStatus, attempt: String) :
    IllegalStateException("reservation ${id.value} is $status and cannot be $attempt")

sealed interface ReservationEvent {
    val eventId: String
    val occurredAt: Instant
}

data class ReservationConfirmed(
    val reservationId: ReservationId,
    val guestId: GuestId,
    val depositDue: Money,
    override val occurredAt: Instant,
    override val eventId: String = UUID.randomUUID().toString(),
) : ReservationEvent

data class ReservationCancelled(
    val reservationId: ReservationId,
    val guestId: GuestId,
    override val occurredAt: Instant,
    override val eventId: String = UUID.randomUUID().toString(),
) : ReservationEvent

class Reservation(
    val id: ReservationId,
    val guestId: GuestId,
    val roomType: RoomTypeCode,
    val stay: StayPeriod,
    val nightlyRate: Money,
) {
    var status: ReservationStatus = ReservationStatus.REQUESTED
        private set

    /** Stays of a week or more need a deposit, as agreed with revenue management. */
    fun depositDue(): Money =
        if (stay.nights >= LONG_STAY_NIGHTS) (nightlyRate * stay.nights).percent(DEPOSIT_PERCENTAGE)
        else Money(0, nightlyRate.currency)

    fun confirm(now: Instant): ReservationConfirmed {
        if (status != ReservationStatus.REQUESTED) throw InvalidTransition(id, status, "confirmed")
        if (!LocalDate.ofInstant(now, ZoneOffset.UTC).isBefore(stay.arrival)) {
            throw InvalidTransition(id, status, "confirmed on or after its arrival day")
        }
        status = ReservationStatus.CONFIRMED
        return ReservationConfirmed(id, guestId, depositDue(), now)
    }

    fun cancel(now: Instant): ReservationCancelled {
        if (status == ReservationStatus.CANCELLED) throw InvalidTransition(id, status, "cancelled")
        status = ReservationStatus.CANCELLED
        return ReservationCancelled(id, guestId, now)
    }

    private companion object {
        const val LONG_STAY_NIGHTS = 7
        val DEPOSIT_PERCENTAGE = Percentage(20)
    }
}
KT
cat > src/stays/ReservationService.kt <<'KT'
package stays

import java.time.Clock
import java.time.Instant

data class ConfirmReservation(val reservationId: ReservationId)

data class CancelReservation(val reservationId: ReservationId)

interface Reservations {
    fun get(id: ReservationId): Reservation
    fun save(reservation: Reservation)
}

fun interface EventPublisher {
    fun publish(event: ReservationEvent)
}

class ReservationService(
    private val reservations: Reservations,
    private val publisher: EventPublisher,
    private val clock: Clock,
) {
    fun confirm(command: ConfirmReservation) {
        val reservation = reservations.get(command.reservationId)
        val confirmed = reservation.confirm(Instant.now(clock))
        reservations.save(reservation)
        publisher.publish(confirmed)
    }

    fun cancel(command: CancelReservation) {
        val reservation = reservations.get(command.reservationId)
        val cancelled = reservation.cancel(Instant.now(clock))
        reservations.save(reservation)
        publisher.publish(cancelled)
    }
}
KT
cat > src/stays/ReservationTest.kt <<'KT'
package stays

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

private val arrival = LocalDate.of(2026, 3, 10)
private val aWeekBefore = Instant.parse("2026-03-03T09:00:00Z")
private val arrivalMorning = Instant.parse("2026-03-10T08:00:00Z")

private fun reservationFor(nights: Long): Reservation = Reservation(
    id = ReservationId("r-1"),
    guestId = GuestId("g-1"),
    roomType = RoomTypeCode("STD"),
    stay = StayPeriod(arrival, arrival.plusDays(nights)),
    nightlyRate = Money(12_000, "EUR"),
)

class ReservationTest {
    @Test
    fun `a requested reservation is confirmed before the guest arrives`() {
        val reservation = reservationFor(3)
        reservation.confirm(aWeekBefore)
        assertEquals(ReservationStatus.CONFIRMED, reservation.status)
    }

    @Test
    fun `a confirmed reservation cannot be confirmed again`() {
        val reservation = reservationFor(3)
        reservation.confirm(aWeekBefore)
        assertThrows(InvalidTransition::class.java) { reservation.confirm(aWeekBefore) }
    }

    @Test
    fun `a reservation cannot be confirmed on its arrival day`() {
        assertThrows(InvalidTransition::class.java) { reservationFor(3).confirm(arrivalMorning) }
    }

    @Test
    fun `a cancelled reservation cannot be confirmed`() {
        val reservation = reservationFor(3)
        reservation.cancel(aWeekBefore)
        assertThrows(InvalidTransition::class.java) { reservation.confirm(aWeekBefore) }
    }

    @Test
    fun `a confirmed reservation can still be cancelled`() {
        val reservation = reservationFor(3)
        reservation.confirm(aWeekBefore)
        reservation.cancel(aWeekBefore)
        assertEquals(ReservationStatus.CANCELLED, reservation.status)
    }

    @Test
    fun `a reservation cannot be cancelled twice`() {
        val reservation = reservationFor(3)
        reservation.cancel(aWeekBefore)
        assertThrows(InvalidTransition::class.java) { reservation.cancel(aWeekBefore) }
    }

    @Test
    fun `a stay of seven nights asks for a twenty percent deposit`() {
        assertEquals(Money(16_800, "EUR"), reservationFor(7).depositDue())
    }

    @Test
    fun `a stay of six nights asks for no deposit`() {
        assertEquals(Money(0, "EUR"), reservationFor(6).depositDue())
    }

    @Test
    fun `confirming tells the hotel how much deposit is due`() {
        val confirmed = reservationFor(7).confirm(aWeekBefore)
        assertEquals(Money(16_800, "EUR"), confirmed.depositDue)
    }

    @Test
    fun `cancelling tells the hotel which reservation was cancelled`() {
        val cancelled = reservationFor(3).cancel(aWeekBefore)
        assertEquals(ReservationId("r-1"), cancelled.reservationId)
    }
}

class ReservationServiceTest {
    private class FakeReservations(private val stored: Map<ReservationId, Reservation>) : Reservations {
        var saves = 0

        override fun get(id: ReservationId): Reservation = stored.getValue(id)

        override fun save(reservation: Reservation) { saves++ }
    }

    private val reservation = reservationFor(3)
    private val reservations = FakeReservations(mapOf(reservation.id to reservation))
    private val published = mutableListOf<ReservationEvent>()
    private val service = ReservationService(
        reservations,
        { event -> published.add(event) },
        Clock.fixed(aWeekBefore, ZoneOffset.UTC),
    )

    @Test
    fun `confirming a reservation saves it and publishes the confirmation`() {
        service.confirm(ConfirmReservation(reservation.id))

        assertEquals(1, reservations.saves)
        assertTrue(published.single() is ReservationConfirmed)
    }

    @Test
    fun `cancelling a reservation saves it and publishes the cancellation`() {
        service.cancel(CancelReservation(reservation.id))

        assertEquals(1, reservations.saves)
        assertTrue(published.single() is ReservationCancelled)
    }
}
KT
cat > src/stays/MoneyTest.kt <<'KT'
package stays

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test

class MoneyTest {
    @Test
    fun `money cannot be negative`() {
        assertThrows(IllegalArgumentException::class.java) { Money(-1, "EUR") }
    }

    @Test
    fun `a currency is a three-letter code`() {
        assertThrows(IllegalArgumentException::class.java) { Money(100, "EURO") }
    }

    @Test
    fun `money in the same currency adds up`() {
        assertEquals(Money(350, "EUR"), Money(100, "EUR") + Money(250, "EUR"))
    }

    @Test
    fun `money in different currencies cannot be added`() {
        assertThrows(IllegalArgumentException::class.java) { Money(100, "EUR") + Money(100, "USD") }
    }

    @Test
    fun `money is multiplied by a count`() {
        assertEquals(Money(36_000, "EUR"), Money(12_000, "EUR") * 3)
    }

    @Test
    fun `a percentage of money rounds down to the minor unit`() {
        assertEquals(Money(33, "EUR"), Money(167, "EUR").percent(Percentage(20)))
    }
}

class PercentageTest {
    @Test
    fun `a percentage cannot be above one hundred`() {
        assertThrows(IllegalArgumentException::class.java) { Percentage(101) }
    }

    @Test
    fun `a percentage cannot be negative`() {
        assertThrows(IllegalArgumentException::class.java) { Percentage(-1) }
    }
}
KT
cat > src/stays/StayPeriodTest.kt <<'KT'
package stays

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test
import java.time.LocalDate

class StayPeriodTest {
    private val arrival = LocalDate.of(2026, 3, 10)

    @Test
    fun `a stay counts the nights from arrival to departure`() {
        assertEquals(3, StayPeriod(arrival, arrival.plusDays(3)).nights)
    }

    @Test
    fun `a stay needs at least one night`() {
        assertThrows(IllegalArgumentException::class.java) { StayPeriod(arrival, arrival) }
    }
}
KT
