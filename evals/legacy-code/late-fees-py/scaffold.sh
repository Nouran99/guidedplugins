#!/usr/bin/env bash
set -e
mkdir -p src/billing
: > src/billing/__init__.py

cat > src/billing/settings.py <<'PY'
import os

_instance = None


class Settings:
    def __init__(self):
        self.db_url = os.environ["BILLING_DB_URL"]
        self.grace_days = int(os.environ.get("LATE_FEE_GRACE_DAYS", "5"))
        self.fee_percent = float(os.environ.get("LATE_FEE_PERCENT", "1.5"))
        self.report_dir = os.environ.get("LATE_FEE_REPORT_DIR", "/var/billing/reports")


def get():
    global _instance
    if _instance is None:
        _instance = Settings()
    return _instance
PY

cat > src/billing/late_fees.py <<'PY'
import csv
import logging
import os
import sys
from datetime import date, timedelta

import psycopg2

from billing import settings

log = logging.getLogger(__name__)


class LateFeeJob:
    def __init__(self):
        self.conn = psycopg2.connect(settings.get().db_url)
        self.conn.autocommit = False

    def run(self):
        cfg = settings.get()
        cutoff = date.today() - timedelta(days=cfg.grace_days)
        cur = self.conn.cursor()
        cur.execute(
            "select id, customer_id, balance_cents, due_date, on_hold "
            "from invoices where status = 'open' and due_date < %s",
            (cutoff,),
        )
        rows = cur.fetchall()

        path = os.path.join(cfg.report_dir, "late-fees-%s.csv" % date.today().isoformat())
        total = 0
        with open(path, "w", newline="") as out:
            writer = csv.writer(out)
            writer.writerow(["invoice", "customer", "fee_cents"])
            for invoice_id, customer_id, balance, due, on_hold in rows:
                if on_hold:
                    log.info("invoice %s skipped, customer %s is on hold", invoice_id, customer_id)
                    continue
                fee = int(balance * cfg.fee_percent / 100)
                if (date.today() - due).days > 60:
                    fee *= 2
                fee = max(100, min(fee, 50_000))
                cur.execute(
                    "update invoices set late_fee_cents = %s where id = %s",
                    (fee, invoice_id),
                )
                writer.writerow([invoice_id, customer_id, fee])
                total += fee

        if total == 0:
            log.error("no late fees were computed, rolling back")
            self.conn.rollback()
            sys.exit(3)

        self.conn.commit()
        log.info("late fees charged: %d cents", total)
        return total


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    LateFeeJob().run()
PY
