---
name: ports-and-gateways
description: "Use when core code builds or calls a database, mailer, payment provider, clock or ID generator directly, or when choosing which layer owns and names an interface. Construction sites are composition-root, storage leaks are persistence-independence, whether a port pays off is boundary-economics."
---

# Ports and gateways

Owns the interfaces through which core policy reaches volatile details: who declares them, what they contain and what they are called. Where the implementation is constructed is `/clean-architecture:composition-root`; whether a given port is worth its cost is `/clean-architecture:boundary-economics`; what must not leak through a persistence port is `/clean-architecture:persistence-independence`.

## When to use

- A use case or entity imports an SDK, driver or client, or constructs one.
- A use case calls `now()`, generates an identifier, sends mail or writes a file itself.
- You are about to write an interface and must choose its layer and its name.
- A port's methods mirror a vendor API instead of what the caller needs.

## Rules

1. **Introduce interfaces for volatile dependencies.** `[MUST]` The source lists gateways, mailers, payment providers, message publishers, storage providers, clocks, ID generators and, if needed, transaction runners. Check: each external effect a use case causes appears as a port among its constructor parameters.
2. **Do not call volatile details directly from core use cases.** `[MUST NOT]` Check: the application directory contains no call that reaches the network, disk, clock or a vendor client except through a port.
3. **Let inner layers own the abstractions they need, and let outer layers implement them.** `[MUST]` Check: a port's declaration sits in the application or domain layer; its implementation sits in adapters or infrastructure.
4. **Put external systems, persistence, messaging, file systems, clocks and service clients behind boundaries, and define interfaces at the architectural seams.** `[MUST]` Check: a search for the vendor's package name finds it only in the adapter.
5. **Prefer adapters over direct calls from policy code to implementation details.** `[SHOULD]` Check: the policy code calls a method on a port, never on a client class.
6. **Name a port by the role it plays for the use case, and an adapter by the external detail it adapts.** `[MUST]` Check: `OverdueNoticeDelivery` is the port and `SmtpOverdueNoticeDelivery` the adapter; no vendor word appears in the port's name.
7. **Do not declare a port in infrastructure for the core to consume.** `[MUST NOT]` unless explicitly required and justified. Check: no application import points at an infrastructure file to get an interface.
8. **Keep a gateway to its job.** `[MUST NOT]` Infrastructure must not define business rules, dictate domain shapes or leak vendor types inward. Check: a gateway method signature uses only domain types and plain data.
9. **Avoid shared "common" packages that create sideways coupling.** `[MUST NOT]` Put the port with the use case that needs it. Check: the interface is not in a module imported by unrelated use cases. Added judgment: when two use cases truly need the same capability, share it from an inner-layer module; otherwise let each declare the small port it needs.
10. **Shape the port after what the use case does today, not after the vendor's API.** Added judgment, reading "inner layers own the abstractions they need": list the calls the use case makes, and write only those methods in the caller's words. Check: every method has a caller; no method name is a vendor term.

## Procedure

1. Find the direct uses: search the changed core files for client constructors, SDK imports, `now()` calls, ID generation and file operations.
2. For each, write the operation in the use case's words (`deliver`, `find`, `save`, `today`) and the plain types it needs.
3. Declare the interface in the application or domain layer next to its client, named by role.
4. Write the adapter in the outer layer, implementing the interface and translating vendor types and errors at the edge.
5. Replace the direct use with a constructor parameter, and construct the adapter in the composition root (`/clean-architecture:composition-root`).
6. Add a fake of the port for unit tests (`/clean-architecture:testing-seams`) and run the tests.

## Example

```python
# Before: the use case builds an SMTP client and asks the system clock
import smtplib
from datetime import datetime


def send_overdue_notice(loan, smtp_host):
    if loan.due_on < datetime.now().date():
        with smtplib.SMTP(smtp_host) as smtp:
            smtp.sendmail("library@example.org", loan.member_email, f"Overdue: {loan.title}")
```

```python
# After: application/send_overdue_notice.py declares what it needs, in its own words
from datetime import date
from typing import Protocol


class Clock(Protocol):
    def today(self) -> date: ...


class OverdueNoticeDelivery(Protocol):
    def deliver(self, member_email: str, title: str) -> None: ...


class SendOverdueNotice:
    def __init__(self, clock: Clock, delivery: OverdueNoticeDelivery) -> None:
        self._clock = clock
        self._delivery = delivery

    def execute(self, loan) -> bool:
        if loan.due_on >= self._clock.today():
            return False
        self._delivery.deliver(loan.member_email, loan.title)
        return True
```

```python
# infrastructure/smtp_overdue_notice_delivery.py: the only file that knows smtplib
import smtplib
from email.message import EmailMessage


class SmtpOverdueNoticeDelivery:
    def __init__(self, host: str, sender: str) -> None:
        self._host = host
        self._sender = sender

    def deliver(self, member_email: str, title: str) -> None:
        message = EmailMessage()
        message["From"] = self._sender
        message["To"] = member_email
        message["Subject"] = f"Overdue: {title}"
        message.set_content(f"The loan of {title} is overdue.")
        with smtplib.SMTP(self._host) as smtp:
            smtp.send_message(message)
```

A test passes a fixed clock and a delivery fake that records calls; no mail server and no wall clock are involved. The composition root builds `SmtpOverdueNoticeDelivery` and passes it in.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Vendor-named port | An interface called `StripeClient`, `S3Storage`, `SmtpSender` in the core | Rename by role (`PaymentGateway`, `ReportArchive`, `NoticeDelivery`) |
| Port in the wrong layer | The interface declared in infrastructure and imported inward | Move the declaration to the application layer |
| Mirror interface | A port whose methods copy the vendor's SDK | Cut it down to what callers use |
| Interface per class | An interface for every class with one implementation and no volatility | Remove; see `/clean-architecture:boundary-economics` |
| Vendor type in a signature | A port method that returns an SDK object or throws SDK errors | Translate in the adapter |
| Shared interface bucket | One `interfaces/` package used by every feature | Put each port with its client |
| Logic in the gateway | Eligibility or pricing decisions inside an adapter | Move to an entity or use case |

## Trade-offs and exceptions

- The cost test still applies: a boundary must not cost more than the option value it keeps. For a clock used by one rule, the lightest boundary is often passing `today` in as a value. Added judgment, not a rule of the source.
- Do not wrap what is stable and universal (the language's standard collections, your own value types). The list in the source names volatile dependencies.
- "When in doubt, introduce a boundary sooner" and partial boundaries are acceptable; see `/clean-architecture:boundary-economics` for how this plugin settles the tension.
- A transaction runner is a port only "if needed": add one when a use case must group several gateway calls atomically.

## Verification

- [ ] No SDK, driver or client appears in the core files you touched.
- [ ] Each port is declared in the layer of its client and named by role.
- [ ] Each adapter is named by the detail it adapts and lives in an outer layer.
- [ ] Port signatures use only domain types and plain data.
- [ ] A fake of the port lets the use case run in a unit test.
- [ ] The concrete adapter is constructed only in the composition root.

## Related

`/clean-architecture:composition-root` for wiring; `/clean-architecture:introduce-port` to apply this to one dependency; `/clean-architecture:solid-design` for the form of the interface; `clean-architecture:port-ownership-reviewer` to review a diff; `clean-architecture:port-introducer` to delegate the change.

## Source

- `Create Ports for Volatile Dependencies`
- `Prefer Stable Dependencies`
- `Keep Boundaries Visible`
- `Non-Negotiable Rules`: rules 6 and 10, boundaries around volatile systems and ownership of interfaces.
- `Naming Rules`: only the rules naming ports by role and adapters by the detail they adapt.
- `Direction Violations`: only gateway interfaces defined in infrastructure and consumed by core policy.
- `Infrastructure Layer`: only the rules that infrastructure implements interfaces owned by inner layers and does not define business rules or leak vendor types.
- `Architecture Economics and Priority`: only the rule against overbuilding boundaries.
