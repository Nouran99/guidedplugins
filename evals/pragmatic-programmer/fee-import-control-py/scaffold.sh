#!/usr/bin/env bash
set -e
mkdir -p src/fees
cat > src/fees/__init__.py <<'PY'
"""Late fees for overdue invoices."""
PY
cat > src/fees/policy.py <<'PY'
"""The late-fee rule. This module owns it; callers ask `late_fee` instead of copying the numbers."""

# Contract terms: no fee until a full two weeks past the due date.
GRACE_DAYS = 14

# Contract terms: 1.5% of the balance, held in basis points so the arithmetic stays in integers.
RATE_BASIS_POINTS = 150

# One whole (100%) in basis points. Adding half of it before the division rounds a fee half up to the cent.
BASIS_POINTS_PER_WHOLE = 10_000

# Contract terms: a single fee never exceeds 250.00.
MAX_FEE_CENTS = 25_000

# The billing API rejects balances above 10,000,000 cents (100,000.00), so a larger value cannot be real.
MAX_BALANCE_CENTS = 10_000_000


def late_fee(balance_cents: int, days_overdue: int) -> int:
    """Return the fee in cents for an invoice that is `days_overdue` days past its due date.

    Precondition: 0 <= balance_cents <= MAX_BALANCE_CENTS. Anything else raises ValueError,
    so it can never turn into a silent fee of zero; a caller that reads balances from outside
    the program rejects the record at its own boundary.
    Postcondition: 0 <= result <= MAX_FEE_CENTS, rounded half up to the cent.
    """
    if not 0 <= balance_cents <= MAX_BALANCE_CENTS:
        raise ValueError(f"balance_cents must be between 0 and {MAX_BALANCE_CENTS}, got {balance_cents}")
    if days_overdue <= GRACE_DAYS:
        return 0
    fee = (balance_cents * RATE_BASIS_POINTS + BASIS_POINTS_PER_WHOLE // 2) // BASIS_POINTS_PER_WHOLE
    return min(fee, MAX_FEE_CENTS)
PY
cat > src/fees/importer.py <<'PY'
"""Applies late fees from the nightly CSV of open invoices."""

import csv
from dataclasses import dataclass, field
from datetime import date
from typing import Protocol

from .policy import late_fee

REQUIRED_COLUMNS = ("invoice_id", "due_date", "balance_cents")


class RowRejected(Exception):
    """One CSV row cannot be used. The rest of the file is still processed."""


class Ledger(Protocol):
    def add_fee(self, invoice_id: str, cents: int) -> None: ...


@dataclass
class ImportResult:
    applied: int = 0
    rejected: list[str] = field(default_factory=list)


def parse_row(line_no: int, row: dict[str, str | None], today: date) -> tuple[str, int, int]:
    """Return (invoice_id, balance_cents, days_overdue), or raise RowRejected naming the line."""
    values = {name: (row.get(name) or "").strip() for name in REQUIRED_COLUMNS}
    missing = [name for name, value in values.items() if not value]
    if missing:
        raise RowRejected(f"line {line_no}: missing {', '.join(missing)}")
    try:
        due = date.fromisoformat(values["due_date"])
        balance = int(values["balance_cents"])
    except ValueError as exc:
        raise RowRejected(f"line {line_no}: unreadable value ({exc})") from exc
    return values["invoice_id"], balance, (today - due).days


def apply_fees(path: str, ledger: Ledger, today: date) -> ImportResult:
    """Apply a fee for every overdue row of the CSV at `path`.

    A malformed row is listed in `rejected` and skipped. A failure of the ledger itself
    propagates, because nothing after it can be trusted.
    """
    result = ImportResult()
    with open(path, newline="", encoding="utf-8") as handle:
        for line_no, row in enumerate(csv.DictReader(handle), start=2):  # line 1 is the header
            try:
                invoice_id, balance, days_overdue = parse_row(line_no, row, today)
            except RowRejected as exc:
                result.rejected.append(str(exc))
                continue
            try:
                fee = late_fee(balance, days_overdue)
            except ValueError as exc:
                result.rejected.append(f"line {line_no}: {exc}")
                continue
            if fee:
                ledger.add_fee(invoice_id, fee)
                result.applied += 1
    return result
PY
cat > src/fees/test_fees.py <<'PY'
from datetime import date

import pytest

from .importer import apply_fees
from .policy import GRACE_DAYS, MAX_BALANCE_CENTS, MAX_FEE_CENTS, late_fee

TODAY = date(2026, 3, 20)


class FakeLedger:
    def __init__(self, fail_on=None):
        self.fees = []
        self.fail_on = fail_on

    def add_fee(self, invoice_id, cents):
        if invoice_id == self.fail_on:
            raise ConnectionError("ledger unavailable")
        self.fees.append((invoice_id, cents))


def write_csv(tmp_path, *lines):
    path = tmp_path / "overdue.csv"
    path.write_text("invoice_id,due_date,balance_cents\n" + "\n".join(lines) + "\n", encoding="utf-8")
    return str(path)


def test_no_fee_inside_the_grace_period():
    assert late_fee(100_000, days_overdue=GRACE_DAYS) == 0


def test_fee_starts_the_day_after_the_grace_period():
    assert late_fee(100_000, days_overdue=GRACE_DAYS + 1) == 1_500


def test_fee_rounds_half_up_to_the_cent():
    assert late_fee(1_100, days_overdue=30) == 17


def test_a_zero_balance_owes_no_fee():
    assert late_fee(0, days_overdue=30) == 0


def test_fee_is_capped_at_the_contract_maximum():
    assert late_fee(MAX_BALANCE_CENTS, days_overdue=30) == MAX_FEE_CENTS


@pytest.mark.parametrize("balance", [-1, MAX_BALANCE_CENTS + 1])
def test_balance_outside_the_contract_is_refused(balance):
    with pytest.raises(ValueError, match="balance_cents"):
        late_fee(balance, days_overdue=30)


def test_applies_a_fee_to_each_overdue_row_only(tmp_path):
    path = write_csv(tmp_path, "A-1,2026-02-01,100000", "A-2,2026-03-15,100000", "A-3,2026-04-01,100000")
    ledger = FakeLedger()

    result = apply_fees(path, ledger, TODAY)

    assert ledger.fees == [("A-1", 1_500)]
    assert result.applied == 1
    assert result.rejected == []


def test_a_malformed_row_is_reported_with_its_line_and_the_rest_still_apply(tmp_path):
    path = write_csv(tmp_path, "A-1,not-a-date,100000", "A-2,2026-02-01,100000")
    ledger = FakeLedger()

    result = apply_fees(path, ledger, TODAY)

    assert ledger.fees == [("A-2", 1_500)]
    assert len(result.rejected) == 1
    assert result.rejected[0].startswith("line 2:")


def test_a_row_with_a_missing_balance_is_rejected_not_charged(tmp_path):
    path = write_csv(tmp_path, "A-1,2026-02-01,")

    result = apply_fees(path, FakeLedger(), TODAY)

    assert result.applied == 0
    assert "missing balance_cents" in result.rejected[0]


def test_a_balance_outside_the_contract_rejects_only_that_row(tmp_path):
    path = write_csv(tmp_path, "A-1,2026-02-01,-5", "A-2,2026-02-01,100000")
    ledger = FakeLedger()

    result = apply_fees(path, ledger, TODAY)

    assert ledger.fees == [("A-2", 1_500)]
    assert len(result.rejected) == 1


def test_a_ledger_failure_stops_the_import(tmp_path):
    path = write_csv(tmp_path, "A-1,2026-02-01,100000", "A-2,2026-02-01,100000")
    ledger = FakeLedger(fail_on="A-1")

    with pytest.raises(ConnectionError):
        apply_fees(path, ledger, TODAY)

    assert ledger.fees == []


def test_invoice_ids_are_trimmed_before_the_ledger_sees_them(tmp_path):
    # Finance reported a fee booked under " A-1 " that matched no invoice.
    path = write_csv(tmp_path, " A-1 ,2026-02-01,100000")
    ledger = FakeLedger()

    apply_fees(path, ledger, TODAY)

    assert ledger.fees == [("A-1", 1_500)]
PY
