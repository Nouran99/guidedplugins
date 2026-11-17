#!/usr/bin/env bash
set -e
mkdir -p src/payments

cat > src/payments/consumer.py <<'PY'
"""Consumes payment events and keeps orders, revenue and refunds in step with
what the gateway reports."""
import json
import logging
import uuid
from datetime import date

import requests

from payments import bus, db

log = logging.getLogger("payments.consumer")

GATEWAY_URL = "https://gateway.internal/v2"

# The queue is a FIFO queue with content-based deduplication, so each message
# reaches handle() once and in the order it was sent.


def run(queue):
    for message in queue.receive():
        handle(message)


def handle(message):
    event = json.loads(message.body)
    kind = event["type"]
    if kind == "payment.captured":
        on_captured(event)
    elif kind == "payment.status_changed":
        on_status_changed(event)
    elif kind == "refund.requested":
        on_refund_requested(event)
    message.ack()


def on_captured(event):
    order_id = event["order_id"]
    amount = event["amount_cents"]
    with db.transaction() as tx:
        tx.execute("UPDATE orders SET status = 'paid' WHERE id = %s", [order_id])
        tx.execute(
            "UPDATE daily_revenue SET total_cents = total_cents + %s WHERE day = %s",
            [amount, date.today()],
        )
    try:
        bus.publish("order.paid", {"order_id": order_id, "amount_cents": amount})
    except Exception:
        log.warning("order.paid was not published for %s", order_id)


def on_status_changed(event):
    # occurred_at is stamped by whichever service emitted the change: the
    # gateway webhook receiver or the fraud service.
    payment_id = event["payment_id"]
    row = db.fetch_one(
        "SELECT status, updated_at FROM payments WHERE id = %s", [payment_id]
    )
    if row is not None and event["occurred_at"] <= row["updated_at"]:
        return
    db.execute(
        "UPDATE payments SET status = %s, updated_at = %s WHERE id = %s",
        [event["status"], event["occurred_at"], payment_id],
    )


def on_refund_requested(event):
    refund_id = event["refund_id"]
    payload = {
        "payment_id": event["payment_id"],
        "amount_cents": event["amount_cents"],
    }
    for _ in range(3):
        try:
            response = requests.post(
                f"{GATEWAY_URL}/refunds",
                json=payload,
                headers={"Idempotency-Key": str(uuid.uuid4())},
                timeout=3,
            )
            response.raise_for_status()
        except requests.Timeout:
            continue
        except requests.HTTPError:
            break
        db.execute("UPDATE refunds SET status = 'done' WHERE id = %s", [refund_id])
        return
    db.execute("UPDATE refunds SET status = 'failed' WHERE id = %s", [refund_id])
PY

cat > src/payments/test_consumer.py <<'PY'
import json
from unittest import mock

import pytest

from payments import consumer


class FakeMessage:
    def __init__(self, body):
        self.body = json.dumps(body)
        self.acked = False

    def ack(self):
        self.acked = True


@pytest.fixture
def fake_db():
    with mock.patch.object(consumer, "db") as db, mock.patch.object(consumer, "bus"):
        yield db


def test_captured_payment_marks_the_order_paid(fake_db):
    message = FakeMessage({
        "type": "payment.captured",
        "order_id": "o-1",
        "amount_cents": 1250,
        "captured_at": "2026-03-01T10:15:00Z",
    })
    consumer.handle(message)
    tx = fake_db.transaction.return_value.__enter__.return_value
    assert tx.execute.call_count == 2
    assert message.acked


def test_newer_status_replaces_the_stored_one(fake_db):
    fake_db.fetch_one.return_value = {
        "status": "pending",
        "updated_at": "2026-03-01T10:00:00Z",
    }
    consumer.handle(FakeMessage({
        "type": "payment.status_changed",
        "payment_id": "p-1",
        "status": "settled",
        "occurred_at": "2026-03-01T10:05:00Z",
    }))
    fake_db.execute.assert_called_once()


def test_successful_refund_is_marked_done(fake_db):
    with mock.patch.object(consumer.requests, "post") as post:
        post.return_value.raise_for_status.return_value = None
        consumer.handle(FakeMessage({
            "type": "refund.requested",
            "refund_id": "r-1",
            "payment_id": "p-1",
            "amount_cents": 500,
        }))
    fake_db.execute.assert_called_once_with(
        "UPDATE refunds SET status = 'done' WHERE id = %s", ["r-1"]
    )
PY
