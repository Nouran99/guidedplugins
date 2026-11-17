#!/usr/bin/env bash
set -e
mkdir -p src/shared src/billing src/support src/notifications
cat > src/NOTES.md <<'MD'
# Modules

- billing: quotes, renewals and invoices. Pricing is where we win or lose deals, and sales changes the discount rules every quarter.
- support: tickets and response targets.
- notifications: email and SMS templates, edited by two people in support and marketing.
- shared: types used by more than one module.
MD
cat > src/shared/models.py <<'PY'
from dataclasses import dataclass, field
from datetime import date
from typing import List, Optional


@dataclass
class Customer:
    id: str
    name: str
    email: str
    tier: str = "standard"
    tax_id: Optional[str] = None
    payment_terms_days: int = 30
    credit_limit: float = 0.0
    balance: float = 0.0
    last_payment_on: Optional[date] = None
    archived: bool = False
    support_plan: str = "basic"
    assigned_agent: Optional[str] = None
    newsletter_opt_in: bool = False
    marketing_segment: Optional[str] = None
    tags: List[str] = field(default_factory=list)

    def display_name(self) -> str:
        return f"{self.name} <{self.email}>"
PY
cat > src/billing/quotes.py <<'PY'
from datetime import date

from shared.models import Customer
from support import tickets

TIER_DISCOUNTS = {"standard": 0, "silver": 5, "gold": 12}


def is_active(customer: Customer, today: date) -> bool:
    if customer.last_payment_on is None:
        return False
    return (today - customer.last_payment_on).days <= 90


def price_quote(customer: Customer, items: list, today: date) -> dict:
    if not is_active(customer, today):
        raise ValueError("customer is not active")
    if tickets.open_count(customer.id) > 5:
        raise ValueError("resolve open tickets before quoting")

    subtotal = 0.0
    for item in items:
        line = item["qty"] * item["unit_price"]
        if item["qty"] >= 100:
            line = line * 0.9
        elif item["qty"] >= 20:
            line = line * 0.95
        subtotal += line

    pct = TIER_DISCOUNTS.get(customer.tier, 0)
    if customer.tier == "gold" and subtotal > 5000:
        pct += 3
    if pct > 15:
        pct = 15
    total = round(subtotal * (100 - pct) / 100, 2)
    return {"customer": customer.id, "subtotal": subtotal, "discount_pct": pct, "total": total}


def price_renewal(customer: Customer, items: list) -> dict:
    subtotal = sum(i["qty"] * i["unit_price"] for i in items)
    pct = TIER_DISCOUNTS.get(customer.tier, 0)
    if customer.tier == "gold" and subtotal > 5000:
        pct += 3
    if customer.tier != "standard":
        pct += 2
    pct = min(pct, 15)
    return {"customer": customer.id, "subtotal": subtotal, "discount_pct": pct, "total": round(subtotal * (100 - pct) / 100, 2)}
PY
cat > src/support/tickets.py <<'PY'
from datetime import datetime, timedelta

from shared.models import Customer

SLA_HOURS = {"basic": 48, "plus": 24, "premium": 4}

_tickets = {}


def is_active(customer: Customer) -> bool:
    return not customer.archived


def open_ticket(customer: Customer, subject: str, now: datetime) -> dict:
    if not is_active(customer):
        raise ValueError("customer account is closed")
    hours = SLA_HOURS.get(customer.support_plan, 48)
    ticket = {
        "id": f"T-{len(_tickets.get(customer.id, [])) + 1}",
        "customer_id": customer.id,
        "subject": subject,
        "opened_at": now,
        "respond_by": now + timedelta(hours=hours),
        "status": "open",
    }
    _tickets.setdefault(customer.id, []).append(ticket)
    return ticket


def open_count(customer_id: str) -> int:
    return len([t for t in _tickets.get(customer_id, []) if t["status"] == "open"])
PY
cat > src/notifications/templates.py <<'PY'
from dataclasses import dataclass
from datetime import datetime
from typing import List, Protocol


@dataclass(frozen=True)
class TemplateId:
    value: str

    def __post_init__(self):
        if not self.value:
            raise ValueError("template id must not be empty")


@dataclass(frozen=True)
class TemplateBody:
    text: str


@dataclass(frozen=True)
class TemplateRenamed:
    template_id: TemplateId
    old_name: str
    new_name: str
    occurred_at: datetime


@dataclass(frozen=True)
class TemplateBodyChanged:
    template_id: TemplateId
    old_body: TemplateBody
    new_body: TemplateBody
    occurred_at: datetime


class TemplateAggregate:
    def __init__(self, template_id: TemplateId, name: str, body: TemplateBody):
        self._id = template_id
        self._name = name
        self._body = body
        self._events: List[object] = []

    @property
    def id(self) -> TemplateId:
        return self._id

    def rename(self, new_name: str) -> None:
        old_name = self._name
        self._name = new_name
        self._events.append(TemplateRenamed(self._id, old_name, new_name, datetime.utcnow()))

    def change_body(self, body: TemplateBody) -> None:
        old_body = self._body
        self._body = body
        self._events.append(TemplateBodyChanged(self._id, old_body, body, datetime.utcnow()))

    def pull_events(self) -> List[object]:
        events, self._events = self._events, []
        return events


class TemplateRepository(Protocol):
    def get(self, template_id: TemplateId) -> TemplateAggregate: ...

    def add(self, template: TemplateAggregate) -> None: ...


class TemplateEventPublisher(Protocol):
    def publish(self, event: object) -> None: ...


class TemplateService:
    def __init__(self, repository: TemplateRepository, publisher: TemplateEventPublisher):
        self._repository = repository
        self._publisher = publisher

    def rename(self, template_id: str, new_name: str) -> None:
        template = self._repository.get(TemplateId(template_id))
        template.rename(new_name)
        self._repository.add(template)
        for event in template.pull_events():
            self._publisher.publish(event)

    def change_body(self, template_id: str, text: str) -> None:
        template = self._repository.get(TemplateId(template_id))
        template.change_body(TemplateBody(text))
        self._repository.add(template)
        for event in template.pull_events():
            self._publisher.publish(event)
PY
