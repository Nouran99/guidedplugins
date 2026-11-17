#!/usr/bin/env bash
set -e
mkdir -p src/pricing

cat > src/pricing/rates_client.py <<'PY'
"""Client for the internal exchange-rate service."""
import os
import time

import requests

RATES_URL = os.environ.get("RATES_URL", "https://rates.internal.example.com/v2")
CACHE_SECONDS = 600

_cache = {}


class RateUnavailable(Exception):
    def __init__(self, currency):
        super().__init__(f"no rate available for {currency}")
        self.currency = currency


def get_rate(currency):
    """Return how many euros one unit of `currency` is worth."""
    hit = _cache.get(currency)
    if hit and time.time() - hit[1] < CACHE_SECONDS:
        return hit[0]

    last_error = None
    for _ in range(5):
        try:
            resp = requests.get(f"{RATES_URL}/rates/{currency}")
            rate = resp.json()["rate"]
            _cache[currency] = (rate, time.time())
            return rate
        except Exception as exc:
            last_error = exc
            time.sleep(1)
    raise RateUnavailable(currency) from last_error


def convert_cents(amount_cents, currency):
    return round(amount_cents * get_rate(currency))
PY

cat > src/pricing/quote_service.py <<'PY'
"""Prices an order in euros using the current exchange rates."""
import time

from pricing.rates_client import RateUnavailable, get_rate

# Rate used when the rates service cannot be reached, so checkout keeps working.
FALLBACK_RATE = 1.0


def _rate_for(currency):
    if currency == "EUR":
        return 1.0
    for _ in range(3):
        try:
            return get_rate(currency)
        except RateUnavailable:
            time.sleep(0.5)
    return FALLBACK_RATE


def quote(order):
    """Return the order total in euro cents."""
    total_cents = 0
    for line in order["lines"]:
        rate = _rate_for(line["currency"])
        total_cents += round(line["unit_price_cents"] * line["quantity"] * rate)
    return {"order_id": order["id"], "currency": "EUR", "total_cents": total_cents}
PY
