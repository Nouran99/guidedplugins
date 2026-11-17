#!/usr/bin/env bash
set -e
mkdir -p src/claims src/renewals src/shared
cat > src/shared/models.py <<'PY'
"""Domain types for the motor policy platform."""
from dataclasses import dataclass, field
from datetime import date
from typing import List, Optional


@dataclass
class Vehicle:
    reg: str
    make: str
    model: str
    year: int
    value: float


@dataclass
class Customer:
    id: str
    name: str
    email: str
    date_of_birth: date
    postcode: str
    policy_no: Optional[str] = None
    vehicle: Optional[Vehicle] = None
    years_with_us: int = 0
    claim_free_years: int = 0
    renewal_due_on: Optional[date] = None
    last_quote: Optional[float] = None
    open_claim_ids: List[str] = field(default_factory=list)
    open_claim_total: float = 0.0
    fraud_flag: bool = False
    preferred_garage: Optional[str] = None

    def label(self) -> str:
        return f"{self.name} ({self.policy_no or 'no policy'})"
PY
cat > src/renewals/legacy_pas.py <<'PY'
"""Read access to the policy administration system (PAS).

Record fields: POL_STS_CD (A active, L lapsed, X cancelled), PREM_AMT (annual
premium), VEH_YR (year of the insured vehicle) and LAPSE_DT (ISO date, only on
lapsed policies).
"""
import requests

PAS_URL = "https://pas.internal.example/api/v2"


class PolicyAdapter:
    """Adapter for the PAS."""

    def __init__(self, session=None):
        self._http = session or requests.Session()

    def get_policy(self, policy_no):
        response = self._http.get(f"{PAS_URL}/policies/{policy_no}", timeout=5)
        response.raise_for_status()
        return response.json()

    def get_vehicle(self, policy_no):
        response = self._http.get(f"{PAS_URL}/policies/{policy_no}/vehicle", timeout=5)
        response.raise_for_status()
        return response.json()
PY
cat > src/renewals/pricing.py <<'PY'
"""Renewal pricing.

The underwriting team changes these rules every quarter. They decide whether
our renewal offers win or lose against the comparison sites.
"""
import time
from datetime import date

from renewals.legacy_pas import PolicyAdapter
from shared.models import Customer

_pas = PolicyAdapter()
_cache = {}


def quote_renewal(customer: Customer, today: date) -> float:
    policy = None
    for attempt in range(3):
        try:
            hit = _cache.get(customer.policy_no)
            if hit and time.time() - hit[0] < 300:
                policy = hit[1]
            else:
                policy = _pas.get_policy(customer.policy_no)
                _cache[customer.policy_no] = (time.time(), policy)
            break
        except Exception:
            time.sleep(0.5 * (attempt + 1))
    if policy is None:
        raise RuntimeError("policy administration system unavailable")

    if policy["POL_STS_CD"] != "A":
        raise ValueError(f"cannot renew a policy in status {policy['POL_STS_CD']}")

    premium = float(policy["PREM_AMT"])
    # 5+ years with us and no claims in the last 3 years get 10% off,
    # unless the driver is under 25 or the car is more than 15 years old
    if (customer.years_with_us >= 5 and customer.claim_free_years >= 3
            and today.year - customer.date_of_birth.year >= 25
            and int(policy["VEH_YR"]) > today.year - 15):
        premium = premium * 0.9
    if customer.open_claim_total > 2500:
        premium = premium * 1.15
    customer.last_quote = round(premium, 2)
    return customer.last_quote


def renewal_offer_text(policyholder: Customer, quote: float) -> str:
    return (
        f"Dear {policyholder.name}, your renewal offer for {policyholder.policy_no} "
        f"is {quote:.2f}. Thank you for {policyholder.years_with_us} years with us."
    )


def proposal_has_expired(client: Customer, today: date) -> bool:
    return client.renewal_due_on is not None and today > client.renewal_due_on
PY
cat > src/claims/first_notice.py <<'PY'
"""First notice of loss: an insured reports an incident."""
from datetime import date
from uuid import uuid4

from renewals.legacy_pas import PolicyAdapter
from shared.models import Customer

_pas = PolicyAdapter()


def register_claim(insured: Customer, incident_on: date, estimate: float, description: str) -> str:
    policy = _pas.get_policy(insured.policy_no)
    status = policy["POL_STS_CD"]
    if status == "X":
        raise ValueError("the policy was cancelled")
    if status == "L":
        lapsed_on = date.fromisoformat(policy["LAPSE_DT"])
        if (incident_on - lapsed_on).days > 30:
            raise ValueError("cover ended more than 30 days before the incident")
    if insured.fraud_flag:
        raise ValueError("refer this customer to the fraud team")

    claim_id = f"CLM-{uuid4().hex[:8]}"
    insured.open_claim_ids.append(claim_id)
    insured.open_claim_total += estimate
    insured.claim_free_years = 0
    return claim_id
PY
