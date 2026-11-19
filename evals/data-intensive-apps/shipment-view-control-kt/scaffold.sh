#!/usr/bin/env bash
set -e
mkdir -p src/shipments

cat > src/shipments/ShipmentEvent.kt <<'KT'
package shipments

import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.databind.json.JsonMapper
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.kotlinModule
import com.fasterxml.jackson.module.kotlin.readValue
import java.time.Instant

/**
 * A fact published by the shipments service, the only writer of a shipment.
 *
 * - The topic is keyed by [shipmentId] and keeps every event, with no time limit.
 * - [version] is a per-shipment sequence assigned by that service: a larger version is always a
 *   later state of the same shipment. [occurredAt] is informational and never decides order.
 * - [schemaVersion] is 1 today. A change of meaning gets a new field, never a changed one, and
 *   readers ignore fields they do not know.
 */
data class ShipmentEvent(
    val eventId: String,
    val shipmentId: String,
    val version: Long,
    val schemaVersion: Int,
    val status: String,
    val occurredAt: Instant,
)

enum class ShipmentStatus {
    CREATED, IN_TRANSIT, DELIVERED, RETURNED,

    /** A status this build does not know; the page renders it as "update in progress". */
    UNKNOWN;

    companion object {
        fun parse(raw: String): ShipmentStatus =
            entries.firstOrNull { it.name == raw && it != UNKNOWN } ?: UNKNOWN
    }
}

object ShipmentEventCodec {
    private val mapper = JsonMapper.builder()
        .addModule(kotlinModule())
        .addModule(JavaTimeModule())
        .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
        .build()

    fun decode(json: String): ShipmentEvent = mapper.readValue(json)
}
KT

cat > src/shipments/ShipmentViewConsumer.kt <<'KT'
package shipments

import java.time.Clock
import java.time.Duration

/**
 * Maintains `shipment_view`, a read model derived from the shipments topic. The topic is the
 * source of truth: the view can be dropped and rebuilt by running this same consumer over the
 * topic from the first offset.
 *
 * Atomic together: the view row and, for a delivery, the notification row in `outbox`. Not atomic
 * with them: the customer notification itself, which the relay sends at least once under the key
 * stored on the outbox row: the shipment id and the version of the event, so a second delivery after
 * a return is its own notification, while a duplicate or a replay of the same event is not. Outbox
 * rows are kept as long as the topic keeps its events, so a rebuild that replays a delivery queues no
 * second notification.
 *
 * Events of one shipment arrive in order because the topic is keyed by shipment id and a partition
 * has one consumer thread. The version check still decides, because a rebalance or a replay can
 * deliver an event again or after a newer one.
 *
 * While the view lags, the tracking page shows the last status it has; a delay of a few minutes is
 * acceptable. Metrics: `unknown_status`, `stale_or_duplicate_event` and `lag_ms` (event age when
 * handled, alerted at 5 minutes; the alert is muted while a rebuild replays old events).
 */
class ShipmentViewConsumer(
    private val db: Database,
    private val metrics: Metrics,
    private val clock: Clock,
) {
    fun handle(json: String) {
        val event = ShipmentEventCodec.decode(json)
        val status = ShipmentStatus.parse(event.status)
        if (status == ShipmentStatus.UNKNOWN) {
            metrics.count("shipment_view.unknown_status")
        }

        val applied = db.inTransaction { tx ->
            val changed = tx.update(
                UPSERT_VIEW, event.shipmentId, status.name, event.version, event.occurredAt,
            )
            if (changed == 1 && status == ShipmentStatus.DELIVERED) {
                tx.update(
                    INSERT_OUTBOX,
                    "shipment-delivered:${event.shipmentId}:${event.version}",
                    "shipment.delivered",
                    event.shipmentId,
                )
            }
            changed == 1
        }

        if (!applied) {
            metrics.count("shipment_view.stale_or_duplicate_event")
        }
        metrics.gauge(
            "shipment_view.lag_ms",
            Duration.between(event.occurredAt, clock.instant()).toMillis(),
        )
    }

    private companion object {
        // Applies the event only when it is newer than what the row already reflects, so a
        // duplicate or an older event changes nothing and reports zero rows.
        const val UPSERT_VIEW = """
            INSERT INTO shipment_view (shipment_id, status, source_version, occurred_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT (shipment_id) DO UPDATE
               SET status = EXCLUDED.status,
                   source_version = EXCLUDED.source_version,
                   occurred_at = EXCLUDED.occurred_at
             WHERE shipment_view.source_version < EXCLUDED.source_version
        """

        const val INSERT_OUTBOX = """
            INSERT INTO outbox (dedup_key, topic, payload) VALUES (?, ?, ?)
            ON CONFLICT (dedup_key) DO NOTHING
        """
    }
}
KT

cat > src/shipments/ShipmentViewConsumerTest.kt <<'KT'
package shipments

import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlin.test.assertEquals

class ShipmentViewConsumerTest {
    private val db = TestPostgres.freshDatabase()
    private val metrics = RecordingMetrics()
    private val clock = Clock.fixed(Instant.parse("2026-03-01T12:00:00Z"), ZoneOffset.UTC)
    private val consumer = ShipmentViewConsumer(db, metrics, clock)

    @BeforeEach
    fun emptyTables() = db.truncate("shipment_view", "outbox")

    private fun event(id: String, version: Long, status: String, extra: String = "") = """
        {"eventId":"$id","shipmentId":"s-1","version":$version,"schemaVersion":1,
         "status":"$status","occurredAt":"2026-03-01T11:00:00Z"$extra}
    """.trimIndent()

    private fun view() =
        db.queryOne("SELECT status, source_version FROM shipment_view WHERE shipment_id = 's-1'")

    @Test
    fun `a duplicate delivery changes nothing and queues one notification`() {
        val delivered = event("e-3", 3, "DELIVERED")

        consumer.handle(delivered)
        consumer.handle(delivered)

        assertEquals("DELIVERED", view().getString("status"))
        assertEquals(1, db.count("outbox"))
        assertEquals(1, metrics.counter("shipment_view.stale_or_duplicate_event"))
    }

    @Test
    fun `an older event arriving late does not overwrite a newer state`() {
        consumer.handle(event("e-2", 2, "IN_TRANSIT"))
        consumer.handle(event("e-1", 1, "CREATED"))

        assertEquals("IN_TRANSIT", view().getString("status"))
        assertEquals(2L, view().getLong("source_version"))
        assertEquals(1, metrics.counter("shipment_view.stale_or_duplicate_event"))
    }

    @Test
    fun `replaying the whole history rebuilds the same view without a second notification`() {
        val history = listOf(
            event("e-1", 1, "CREATED"),
            event("e-2", 2, "IN_TRANSIT"),
            event("e-3", 3, "DELIVERED"),
        )
        history.forEach(consumer::handle)
        val live = view().getString("status") to view().getLong("source_version")

        db.truncate("shipment_view")
        history.forEach(consumer::handle)

        assertEquals(live, view().getString("status") to view().getLong("source_version"))
        assertEquals(1, db.count("outbox"))
    }

    @Test
    fun `a second delivery after a return is its own notification and a replay adds none`() {
        val history = listOf(
            event("e-3", 3, "DELIVERED"),
            event("e-4", 4, "RETURNED"),
            event("e-5", 5, "DELIVERED"),
        )
        history.forEach(consumer::handle)
        assertEquals(2, db.count("outbox"))

        db.truncate("shipment_view")
        history.forEach(consumer::handle)

        assertEquals("DELIVERED", view().getString("status"))
        assertEquals(2, db.count("outbox"))
    }

    @Test
    fun `an unknown status and an unknown field are accepted and counted`() {
        consumer.handle(event("e-1", 1, "LOST_AT_SEA", extra = ",\"carrierNote\":\"new field\""))

        assertEquals("UNKNOWN", view().getString("status"))
        assertEquals(1, metrics.counter("shipment_view.unknown_status"))
    }
}
KT
