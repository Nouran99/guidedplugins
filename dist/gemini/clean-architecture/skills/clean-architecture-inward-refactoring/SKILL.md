---
name: "clean-architecture-inward-refactoring"
description: "Use only when asked to restructure existing code toward Clean Architecture in safe steps: wrapping details, replacing concrete dependencies with ports, splitting god services, ordering several findings. Where a moved rule lands is entities-and-invariants; the target shape is in its cluster skill."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Inward refactoring

Owns the sequence of moves that turn existing code toward the rules, one safe step at a time. The shape each move aims at is in the cluster skills (`clean-architecture-entities-and-invariants`, `clean-architecture-ports-and-gateways`, `clean-architecture-service-sprawl` and the others); a specific move can be run with `/clean-architecture:extract-use-case` or `/clean-architecture:introduce-port`.

## When to use

- You are asked to improve the structure of code whose behavior must stay the same.
- A feature or bug fix would be easier after the logic is moved out of a controller, job or gateway.
- A review lists several architectural findings and you must choose an order.
- Someone proposes a rewrite of a module to "do it properly".

## Rules

1. **Move business rules inward.** `[MUST]` Extract domain logic from controllers, handlers, views, gateway classes and jobs. Check: after the step, the rule lives in an entity or use case and the old place only calls it.
2. **Introduce boundaries around details.** `[MUST]` Wrap external services, database access, message buses, filesystem operations and clocks. Check: each detail you touched is reached through an interface the core owns.
3. **Replace concrete dependencies with ports.** `[MUST]` Define the interfaces in inner layers and implement them in outer layers. Check: the core names no concrete adapter.
4. **Separate translation from policy.** `[MUST]` Parsing requests, mapping data, serializing and formatting for presentation all belong outside the core business rules. Check: the core has no parsing, mapping or formatting code.
5. **Break up god services.** `[MUST]` Split by use case and give each use case one clear application action (`clean-architecture-service-sprawl`).
6. **Eliminate framework coupling from tests.** `[SHOULD]` Rewrite tests to target use cases and entities directly where possible; the source's "where possible" keeps this a strong default (`clean-architecture-testing-seams`).
7. **Preserve behavior while improving direction.** `[MUST]` Refactor incrementally; prefer (`SHOULD`) safe boundary extraction over large rewrites. Check: the observable behavior and the existing tests are unchanged after every step.
8. **Keep or improve the dependency direction, and add no framework dependency to an inner layer.** `[MUST]` Applies to any modification of existing code. Check: the diff adds no outward import to a core file.
9. **Call out architectural debt explicitly when it cannot be fixed safely now.** `[MUST]` Check: the report lists what remains, why it was left, and what would fix it (`clean-architecture-boundary-economics` for the note format).
10. **Choose the order by what unlocks testing.** Added judgment: first the move that lets the rule be tested without the detail (rules 1 and 4), then the port for the dependency that still blocks the test (rules 2 and 3), then the split (rule 5), then the tests (rule 6). Check: after each step more of the behavior can be tested without a framework.
11. **Make each step small enough to review alone.** Added judgment: one move per step, tests green between steps, and no behavior change mixed with a structural change. Check: the step's diff can be described in one sentence.
12. **Characterize before moving when behavior is unclear.** Added judgment: if the code has no tests, pin down its current behavior first. The `legacy-code` plugin covers that; return here once the code is under test. Check: a test fails if the moved code changes behavior.

## Procedure

1. Run the tests and record the baseline; stop and report if it fails or if no test exists to protect the area (rule 12).
2. List the architectural findings in scope and order them by rule 10.
3. Do the first move: extract the rule into an entity or use case behind the same entry point, so callers do not change.
4. Run the tests; review the diff. Commit-sized, reversible, nothing else changed.
5. Do the next move (port, then adapter, then wiring), running the tests after each.
6. Split the service, then rewrite the framework-bound tests, one at a time.
7. Report what changed, the tests run, and the debt left (rule 9).

## Example

```python
# Start: an AWS Lambda-style handler that does everything
def handler(event, context):
    body = json.loads(event["body"])
    row = db.fetch_one(
        "select balance_cents, frozen from accounts where id = %s", body["account_id"]
    )
    if row["frozen"] or row["balance_cents"] < body["amount_cents"]:
        return {"statusCode": 409, "body": json.dumps({"error": "cannot withdraw"})}
    db.execute(
        "update accounts set balance_cents = balance_cents - %s where id = %s",
        body["amount_cents"], body["account_id"],
    )
    return {"statusCode": 200, "body": "{}"}
```

```python
# Step 1: move the rule inward. Same entry point, same behavior; one new test for the rule.
class Account:
    def __init__(self, account_id, balance_cents, frozen):
        self.account_id, self.balance_cents, self.frozen = account_id, balance_cents, frozen

    def can_withdraw(self, amount_cents):
        return not self.frozen and self.balance_cents >= amount_cents


def handler(event, context):
    body = json.loads(event["body"])
    row = db.fetch_one(
        "select balance_cents, frozen from accounts where id = %s", body["account_id"]
    )
    account = Account(body["account_id"], row["balance_cents"], row["frozen"])
    if not account.can_withdraw(body["amount_cents"]):
        return {"statusCode": 409, "body": json.dumps({"error": "cannot withdraw"})}
    db.execute(
        "update accounts set balance_cents = balance_cents - %s where id = %s",
        body["amount_cents"], body["account_id"],
    )
    return {"statusCode": 200, "body": "{}"}


# Step 2: the entity changes its own balance, a use case orchestrates, and the port is load and save only.
# The handler shrinks to translation. Tests green after each step.
class Account:
    # ... __init__ and can_withdraw as above ...

    def withdraw(self, amount_cents):
        if not self.can_withdraw(amount_cents):
            return False
        self.balance_cents -= amount_cents
        return True


class Withdraw:
    def __init__(self, accounts):          # accounts: a port with get(id) and save(account), declared next to this class
        self._accounts = accounts

    def execute(self, account_id, amount_cents):
        account = self._accounts.get(account_id)
        if not account.withdraw(amount_cents):
            return False
        self._accounts.save(account)
        return True
```

After step 2 the handler parses the event, calls `Withdraw(accounts).execute(...)` and maps `False` to 409 and `True` to 200. The gateway only loads and stores an `Account`; the decision and the balance change live in the entity. Each step changed one thing and left the observable behavior alone, with one caveat to check: the original `balance = balance - x` update was atomic, so if withdrawals can run concurrently, make the adapter's `save` conditional on the balance it loaded (or use a version column) rather than a blind overwrite.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Big-bang rewrite | A branch that replaces a module wholesale | Replace with a sequence of boundary extractions |
| Relocation without inversion | Files moved between folders while imports still point outward | Invert the dependency with a port |
| Vendor-shaped port | A new interface whose methods copy the SDK | Cut it down to what the core calls |
| Pass-through extraction | A new class that only forwards the call | Move the rule into it, or leave the code |
| Mixed step | One diff that moves a rule, renames a field and fixes a bug | Separate into steps; the bug fix gets its own test |
| Test deletion | Framework-bound tests removed to get green | Rewrite them to call the use case |
| Silent debt | Findings left unmentioned after a partial refactor | List them with the reason |

## Trade-offs and exceptions

- The source prefers safe boundary extraction over large rewrites. A rewrite can be right when the module is small and fully tested; say so and treat it as a decision.
- A refactoring that cannot be done safely now becomes recorded debt, not a half-finished change.
- When time is short, rules 1 and 3 usually buy the most; rule 5 and 6 can follow. Added judgment.
- Public API names, wire formats and database columns are compatibility surfaces; propose their changes rather than making them as a side effect.

## Verification

- [ ] Baseline tests were recorded and still pass after every step.
- [ ] Each step is a single move that can be reviewed alone.
- [ ] No outward import was added to a core file.
- [ ] Moved rules are covered by a test that needs no framework or database.
- [ ] Remaining architectural debt is listed with reasons.
- [ ] No behavior change is hiding in the structural steps.

## Related

`/clean-architecture:extract-use-case` and `/clean-architecture:introduce-port` for the two most common moves; `/clean-architecture:fix` to carry out review findings; `clean-architecture-use-case-extractor` and `clean-architecture-port-introducer` to delegate; `legacy-code` (a separate plugin) for code without tests.

## Source

- `Refactoring Rules`
- `Output Expectations`: only the list for modifying existing code.
- `When Tradeoffs Are Necessary`: only keeping a path to separation when something cannot be fixed now.
