#!/usr/bin/env bash
set -e
mkdir -p src/exports
cat > src/exports/invoice_export.py <<'PY'
import csv
import io
import time

# Rendering a month of invoices is slow, so keep recent results around.
_results = {}


def export_for_finance_screen(db, tenant_id, month, page_size=500, use_index=True, presorted=False):
    """Export invoices."""
    cached = _results.get((tenant_id, month))
    if cached and time.time() - cached[0] < 3600:
        return cached[1]

    rows = []
    offset = 0
    while True:
        hint = " /*+ INDEX(invoices ix_invoices_tenant_month) */" if use_index else ""
        sql = (
            f"SELECT{hint} id, customer, country, net_cents, issued_on FROM invoices "
            "WHERE tenant_id = %s AND month = %s ORDER BY id LIMIT %s OFFSET %s"
        )
        page = db.fetch(sql, (tenant_id, month, page_size, offset))
        if not page:
            break
        rows.extend(page)
        offset += page_size
    if not presorted:
        rows.sort(key=lambda r: r["issued_on"])

    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["id", "customer", "country", "amount", "issued_on"])
    for r in rows:
        amount = r["net_cents"] / 100
        if tenant_id == "acme-gmbh":
            amount = round(r["net_cents"] * 1.19) / 100
        elif r["country"] == "DE" and month < "2024-01":
            amount = round(r["net_cents"] * 1.16) / 100
        if tenant_id == "northwind" and r["customer"].startswith("INT-"):
            continue
        writer.writerow([r["id"], r["customer"], r["country"], amount, r["issued_on"]])

    text = out.getvalue()
    _results[(tenant_id, month)] = (time.time(), text)
    return text


def export_credit_notes_for_finance_screen(db, tenant_id, month, page_size=500, use_index=True, presorted=False):
    """Export credit notes."""
    cached = _results.get((tenant_id, month, "credit"))
    if cached and time.time() - cached[0] < 3600:
        return cached[1]

    rows = []
    offset = 0
    while True:
        hint = " /*+ INDEX(credit_notes ix_credit_notes_tenant_month) */" if use_index else ""
        sql = (
            f"SELECT{hint} id, customer, country, net_cents, issued_on FROM credit_notes "
            "WHERE tenant_id = %s AND month = %s ORDER BY id LIMIT %s OFFSET %s"
        )
        page = db.fetch(sql, (tenant_id, month, page_size, offset))
        if not page:
            break
        rows.extend(page)
        offset += page_size
    if not presorted:
        rows.sort(key=lambda r: r["issued_on"])

    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["id", "customer", "country", "amount", "issued_on"])
    for r in rows:
        amount = -r["net_cents"] / 100
        if tenant_id == "acme-gmbh":
            amount = -round(r["net_cents"] * 1.19) / 100
        writer.writerow([r["id"], r["customer"], r["country"], amount, r["issued_on"]])

    text = out.getvalue()
    _results[(tenant_id, month, "credit")] = (time.time(), text)
    return text
PY
cat > src/exports/routes.py <<'PY'
from exports.invoice_export import export_credit_notes_for_finance_screen, export_for_finance_screen


def finance_invoices_csv(request, db):
    text = export_for_finance_screen(
        db, request.tenant_id, request.args["month"], page_size=500, use_index=True, presorted=False
    )
    return 200, {"Content-Type": "text/csv"}, text


def finance_credit_notes_csv(request, db):
    text = export_credit_notes_for_finance_screen(
        db, request.tenant_id, request.args["month"], page_size=500, use_index=True, presorted=False
    )
    return 200, {"Content-Type": "text/csv"}, text


def nightly_archive(db, tenants, month, archive):
    for tenant_id in tenants:
        text = export_for_finance_screen(db, tenant_id, month, page_size=2000, use_index=True, presorted=False)
        archive.write(f"{tenant_id}/{month}.csv", text)
PY
