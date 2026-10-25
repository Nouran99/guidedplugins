---
name: "legacy-code-hard-outputs"
description: "Use when code writes files, calls the network, exits the process, writes the database, publishes messages or uses logging as control flow, so effects cannot be observed in a test. Clock and environment reads are `legacy-code-hidden-inputs`; decisions in handlers are `legacy-code-policy-vs-mechanism`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Hard outputs

A hard output is an effect that leaves the code and cannot be avoided or inspected from a test. This skill puts such effects behind explicit collaborators so a test can observe them or turn them off. Values the code reads from its surroundings are `legacy-code-hidden-inputs`; moving a decision out of a handler or a query layer is `legacy-code-policy-vs-mechanism`.

## When to use

- A test would write real files, hit a real endpoint, publish a real message or write a real table.
- A function calls `exit` (or its equivalent) deep in logic, so a test would end the process.
- The only record of a decision is a log line, or behavior depends on what was logged.
- You cannot assert on what the code did, only on what it returned.

## Rules

1. **When legacy code is hard to test, look for hard outputs: direct file writes, network calls, process exits, direct database writes, direct message publication, and logging used as control flow.** [MUST] Check: you searched the code under test for each kind and listed what you found.
2. **Extract side effects behind explicit collaborators.** [MUST] Check: the code under test holds a collaborator and calls it, instead of calling the file system, client or driver directly.
3. **Narrow the code under test to a manageable slice.** [MUST] Check: the test exercises the decision, with the effect replaced, not the whole workflow.
4. **Keep integration tests for actual persistence and network behavior.** [MUST] The doubles replace effects in policy tests; the real boundary still needs its own test. Check: one test exercises each real writer you wrapped.
5. **Prefer improving untestable structure to mocking around it.** [SHOULD] A recording collaborator at a boundary you created is an improvement; patching internals is not. Check: the double sits at the new collaborator.
6. **Do not add new hard outputs in the style of the legacy code.** [MUST NOT] Check: the diff adds no direct file, network, exit, database or publish call inside logic.
7. **Separate deciding from doing.** [Added judgment] The code that decides what must happen returns the decision or hands it to a collaborator; the collaborator carries it out. Check: you can test the decision with the effect turned into a recorded call.
8. **Name collaborators for intent, not mechanism.** [Added judgment] `saveClosed` and `announceClosed` say what the code needs; `execute` and `send` say how it is done today. Check: the interface survives a change of database or transport.
9. **Process exits: return a result and exit only at the entry point.** [Added judgment] Check: a test can call the function without ending the process, and the entry point turns the result into the same exit code as before.
10. **Logging used as control flow: make the decision a return value or event, and let logging describe it.** [Added judgment] Check: nothing branches on log output, and the decision is observable without reading a log.
11. **Sense through the collaborator.** [Added judgment] A recording double is a sensing seam: it exists so the test can see what the code did. Check: the assertion reads recorded calls, with order and arguments.
12. **Preserve order and failure behavior.** [Added judgment] Effects happen in the same order and on the same failures as before. Check: the recording test asserts order, and a failing collaborator produces the failure the old code produced.

## Procedure

1. Search the code under test: file writes, HTTP or RPC clients, `exit`, database drivers and query calls, publishers, loggers that carry decisions. List each with its location.
2. Pin current behavior first if it is unclear (`/legacy-code:characterize`); outputs are behavior.
3. For each effect worth testing, define a narrow collaborator named for intent and pass it in; default it to the real implementation at the edge.
4. Turn exits into results; move the exit to the entry point.
5. Write the recording test for the decision; keep or add the real-boundary test for the writer.
6. Run all tests; report effects found but left alone.

## Example

```ts
// Before: deciding and doing are one body; the exit ends any test that reaches it
export async function closeOrder(order: Order): Promise<void> {
  const total = order.lines.reduce((sum, l) => sum + l.cents * l.qty, 0);
  if (total === 0) {
    console.error(`order ${order.id} is empty`);
    process.exit(2);
  }
  await db.query("update orders set status='closed', total=$1 where id=$2", [total, order.id]);
  await bus.publish("order.closed", { id: order.id, total });
}
```

```ts
// After: effects behind an intent-named collaborator, the exit at the entry point
export interface OrderSink {
  saveClosed(orderId: string, totalCents: number): Promise<void>;
  announceClosed(orderId: string, totalCents: number): Promise<void>;
}

export type CloseResult =
  | { closed: true; totalCents: number }
  | { closed: false; reason: "empty" };

export async function closeOrder(order: Order, sink: OrderSink): Promise<CloseResult> {
  const totalCents = order.lines.reduce((sum, l) => sum + l.cents * l.qty, 0);
  if (totalCents === 0) return { closed: false, reason: "empty" };
  await sink.saveClosed(order.id, totalCents);
  await sink.announceClosed(order.id, totalCents);
  return { closed: true, totalCents };
}

// entry point: the only place that logs and exits
const result = await closeOrder(order, productionSink);
if (!result.closed) {
  console.error(`order ${order.id} is ${result.reason}`);
  process.exit(2);
}
```

```ts
it("saves, then announces, a non-empty order", async () => {
  const calls: string[] = [];
  const sink: OrderSink = {
    saveClosed: async (id, total) => { calls.push(`save ${id} ${total}`); },
    announceClosed: async (id, total) => { calls.push(`announce ${id} ${total}`); },
  };
  const result = await closeOrder(orderOf("o-1", [{ cents: 250, qty: 2 }]), sink);
  expect(result).toEqual({ closed: true, totalCents: 500 });
  expect(calls).toEqual(["save o-1 500", "announce o-1 500"]);
});
```

`productionSink` is the real implementation of `OrderSink`; its own test talks to a real database and bus. The empty-order case becomes a returned value with no effect calls.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Exit in logic | `exit(`, `System.exit`, `os.Exit` below the entry point | Return a result |
| Direct writer | File, driver or client calls inside a rule | Collaborator named for intent |
| Log as truth | A decision visible only in a log line | Return value or event |
| Mechanism-named port | `send`, `execute`, `write` | Rename for the need |
| Mock the internals | Patches of private functions of the class under change | Move the double to the new collaborator |
| Lost ordering | Effects reordered by the extraction | Assert order in the test |

## Trade-offs and exceptions

- Wrap only the effects that block a test you need; the qualifier is the same as for every dependency break.
- Added judgment: when a function has one effect and one trivial decision, a thin wrapper may add more ceremony than value; characterize through a test double at the existing library seam if one exists.
- The real boundary keeps an integration test; doubles never replace it.
- Added judgment: if the code emits many effects in sequence, return a list of commands for a small executor to run; do this only when more than one effect needs ordering assertions.

## Verification

- [ ] Every hard output found is wrapped, or listed as left alone with a reason.
- [ ] The decision is testable with a recording collaborator.
- [ ] No exit remains below the entry point you touched.
- [ ] A real-boundary test exists for each writer.
- [ ] Order and failure behavior are unchanged.
- [ ] No new direct effect was added inside logic.

## Related

`legacy-code-hard-output-reviewer` to review a diff; `legacy-code-boundary-wrapper` to build the collaborator; `legacy-code-policy-vs-mechanism` for handlers and database-heavy code; `legacy-code-large-methods` when the effect is buried in a long body; `legacy-code-seams` to classify the seam.

## Source

- `Hard Outputs`
- `Dependency Breaking Rules`
- `Required Moves`: only the rules to extract side effects behind explicit collaborators and to narrow the code under test.
- `Database-Heavy Code`: only the rule to keep integration tests for actual persistence behavior.
- `Hidden Dependency Expansion`: only the rule not to embed new hard dependencies in the legacy style.
- `Code Generation Rules`: only the preferred avoidance of mocking untestable structure instead of improving it.
