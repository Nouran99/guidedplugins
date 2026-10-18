---
name: "enterprise-patterns-session-state"
description: "Use when per-user state must survive between requests: cookies or tokens carrying data, server-held sessions, a session table, expiry and cleanup, a cart or wizard lost on restart. Shared-record edit conflicts are offline-locking; UI state in domain code is presentation-layer."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Session state

Chooses where state between requests lives (client, server memory, or database) and makes its owner, lifetime, trust and cleanup explicit before features depend on it. Conflicts when several people edit the same stored record are `enterprise-patterns-offline-locking`; keeping UI state out of domain logic is `enterprise-patterns-presentation-layer`.

## When to use

- A cart, wizard, draft or filter selection must persist across requests.
- A cookie, token or hidden form field carries more than an identifier.
- Sessions live in process memory and the application runs, or will run, on several instances.
- Users lose their work on deploy or restart, or the session store grows without bound.
- Someone proposes "just put it in the session".

## Rules

1. **Choose the session-state pattern before adding features that depend on it.** Compact checklist (from `mini.md`): each piece of session data has a stated owner, lifetime, storage location, security stance, failover behavior, durability and cleanup. State without an owner and a lifetime leaks or vanishes. Check: a short table exists, even three lines long.
2. **Use Client Session State only when client storage is acceptable and the integrity and security implications are handled.** The client can read and change anything it holds. Check: nothing the user must not read or alter is held on the client, or it is protected (signed or encrypted) and verified on every request.
3. **Never let a client-held value decide something the user is not allowed to decide.** Added judgment, a consequence of rule 2: prices, discounts, roles and totals are derived on the server from what the user actually chose. A derived value the client can alter is a direct way to cheat.
4. **Use Server Session State when server-managed session data is needed and the scaling and cleanup costs are explicit.** Memory sessions cost RAM per user and do not survive restarts, so their costs must be known. Check: memory per session, expiry, eviction, and how requests reach the server holding the session (affinity or a shared store) are written down.
5. **Use Database Session State when session durability or server-farm sharing outweighs the database load.** Database sessions trade load for durability and sharing. Check: the extra reads and writes per request are estimated, and an expiry job removes abandoned sessions.
6. **Define lifetime and cleanup for every session store.** Abandoned sessions otherwise accumulate. Check: an expiry rule exists, and something enforces it (time-to-live, scheduled delete).
7. **State what happens on restart and failover.** Failover turns a hidden assumption into a visible user problem. Check: you can answer "a server is replaced mid-session: what does the user see?" for each kind of session data.
8. **Keep session data small and by reference.** Added judgment: store identifiers and user choices, not copies of domain objects, so the session cannot go stale against the database. Copies in a session go stale against the database.
9. **Keep UI interaction state out of domain logic.** UI state in the domain couples rules to one screen. Check: step numbers, selected tabs and filters live in session or client state and presentation code, not in domain classes (`enterprise-patterns-presentation-layer`).
10. **Treat each choice as reversible by design.** Added judgment: access session data through one small interface, so moving from server memory to a shared store is a change in one place.

## Procedure

1. List the data that must outlive a request, with its sensitivity and how long it matters.
2. For each item decide: can the user hold it safely (client), must the server keep it (server), or must it survive restarts and be shared (database)?
3. Write the table from rule 1 and agree it with whoever runs the deployment.
4. Implement behind one session interface; add expiry and cleanup now, not later.
5. Recompute derived values (prices, permissions) on the server at the point of use.
6. Test: tampered client state, expired session, and restart or failover for the chosen store.

## Example

```python
import json

# Before: the cart cookie carries prices, and checkout trusts them
def checkout_total_before(cookie: str) -> int:
    cart = json.loads(cookie)        # {"items": [{"sku": "A1", "qty": 2, "price_cents": 1000}]}
    return sum(i["qty"] * i["price_cents"] for i in cart["items"])   # the client can edit price_cents

# After: client state holds only what the user chose; the server derives everything else
def checkout_total(cookie: str, price_of) -> int:
    cart = json.loads(cookie)        # {"items": [{"sku": "A1", "qty": 2}]}
    total = 0
    for item in cart["items"]:
        qty = int(item["qty"])
        if not 1 <= qty <= 99:
            raise ValueError("quantity out of range")
        total += qty * price_of(item["sku"])     # authoritative price list on the server
    return total
```

The client may still change `qty`; that is its own cart, and the server bounds it. It can no longer change what the cart costs. If the cart must survive across devices or restarts, the same data moves to Server or Database Session State behind the same interface, which is why the data is kept small and by reference.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Trusting the client | Derived values (price, role, total) read from cookies or hidden fields | Recompute on the server |
| Unowned session data | Keys added to the session ad hoc, no lifetime | Session table with owner and expiry |
| Memory sessions on a farm | In-process sessions and several instances without affinity or sharing | Shared store, or deliberate affinity |
| Immortal sessions | Session table with no expiry job | Time-to-live and cleanup |
| Domain objects in the session | Entire entities serialized into it | Identifiers and choices only |
| Session as database | Business facts stored only in the session | Persist through the normal workflow |

## Trade-offs and exceptions

- Client Session State is fine when the data is harmless and bounded (a theme choice, a sort order) or protected and verified.
- Server memory sessions are simplest when there is one instance and loss on restart is acceptable; the source requires the scaling and cleanup costs to be explicit, not that the pattern be avoided.
- Database sessions cost load per request; the source accepts it when durability or sharing across a server farm outweighs it.
- Authentication protocols, token formats and cookie flags are security design outside this book.

## Verification

- [ ] Every session datum has owner, lifetime, location and trust noted.
- [ ] No decision depends on an unverified client value.
- [ ] Expiry and cleanup are implemented.
- [ ] Restart and failover behavior is stated and tested for the chosen store.
- [ ] Session data is small and by reference.
- [ ] No domain class holds UI state.

## Related

`enterprise-patterns-presentation-layer` for UI state; `enterprise-patterns-offline-locking` for concurrent edits of stored data; `enterprise-patterns-web-presentation-patterns` for flow state; `enterprise-patterns-session-state-reviewer` to review a diff.

## Source

- `Session State and Base Pattern Index`
- `Presentation Layer Rules`: only the rule that UI interaction state belongs outside domain logic.
