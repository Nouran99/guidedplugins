#!/usr/bin/env bash
set -e
mkdir -p src/booking
touch src/booking/__init__.py
cat > src/booking/events.py <<'PY'
class EventBus:
    def __init__(self):
        self._handlers = []

    def subscribe(self, handler):
        self._handlers.append(handler)

    def publish(self, event):
        for handler in self._handlers:
            handler(event)


bus = EventBus()
PY
cat > src/booking/model.py <<'PY'
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class LedgerEntry:
    at: datetime
    delta: int
    note: str


@dataclass
class Member:
    id: str
    name: str
    email: str
    credits: int = 0
    ledger: list = field(default_factory=list)

    def top_up(self, amount, at):
        self.credits += amount
        self.ledger.append(LedgerEntry(at, amount, "top-up"))


@dataclass
class Booking:
    member_id: str
    booked_at: datetime
    seat: int


@dataclass
class ClassSession:
    id: str
    title: str
    starts_at: datetime
    ends_at: datetime
    capacity: int
    bookings: list = field(default_factory=list)

    def seats_left(self):
        return self.capacity - len(self.bookings)


class SendBookingReceipt:
    def __init__(self, member_row, session_row):
        self.member_row = member_row
        self.session_row = session_row
PY
cat > src/booking/repository.py <<'PY'
import sqlite3
from datetime import datetime

from .model import Booking, ClassSession, LedgerEntry, Member

SCHEMA = """
CREATE TABLE IF NOT EXISTS members (id TEXT PRIMARY KEY, name TEXT, email TEXT, credits INTEGER);
CREATE TABLE IF NOT EXISTS ledger (member_id TEXT, at TEXT, delta INTEGER, note TEXT);
CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, title TEXT, starts_at TEXT, ends_at TEXT, capacity INTEGER);
CREATE TABLE IF NOT EXISTS bookings (session_id TEXT, member_id TEXT, booked_at TEXT, seat INTEGER);
"""


def create_schema(db):
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)


class MemberRepository:
    def __init__(self, db):
        self.db = db

    def row(self, member_id):
        return self.db.execute("SELECT * FROM members WHERE id = ?", (member_id,)).fetchone()

    def get(self, member_id):
        row = self.row(member_id)
        member = Member(row["id"], row["name"], row["email"], row["credits"])
        entries = self.db.execute(
            "SELECT at, delta, note FROM ledger WHERE member_id = ? ORDER BY at", (member_id,)
        )
        for e in entries:
            member.ledger.append(LedgerEntry(datetime.fromisoformat(e["at"]), e["delta"], e["note"]))
        return member

    def save(self, member):
        self.db.execute(
            "UPDATE members SET name = ?, email = ?, credits = ? WHERE id = ?",
            (member.name, member.email, member.credits, member.id),
        )
        self.db.execute("DELETE FROM ledger WHERE member_id = ?", (member.id,))
        for e in member.ledger:
            self.db.execute(
                "INSERT INTO ledger VALUES (?, ?, ?, ?)",
                (member.id, e.at.isoformat(), e.delta, e.note),
            )


class SessionRepository:
    def __init__(self, db):
        self.db = db

    def row(self, session_id):
        return self.db.execute("SELECT * FROM sessions WHERE id = ?", (session_id,)).fetchone()

    def get(self, session_id):
        row = self.row(session_id)
        session = ClassSession(
            row["id"],
            row["title"],
            datetime.fromisoformat(row["starts_at"]),
            datetime.fromisoformat(row["ends_at"]),
            row["capacity"],
        )
        rows = self.db.execute("SELECT * FROM bookings WHERE session_id = ? ORDER BY seat", (session_id,))
        for b in rows:
            session.bookings.append(Booking(b["member_id"], datetime.fromisoformat(b["booked_at"]), b["seat"]))
        return session

    def add(self, session):
        self.db.execute(
            "INSERT INTO sessions VALUES (?, ?, ?, ?, ?)",
            (session.id, session.title, session.starts_at.isoformat(), session.ends_at.isoformat(), session.capacity),
        )

    def save(self, session):
        self.db.execute(
            "UPDATE sessions SET title = ?, starts_at = ?, ends_at = ?, capacity = ? WHERE id = ?",
            (session.title, session.starts_at.isoformat(), session.ends_at.isoformat(), session.capacity, session.id),
        )
        self.db.execute("DELETE FROM bookings WHERE session_id = ?", (session.id,))
        for b in session.bookings:
            self.db.execute(
                "INSERT INTO bookings VALUES (?, ?, ?, ?)",
                (session.id, b.member_id, b.booked_at.isoformat(), b.seat),
            )
PY
cat > src/booking/service.py <<'PY'
from datetime import datetime

from .events import bus
from .model import Booking, ClassSession, LedgerEntry, SendBookingReceipt
from .repository import MemberRepository, SessionRepository


class BookingService:
    def __init__(self, db):
        self.db = db
        self.members = MemberRepository(db)
        self.sessions = SessionRepository(db)

    def schedule_session(self, session_id: str, title: str, starts_at: datetime, ends_at: datetime, capacity: int):
        if ends_at <= starts_at:
            raise ValueError("a class must end after it starts")
        if capacity < 1:
            raise ValueError("capacity must be at least 1")
        with self.db:
            self.sessions.add(ClassSession(session_id, title, starts_at, ends_at, capacity))

    def reschedule(self, session_id: str, starts_at: datetime, ends_at: datetime):
        if ends_at <= starts_at:
            raise ValueError("a class must end after it starts")
        with self.db:
            session = self.sessions.get(session_id)
            session.starts_at = starts_at
            session.ends_at = ends_at
            self.sessions.save(session)

    def book_seat(self, member_id: str, session_id: str, now: datetime) -> Booking:
        with self.db:
            member = self.members.get(member_id)
            session = self.sessions.get(session_id)
            if session.starts_at <= now:
                raise ValueError("the class has already started")
            if len(session.bookings) >= session.capacity:
                raise ValueError("the class is full")
            if any(b.member_id == member_id for b in session.bookings):
                raise ValueError("already booked")
            if member.credits < 1:
                raise ValueError("no credits left")
            booking = Booking(member_id, now, seat=len(session.bookings) + 1)
            session.bookings.append(booking)
            member.credits -= 1
            member.ledger.append(LedgerEntry(now, -1, "booked " + session.title))
            self.sessions.save(session)
            self.members.save(member)
        bus.publish(SendBookingReceipt(self.members.row(member_id), self.sessions.row(session_id)))
        return booking
PY
cat > src/booking/test_booking.py <<'PY'
import sqlite3
from datetime import datetime, timedelta

import pytest

from booking.repository import create_schema
from booking.service import BookingService

NOW = datetime(2024, 5, 6, 9, 0)


@pytest.fixture
def svc(tmp_path):
    db = sqlite3.connect(tmp_path / "gym.db")
    create_schema(db)
    db.execute("INSERT INTO members VALUES ('m1', 'Ana', 'ana@example.com', 2)")
    db.execute("INSERT INTO members VALUES ('m2', 'Ben', 'ben@example.com', 0)")
    db.commit()
    service = BookingService(db)
    tomorrow = NOW + timedelta(days=1)
    service.schedule_session("s1", "Spin", tomorrow, tomorrow + timedelta(hours=1), 1)
    return service


def test_book(svc):
    svc.book_seat("m1", "s1", NOW)
    count = svc.db.execute("SELECT COUNT(*) FROM bookings").fetchone()[0]
    assert count == 1


def test_book_2(svc):
    with pytest.raises(ValueError):
        svc.book_seat("m2", "s1", NOW)


def test_credits(svc):
    svc.book_seat("m1", "s1", NOW)
    assert svc.members.get("m1").credits == 1
PY
