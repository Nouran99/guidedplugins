#!/usr/bin/env bash
set -e
mkdir -p src/statements
cat > src/statements/account.py <<'PY'
from dataclasses import dataclass, field
from datetime import date
from typing import Optional


@dataclass
class Plan:
    name: str
    grace_days: int
    late_rate: float
    minimum_fee: int


@dataclass
class Entry:
    posted_on: date
    description: str
    amount: int
    due_on: Optional[date] = None
    paid: bool = False
    disputed: bool = False
    resolved: bool = False
    reminded_on: Optional[date] = None

    def is_overdue(self, today: date) -> bool:
        overdue = self.due_on is not None and not self.paid and today > self.due_on
        if overdue:
            self.reminded_on = today
        return overdue


@dataclass
class Account:
    account_id: str
    holder: str
    plan: Plan
    entries: list = field(default_factory=list)
    balance: int = 0

    def post(self, entry: Entry) -> None:
        self.entries.append(entry)
        self.balance += entry.amount

    def pay(self, description: str, amount: int, on: date) -> None:
        self.post(Entry(on, description, -amount, paid=True))
PY
cat > src/statements/statement.py <<'PY'
from datetime import date

from statements.account import Account


def format_amount(cents):
    cents = cents / 100
    cents = f"{cents:,.2f}"
    return cents


class StatementBuilder:
    def __init__(self, account: Account):
        self.account = account
        self._rows = None
        self._total = None
        self._overdue = None

    def build(self, month_start: date, today: date) -> str:
        entries = self.account.entries
        entries.sort(key=lambda e: e.posted_on)
        self._rows = [e for e in entries if e.posted_on >= month_start]
        self._total = sum(e.amount for e in self._rows)
        self._overdue = [e for e in self._rows if e.is_overdue(today)]
        parts = [self._header(), self._body(), self._footer(today)]
        return "\n".join(parts)

    def _header(self) -> str:
        return f"Statement for {self.account.holder} ({self.account.account_id})"

    def _body(self) -> str:
        lines = []
        for e in self._rows:
            flag = "!" if e in self._overdue else " "
            lines.append(f"{flag} {e.posted_on}  {e.description:<28}{format_amount(e.amount):>10}")
        return "\n".join(lines)

    def _footer(self, today: date) -> str:
        fee = self.late_fee(self.account, today)
        lines = [f"Charges this month: {format_amount(self._total)}"]
        if fee:
            lines.append(f"Late fee: {format_amount(fee)}")
        if self._has_open_dispute():
            lines.append("Some items are under dispute.")
        lines.append(f"Amount due: {format_amount(self.account.balance + fee)}")
        return "\n".join(lines)

    def late_fee(self, account: Account, today: date) -> int:
        if not self._overdue:
            return 0
        oldest = min(e.due_on for e in self._overdue)
        if (today - oldest).days <= account.plan.grace_days:
            return 0
        months = max(1, (today - oldest).days // 30)
        fee = round(account.balance * account.plan.late_rate * months)
        return max(fee, account.plan.minimum_fee)

    def _has_open_dispute(self) -> bool:
        found = False
        for e in self._rows:
            if e.disputed and not e.resolved:
                found = True
                break
        return found
PY
