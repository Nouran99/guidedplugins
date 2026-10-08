---
name: information-hiding
description: "Use when deciding where knowledge belongs: one decision or format (file format, storage shape, protocol detail, internal representation, normalization or edge handling) known by several modules, or workflow bookkeeping exposed to callers."
---

# Information hiding

Decides which single module owns each design decision and keeps that knowledge from leaking through its interface. The shape of one public element is `/philosophy-of-design:interface-design`; work every caller repeats is `/philosophy-of-design:pull-complexity-down`.

## When to use

- Two modules both parse, format, build or interpret the same string, record or key.
- A public method returns an internal container, a database row, a vendor type or a framework object.
- A change to storage, transport or a library forces edits in modules that "only use" it.
- Callers coordinate several objects' internals to finish a job.

## Rules

1. **Hide design decisions that are likely to change.** Storage engine, wire format, vendor, schedule, file layout. Check: ask "if this changes, how many modules change?" The answer should be one.
2. **Hide internal data representations.** Check: no public member returns the live internal collection or exposes a field's concrete type for the sake of convenience.
3. **Hide incidental workflow steps and bookkeeping.** Counters, flags, ordering, cleanup. Check: callers never see or maintain them.
4. **Keep callers from depending on implementation detail, performance hacks or storage shape.** Check: no caller code mentions a table, a key prefix, a buffer size or an index name.
5. **Encapsulate messy edge conditions and normalization logic.** Trimming, case folding, defaults, legacy values. Check: callers pass raw values and the module normalizes.
6. **Do not expose internal representation or state through module interfaces.** Check: the return types of public members are domain concepts, not containers or rows.
7. **Do not leak storage, protocol, framework or file-format details through module interfaces.** Check: no signature includes an ORM entity, an HTTP request object or a raw path format.
8. **Do not make callers coordinate object internals across multiple modules.** Check: no call site must touch two modules in a fixed pattern to complete one job.
9. **Added judgment: one decision, one owner.** When two modules know the same fact, choose the owner by who changes it, move the code there, and delete the duplicate knowledge. Check: search for the shared literal or format; one module should contain it.

## Procedure

1. List the decisions in the touched area that could change (format, store, vendor, rule thresholds, normalization).
2. For each, search the repository for who knows it (literals, field orders, type imports).
3. Pick one owner. Give it semantic operations in the callers' vocabulary.
4. Move the knowledge into the owner and make the old users call the operations.
5. Delete leaked knowledge: exposed fields, parsing code in callers, type imports.
6. Test through the owner's interface, including the edge cases it now absorbs.

## Example

```ts
// Before: two modules know the file layout (field order and separator).
// audit.ts
export function logAction(path: string, user: string, action: string): void {
  fs.appendFileSync(path, `${new Date().toISOString()}|${user}|${action}\n`);
}
// report.ts
const rows = fs.readFileSync(path, "utf8").trim().split("\n").map((l) => l.split("|"));
const failures = rows.filter((r) => r[2] === "login-failed");   // a user name with "|" breaks this

// After: one module owns the format.
// audit-log.ts
export type AuditEntry = { at: string; user: string; action: string };

export class AuditLog {
  constructor(private readonly path: string) {}

  record(user: string, action: string): void {
    const entry: AuditEntry = { at: new Date().toISOString(), user, action };
    fs.appendFileSync(this.path, JSON.stringify(entry) + "\n");
  }

  entries(filter?: { action?: string }): AuditEntry[] {
    if (!fs.existsSync(this.path)) return [];
    return fs.readFileSync(this.path, "utf8").split("\n").filter(Boolean)
      .map((line) => JSON.parse(line) as AuditEntry)
      .filter((e) => !filter?.action || e.action === filter.action);
  }
}
// report.ts
const failures = audit.entries({ action: "login-failed" });
```

The format can now change (rotation, a database) without touching the report, and the separator bug disappears with the knowledge that caused it.

## Anti-patterns

- **Shared format knowledge.** Two modules parse the same string. Detect: the same separator, key prefix or field index in more than one file.
- **Live-container getter.** `getItems()` returns the internal list. Detect: a public method returning a mutable field.
- **Storage-shaped API.** `findByWhereClause(sql)` or row objects returned to callers. Detect: SQL, document paths or column names outside the store.
- **Framework type in a domain signature.** A request or entity class from a framework in a business method's parameters. Detect: framework imports in domain modules.
- **Caller-run protocol.** Callers call `lock`, `write`, `flush`, `unlock` in a pattern. Detect: the same four-call sequence at several sites.

## Trade-offs and exceptions

- A wire or file format that other systems read is part of the interface; document it as such and still keep one module responsible for reading and writing it (Added judgment).
- Callers sometimes must make a real choice (a consistency level, a time zone). Expose it as a named, semantic option, not as a mechanism.
- Bulk or streaming access may justify a controlled read-only view instead of a copy; hide the container's type, not the fact that iteration exists.
- Do not hide a detail the user of the module must see to act correctly (for example that an operation is not atomic); that belongs in the contract (`/philosophy-of-design:comments-as-design`).

## Verification

- [ ] For each decision touched, exactly one module contains the knowledge.
- [ ] No public signature mentions storage, transport or framework types.
- [ ] No public member returns a live internal container.
- [ ] Callers pass raw values and the module normalizes.
- [ ] A test exercises the edge cases through the public interface only.

## Related

`/philosophy-of-design:interface-design` for element shape; `/philosophy-of-design:pull-complexity-down` for repeated caller work; `philosophy-of-design:leakage-reviewer` for a knowledge map of a diff; `/philosophy-of-design:testing-through-interfaces`.

## Source

- `Information Hiding Rules`
- `Interface Leakage`
