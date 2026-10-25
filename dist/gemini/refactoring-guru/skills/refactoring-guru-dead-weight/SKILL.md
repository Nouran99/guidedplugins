---
name: "refactoring-guru-dead-weight"
description: "Use when code may be unused or not earning its cost: unused parameters, fields, methods, classes, near-empty classes, or abstractions built for imagined needs (dead code, lazy class, speculative generality). Decides deletion, inlining or keeping; reach checks are public-compatibility."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Dead weight

Owns three Dispensables that cost maintenance without giving value: Lazy Class, Dead Code and Speculative Generality. It finds candidates and chooses delete, inline or keep. Whether a deletion is safe for outside users is `refactoring-guru-public-compatibility`; the symbol-level verdict is `/refactoring-guru:reachability-check`.

## When to use

- A parameter, field, method, class or file has no references you can find, or a branch cannot be reached.
- A class has one or two trivial members and one user, or a subclass overrides nothing.
- An interface, hook, option or factory exists "in case we need it later" and has one implementation and no second client.
- A review comment says "do we still need this?".

## Rules

1. **Inline a class that no longer does enough to justify its maintenance cost** (`SHOULD`), using Inline Class as the preferred rung. Check: the class has few trivial members and a single natural owner for them.
2. **Collapse a hierarchy when subclasses or superclasses no longer carry distinct behavior** (`SHOULD`), as the fallback. Check: the subclass overrides nothing and adds no data that a field could not carry.
3. **You may keep a small class when it clearly communicates an intended extension point and earns that clarity** (`MAY`). Keeping a class only because future work might need it is the risky rung. Check: you can name the extension that exists today or is requested.
4. **Find dead code with IDE and compiler feedback** (`SHOULD`): unused variables, parameters, fields, methods, classes, files and unreachable branches. Check: the tool output is cited, not remembered.
5. **Delete unused code and files when no compatibility reason remains** (`MUST`). Dead code costs reading time and invites misuse. Check: nothing commented out is left behind.
6. **Do not delete public, serialized, reflected or plugin-facing code without checking external compatibility** (`MUST NOT`). That check is `refactoring-guru-public-compatibility`. Check: the deletion note lists the channels searched.
7. **Inline or collapse empty classes or hierarchies before deletion when needed** (`SHOULD`), and remove unused parameters from methods (`SHOULD`). Check: after the step, no empty shell remains.
8. **Treat abstractions, parameters, hooks, fields or classes that exist only for imagined future needs as Speculative Generality, and inline, remove or collapse them** (`SHOULD`). Check: for each, name the second user or the requested feature; if there is none, it goes.
9. **Keep framework extension points only when real users need them** (`MAY`). Removing an extension point without checking its users is the risky rung. Check: users were searched for (see `/refactoring-guru:reachability-check`).
10. **Check tests before deleting a member that exists only for test access** (`MUST`). Check: tests that use the member were read; they test either behavior reachable another way or nothing worth keeping.
11. **Prefer deleting unused structure before extending it** (`SHOULD`). Adding a feature next to dead structure makes the dead part look alive. Check: the cleanup precedes the feature in the plan or is in its own commit.
12. **Delete in its own step with its own test run,** so a failure points at the deletion. Added judgment. Check: the commit or step contains only the removals.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Lazy Class | Inline Class | Collapse Hierarchy | Keeping a class only because future work might need it |
| Dead Code | Delete after usage checks | Inline Class, Collapse Hierarchy or Remove Parameter | Deleting externally reachable API |
| Speculative Generality | Inline Method, Inline Class, Remove Parameter, delete the field | Collapse Hierarchy | Removing framework extension points without checking users |

## Procedure

1. Collect candidates from compiler and IDE output, then read for the patterns that tools miss: parameters always passed the same value, interfaces with one implementation, flags that are never true, options nobody sets.
2. For each candidate, classify the reason: unused (Dead Code), unjustified (Lazy Class) or imagined (Speculative Generality).
3. Added judgment: raise the evidence in order. Compiler or IDE references first, then text and reflection search, then configuration and serialization, then external consumers; stop at the first hit.
4. Decide delete, inline or keep, and apply `refactoring-guru-public-compatibility` for anything reachable from outside.
5. Delete or inline in a separate step, run the tests, and list what was removed and the evidence.

## Example

An options parameter is declared on an interface and on its only implementation, and no caller passes it. The interface stays because tests inject a fake through it.

```ts
// Before
interface Notifier {
  send(to: string, body: string, opts?: { retries: number; locale: string }): void;
}
class EmailNotifier implements Notifier {
  send(to: string, body: string, opts?: { retries: number; locale: string }): void {
    smtp.deliver(to, body); // opts is never read
  }
}

// After: unused parameter removed (service is internal; no caller passes it)
interface Notifier {
  send(to: string, body: string): void;
}
class EmailNotifier implements Notifier {
  send(to: string, body: string): void {
    smtp.deliver(to, body);
  }
}
```

Decisions recorded: `opts` was Speculative Generality and is removed after searching callers (none) and checking that the package is not published. The `Notifier` interface is kept because `NotifierFake` in the tests and the queue worker depend on it, so it has real clients.

## Anti-patterns

- **Compiler-clean deletion.** Deleting what the compiler cannot see used. Detect: no search of strings, configuration or serialization.
- **Just in case.** Keeping a hook or class for a future that has no owner. Detect: the justification contains "might" or "later".
- **Tombstones.** Commented-out code or a `// removed` stub. Detect: comment blocks of code in the diff.
- **Test-only life support.** A member whose only caller is its own test. Detect: references only under test directories.
- **Interface per class.** One interface per implementation with no second client. Detect: an interface with one implementation, no fake and no boundary role.

## Trade-offs and exceptions

- Extension points for frameworks and libraries are legitimate when real users need them; the evidence is a user, not a possibility.
- A small class may stay as a named boundary or extension point.
- Generated code and reflection hide users from tools. Treat "no references" as insufficient evidence in those settings.
- Added judgment: if you cannot establish reach and the cost of keeping is small, record the candidate as deferred instead of deleting (`refactoring-guru-stop-and-defer`).

## Verification

- [ ] The reason for each candidate is classified: unused, unjustified or imagined.
- [ ] Evidence of non-use is listed per deletion.
- [ ] Public, reflected, serialized and plugin-facing reach was checked or the item was deferred.
- [ ] Tests that used a removed member were handled deliberately.
- [ ] The deletion ran in its own step with a test run.

## Related

`refactoring-guru-public-compatibility` and `/refactoring-guru:reachability-check` for safety; `refactoring-guru-dead-weight-reviewer` to review candidates; `refactoring-guru-dead-code-remover` to act; `refactoring-guru-moving-features` for the mechanics of Inline Class; `refactoring-guru-hierarchies` for Collapse Hierarchy.

## Source

- `Dispensables`: only the Lazy Class, Dead Code and Speculative Generality entries.
- `Lazy Class`
- `Dead Code`
- `Speculative Generality`
- `Smell-to-Treatment Priority Map`: only the Lazy Class, Dead Code and Speculative Generality rows.
- `Safety and Tradeoff Rules`: only the preference for deleting unused structure before extending it.
