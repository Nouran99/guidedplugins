#!/usr/bin/env bash
set -e
mkdir -p src/shop/models src/shop/services src/shop/utils

cat > src/shop/models/order.py <<'PY'
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class Order:
    id: str
    customer_id: str
    lines: list = field(default_factory=list)
    status: str = "new"
    coupon: Optional[str] = None
    placed_at: Optional[datetime] = None
    shipped_at: Optional[datetime] = None

    def subtotal_cents(self) -> int:
        return sum(qty * unit_cents for _sku, qty, unit_cents in self.lines)

    def total_cents(self) -> int:
        from shop.services.order_service import loyalty_discount

        return self.subtotal_cents() - loyalty_discount(self)
PY

cat > src/shop/services/order_service.py <<'PY'
import csv
import io
import uuid
from datetime import datetime

from shop.models.order import Order
from shop.utils.common import cents_to_str, format_address


def loyalty_discount(order):
    subtotal = order.subtotal_cents()
    if subtotal > 50_000:
        return subtotal // 10
    return 0


class OrderService:
    def __init__(self, db, payments, notifier, label_printer, export_dir):
        self.db = db
        self.payments = payments
        self.notifier = notifier
        self.label_printer = label_printer
        self.export_dir = export_dir

    def place_order(self, customer_id, lines, coupon=None):
        order = Order(id=str(uuid.uuid4()), customer_id=customer_id, lines=lines, coupon=coupon)
        for sku, qty, _ in lines:
            stock = self.db.query_one("select on_hand from stock where sku = %s", (sku,))
            if stock is None or stock["on_hand"] < qty:
                raise ValueError(f"not enough stock for {sku}")
        total = order.total_cents()
        if coupon == "WELCOME10":
            total = total - total // 10
        self.payments.charge(customer_id, total)
        order.status = "paid"
        order.placed_at = datetime.utcnow()
        self.db.save_order(order)
        self.notifier.send_email(
            self.db.customer_email(customer_id), "Order received", f"Total {cents_to_str(total)}"
        )
        return order

    def cancel_order(self, order_id):
        order = self.db.load_order(order_id)
        if order.status == "shipped":
            raise ValueError("shipped orders cannot be cancelled")
        self.payments.refund(order.customer_id, order.total_cents())
        order.status = "cancelled"
        self.db.save_order(order)
        self.notifier.send_email(
            self.db.customer_email(order.customer_id), "Order cancelled", order.id
        )

    def refund_order(self, order_id, reason):
        order = self.db.load_order(order_id)
        if order.status == "shipped":
            raise ValueError("shipped orders are refunded through returns")
        self.payments.refund(order.customer_id, order.total_cents())
        order.status = "refunded"
        self.db.save_order(order)
        self.db.log_refund(order_id, reason)

    def export_monthly_csv(self, year, month):
        rows = self.db.query_all(
            "select id, customer_id, total_cents from orders "
            f"where extract(year from placed_at) = {year} and extract(month from placed_at) = {month}"
        )
        out = io.StringIO()
        writer = csv.writer(out)
        writer.writerow(["id", "customer", "total"])
        for row in rows:
            writer.writerow([row["id"], row["customer_id"], cents_to_str(row["total_cents"])])
        path = f"{self.export_dir}/orders-{year}-{month:02d}.csv"
        with open(path, "w") as handle:
            handle.write(out.getvalue())
        return path

    def print_shipping_label(self, order_id):
        order = self.db.load_order(order_id)
        address = self.db.shipping_address(order.customer_id)
        self.label_printer.print(
            format_address(address, upper=True, for_label=True, include_name=True)
        )
        order.status = "shipped"
        order.shipped_at = datetime.utcnow()
        self.db.save_order(order)

    def send_invoice(self, order_id):
        order = self.db.load_order(order_id)
        address = self.db.billing_address(order.customer_id)
        body = format_address(address, include_name=True, vat_id=address.get("vat_id"))
        self.notifier.send_email(
            address["email"],
            f"Invoice {order.id}",
            body + "\n" + cents_to_str(order.total_cents()),
        )
PY

cat > src/shop/services/notifier.py <<'PY'
import smtplib
from abc import ABC, abstractmethod
from email.message import EmailMessage


class Notifier(ABC):
    @abstractmethod
    def send_email(self, to, subject, body): ...

    @abstractmethod
    def send_sms(self, number, text): ...

    @abstractmethod
    def send_push(self, device_id, title, body): ...

    @abstractmethod
    def post_to_slack(self, channel, text): ...


class EmailNotifier(Notifier):
    def __init__(self, host, sender="shop@example.com"):
        self.host = host
        self.sender = sender

    def send_email(self, to, subject, body):
        message = EmailMessage()
        message["From"] = self.sender
        message["To"] = to
        message["Subject"] = subject
        message.set_content(body)
        with smtplib.SMTP(self.host) as smtp:
            smtp.send_message(message)

    def send_sms(self, number, text):
        raise NotImplementedError("the email notifier cannot send text messages")

    def send_push(self, device_id, title, body):
        raise NotImplementedError("the email notifier cannot send push notifications")

    def post_to_slack(self, channel, text):
        raise NotImplementedError("the email notifier cannot post to slack")
PY

cat > src/shop/utils/common.py <<'PY'
def cents_to_str(cents):
    return f"{cents // 100}.{cents % 100:02d}"


def format_address(
    addr,
    upper=False,
    for_label=False,
    include_name=True,
    vat_id=None,
    country_code=False,
):
    lines = []
    if include_name:
        lines.append(addr["name"])
    lines.append(addr["street"])
    city_line = f'{addr["postcode"]} {addr["city"]}'
    if for_label:
        city_line = city_line.replace(" ", "  ")  # wide spacing helps the label scanner
    lines.append(city_line)
    if country_code:
        lines.append(addr["country"])
    if vat_id:
        lines.append(f"VAT {vat_id}")
    text = "\n".join(lines)
    return text.upper() if upper else text
PY
