#!/usr/bin/env bash
set -e
mkdir -p jobs
cat > jobs/refund_consumer.py <<'PY'
"""Worker that applies refund requests taken from the refunds queue."""
import json
import logging

import gateway
import notifier
import orders

log = logging.getLogger("refunds")

REFUND_STATES = {"ok": "refunded", "pending": "refund_pending"}


def run(queue):
    for raw in queue:
        consume(raw)


def load_order(order_id):
    matches = orders.search(id=order_id)
    return matches[0] if matches else None


def load_charge(charge_id):
    charge = gateway.find_charge(charge_id)
    if charge is None:
        raise LookupError(f"no charge {charge_id}")
    return charge


def consume(raw):
    msg = json.loads(raw)
    assert msg["amount_cents"] > 0, "amount must be positive"
    order = load_order(msg["order_id"])
    if is_refundable(order, msg["amount_cents"]):
        return issue_refund(order, msg["amount_cents"], msg["reason"])
    return False


def is_refundable(order, amount_cents):
    left = order["paid_cents"] - order["refunded_cents"]
    if left >= amount_cents:
        orders.set_state(order["id"], "refund_requested")
        return True
    return False


def issue_refund(order, amount_cents, reason):
    charge = load_charge(order["charge_id"])
    try:
        result = gateway.refund(charge["id"], amount_cents, note=reason)
    except Exception:
        log.error("refund failed")
        return False
    orders.set_state(order["id"], REFUND_STATES.get(result["status"], "refunded"))
    notifier.send(order["email"], "Your refund is on its way")
    return True
PY
