#!/usr/bin/env bash
set -e
mkdir -p src/desk

cat > src/desk/repository.py <<'PY'
from datetime import date


class Agent:
    def __init__(self, id, name):
        self.id = id
        self.name = name


class Ticket:
    def __init__(self, id, title, status, assignee_id, closed_on, load_agent):
        self.id = id
        self.title = title
        self.status = status
        self.assignee_id = assignee_id
        self.closed_on = closed_on
        self._load_agent = load_agent
        self._assignee = None

    @property
    def assignee(self):
        if self._assignee is None and self.assignee_id is not None:
            self._assignee = self._load_agent(self.assignee_id)
        return self._assignee


class TicketRepository:
    COLUMNS = "id, title, status, assignee_id, closed_on"

    def __init__(self, conn):
        self.conn = conn

    def get(self, ticket_id):
        row = self.conn.execute(
            f"select {self.COLUMNS} from tickets where id = ?", (ticket_id,)
        ).fetchone()
        return self._ticket(row) if row else None

    def open_tickets(self):
        rows = self.conn.execute(
            f"select {self.COLUMNS} from tickets where status != 'closed' order by id"
        ).fetchall()
        return [self._ticket(row) for row in rows]

    def save(self, ticket):
        closed_on = ticket.closed_on.isoformat() if ticket.closed_on else None
        self.conn.execute(
            "update tickets set title = ?, status = ?, assignee_id = ?, closed_on = ? where id = ?",
            (ticket.title, ticket.status, ticket.assignee_id, closed_on, ticket.id),
        )
        self.conn.commit()

    def _agent(self, agent_id):
        row = self.conn.execute(
            "select id, name from agents where id = ?", (agent_id,)
        ).fetchone()
        return Agent(row[0], row[1])

    def _ticket(self, row):
        closed_on = date.fromisoformat(row[4]) if row[4] else None
        return Ticket(row[0], row[1], row[2], row[3], closed_on, self._agent)
PY

cat > src/desk/service.py <<'PY'
from datetime import date

import requests

CHAT_HOOK = "https://chat.internal.example/hooks/support-desk"


class AuditLog:
    def __init__(self, conn):
        self.conn = conn

    def record(self, ticket_id, actor, action):
        self.conn.execute(
            "insert into ticket_audit (ticket_id, actor, action) values (?, ?, ?)",
            (ticket_id, actor, action),
        )
        self.conn.commit()


class TicketService:
    def __init__(self, tickets, audit):
        self.tickets = tickets
        self.audit = audit

    def reassign(self, ticket_id, agent_id, actor):
        ticket = self.tickets.get(ticket_id)
        if ticket is None:
            raise LookupError(f"no ticket {ticket_id}")
        ticket.assignee_id = agent_id
        if ticket.status == "open":
            ticket.status = "assigned"
        self.tickets.save(ticket)
        requests.post(
            CHAT_HOOK,
            json={"text": f"Ticket {ticket.id} now belongs to agent {agent_id} ({actor})"},
            timeout=5,
        )
        self.audit.record(ticket.id, actor, f"reassigned to agent {agent_id}")
        return ticket

    def close(self, ticket_id, actor):
        ticket = self.tickets.get(ticket_id)
        if ticket is None:
            raise LookupError(f"no ticket {ticket_id}")
        ticket.status = "closed"
        ticket.closed_on = date.today()
        self.tickets.save(ticket)
        self.audit.record(ticket.id, actor, "closed")
        return ticket
PY

cat > src/desk/handlers.py <<'PY'
from datetime import date

from flask import Blueprint, current_app, jsonify, request

from desk.repository import TicketRepository
from desk.service import AuditLog, TicketService

bp = Blueprint("desk", __name__)


def repo():
    return TicketRepository(current_app.config["DB"])


def service():
    conn = current_app.config["DB"]
    return TicketService(TicketRepository(conn), AuditLog(conn))


@bp.get("/tickets/open")
def list_open():
    rows = []
    for ticket in repo().open_tickets():
        rows.append(
            {
                "id": ticket.id,
                "title": ticket.title,
                "assignee": ticket.assignee.name if ticket.assignee else None,
            }
        )
    return jsonify(rows)


@bp.get("/tickets/<int:ticket_id>")
def show(ticket_id):
    ticket = repo().get(ticket_id)
    if ticket is None:
        return jsonify(error="unknown ticket"), 404
    return jsonify(
        id=ticket.id,
        title=ticket.title,
        status=ticket.status,
        assignee_id=ticket.assignee_id,
    )


@bp.put("/tickets/<int:ticket_id>")
def update(ticket_id):
    tickets = repo()
    ticket = tickets.get(ticket_id)
    if ticket is None:
        return jsonify(error="unknown ticket"), 404
    form = request.get_json()
    ticket.title = form["title"]
    ticket.status = form["status"]
    ticket.assignee_id = form["assignee_id"]
    tickets.save(ticket)
    return jsonify(id=ticket.id, title=ticket.title, status=ticket.status)


@bp.post("/tickets/<int:ticket_id>/reassign")
def reassign(ticket_id):
    try:
        ticket = service().reassign(
            ticket_id, request.get_json()["agent_id"], request.headers["X-Agent"]
        )
    except LookupError:
        return jsonify(error="unknown ticket"), 404
    return jsonify(id=ticket.id, assignee_id=ticket.assignee_id)


@bp.post("/tickets/<int:ticket_id>/close")
def close(ticket_id):
    try:
        ticket = service().close(ticket_id, request.headers["X-Agent"])
    except LookupError:
        return jsonify(error="unknown ticket"), 404
    return jsonify(id=ticket.id, status=ticket.status)


@bp.post("/tickets/<int:ticket_id>/reopen")
def reopen(ticket_id):
    tickets = repo()
    ticket = tickets.get(ticket_id)
    if ticket is None:
        return jsonify(error="unknown ticket"), 404
    if ticket.status != "closed":
        return jsonify(error="only a closed ticket can be reopened"), 409
    if (date.today() - ticket.closed_on).days > 14:
        return jsonify(error="closed for more than 14 days; open a new ticket"), 409
    ticket.status = "open"
    ticket.closed_on = None
    tickets.save(ticket)
    return jsonify(id=ticket.id, status=ticket.status)
PY

cat > src/desk/test_handlers.py <<'PY'
import sqlite3
from datetime import date, timedelta

import pytest
from flask import Flask

from desk.handlers import bp

SCHEMA = """
create table agents (id integer primary key, name text);
create table tickets (
    id integer primary key, title text, status text, assignee_id integer, closed_on text
);
create table ticket_audit (id integer primary key, ticket_id integer, actor text, action text);
"""


@pytest.fixture
def db():
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.executescript(SCHEMA)
    conn.execute("insert into agents values (1, 'Mara'), (2, 'Joss')")
    conn.commit()
    return conn


@pytest.fixture
def client(db):
    app = Flask(__name__)
    app.config["DB"] = db
    app.register_blueprint(bp)
    return app.test_client()


def add_ticket(db, ticket_id, status, closed_days_ago=None, assignee_id=None):
    closed_on = None
    if closed_days_ago is not None:
        closed_on = (date.today() - timedelta(days=closed_days_ago)).isoformat()
    db.execute(
        "insert into tickets values (?, ?, ?, ?, ?)",
        (ticket_id, f"Ticket {ticket_id}", status, assignee_id, closed_on),
    )
    db.commit()


def test_reopen_within_two_weeks(client, db):
    add_ticket(db, 1, "closed", closed_days_ago=3)
    response = client.post("/tickets/1/reopen")
    assert response.status_code == 200
    assert response.get_json()["status"] == "open"


def test_reopen_after_two_weeks_is_refused(client, db):
    add_ticket(db, 2, "closed", closed_days_ago=15)
    assert client.post("/tickets/2/reopen").status_code == 409


def test_open_tickets_show_the_assignee_name(client, db):
    add_ticket(db, 3, "assigned", assignee_id=2)
    assert client.get("/tickets/open").get_json()[0]["assignee"] == "Joss"
PY
