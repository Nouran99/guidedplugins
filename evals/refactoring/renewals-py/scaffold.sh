#!/usr/bin/env bash
set -e
mkdir -p src tests
cat > src/renewals.py <<'PY'
import logging
from datetime import datetime, timedelta

import gateway
import settings
from db import connect
from mailer import send_mail

log = logging.getLogger(__name__)


def is_due_for_renewal(sub):
    due_from = sub["renews_on"] - timedelta(days=settings.RENEWAL_LEAD_DAYS)
    return datetime.utcnow() >= due_from


def get_amount_due(sub):
    amount = sub["plan_cents"]
    if sub["billing"] == "annual":
        amount = amount * 12 * 0.9
    amount = amount + amount * settings.TAX_RATE
    with connect() as db:
        db.execute(
            "update subscriptions set quoted_cents = ? where id = ?",
            (int(amount), sub["id"]),
        )
    return int(round(amount))


def amount_for_upgrade(sub, new_plan_cents):
    amount = new_plan_cents
    if sub["billing"] == "annual":
        amount = amount * 12 * 0.9
    amount = amount + amount * settings.TAX_RATE
    return int(amount)


def format_amount(cents, currency):
    return "%d.%02d %s" % (cents // 100, cents % 100, currency)


def charge_card(token, cents, currency):
    log.info("charging %s", format_amount(cents, currency))
    return gateway.charge(token, cents, currency)


def record_payment(sub_id, cents, currency):
    with connect() as db:
        db.execute(
            "insert into payments (sub_id, cents, currency) values (?, ?, ?)",
            (sub_id, cents, currency),
        )


def renew_due(subs, notify=True, dry_run=False, retry=False):
    results = []
    for sub in subs:
        if not is_due_for_renewal(sub):
            continue
        total = get_amount_due(sub)
        with connect() as db:
            row = db.execute(
                "select token from cards where customer_id = ?", (sub["customer_id"],)
            ).fetchone()
        if row is None:
            results.append((sub["id"], "no-card"))
            continue
        # if sub["plan"] == "legacy":
        #     total = total - 500
        ok = True
        if not dry_run:
            ok = charge_card(row[0], total, "EUR")
            if not ok and retry:
                ok = charge_card(row[0], total, "EUR")
            if ok:
                record_payment(sub["id"], total, "EUR")
                days = 365 if sub["billing"] == "annual" else 30
                with connect() as db:
                    db.execute(
                        "update subscriptions set renews_on = ? where id = ?",
                        (sub["renews_on"] + timedelta(days=days), sub["id"]),
                    )
        if ok and notify:
            total = format_amount(total, "EUR")
            send_mail(sub["email"], "Your renewal", "Thanks, we charged " + total + ".")
        results.append((sub["id"], "renewed" if ok else "failed"))
    return results
PY
cat > tests/test_renewals.py <<'PY'
from datetime import datetime, timedelta

import renewals


def test_format_amount_pads_the_cents():
    assert renewals.format_amount(1205, "EUR") == "12.05 EUR"


def test_upgrade_price_on_a_monthly_plan_adds_tax(monkeypatch):
    monkeypatch.setattr(renewals.settings, "TAX_RATE", 0.2)
    assert renewals.amount_for_upgrade({"billing": "monthly"}, 1000) == 1200


def test_subscription_is_due_inside_the_lead_window(monkeypatch):
    monkeypatch.setattr(renewals.settings, "RENEWAL_LEAD_DAYS", 3)
    sub = {"renews_on": datetime.utcnow() + timedelta(days=2)}
    assert renewals.is_due_for_renewal(sub)


def test_renew_due_with_nothing_due():
    assert renewals.renew_due([], True, False, False) == []
PY
