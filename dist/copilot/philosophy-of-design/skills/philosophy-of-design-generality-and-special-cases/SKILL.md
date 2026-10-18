---
name: "philosophy-of-design-generality-and-special-cases"
description: "Use when an interface fits exactly one caller, an abstraction is so general it says nothing, or a few rare cases clutter the core path with conditionals. Sets the generality level and isolates special behavior."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Generality and special cases

Chooses how general a module's interface should be, and keeps rare behavior out of the general path. Removing error and invalid-state cases by changing invariants is `philosophy-of-design-define-errors-away`; whether two pieces should be one unit is `philosophy-of-design-split-or-merge`.

## When to use

- A method name describes one screen, button or caller (`markReadFromNotificationBadge`).
- A type is called `Handler`, `Processor` or `Manager` and cannot be described in a domain noun.
- A core function has gathered branches for customers, regions or legacy data.
- You must choose between a narrow helper and a slightly more general operation.

## Rules

1. **Prefer modules that capture a reusable concept at the right abstraction level.** Check: the module can be described by a domain noun and a verb without naming a caller.
2. **Do not overfit an interface to one narrow caller if a slightly more general concept is obvious.** Check: the method name mentions a user interface element, a screen or one caller's workflow.
3. **Do not generalize so far that the abstraction becomes vague.** Check: you can state what the module guarantees in one specific sentence.
4. **Aim for specific enough to be strong and general enough to be reusable within its domain.** Check: the next two plausible callers in the same domain could use it unchanged.
5. **Keep the general case simple.** The ordinary path reads as the ordinary path. Check: remove the rare branches in your head; what remains is short and complete.
6. **Isolate the unusual or rare behavior.** Put it in a clearly named place instead of the core path. Check: each rare case has a name and one home.
7. **Do not pollute the main abstraction with every edge case.** Check: the core function has no conditionals keyed on a customer, tenant, legacy flag or one-off identifier.
8. **Prefer isolating special cases over accreting conditionals in the core path forever.** Check: a new special case adds a line in one isolated place, not a branch in the middle of the algorithm.
9. **Do not separate normal and special cases so far apart that their shared invariant is hidden.** Check: a reader of the special case can still see the rule the general case relies on.
10. **Added judgment: name the generalization in domain words before building it.** If the only name available contains `Generic`, `Manager`, `Handler` or `Processor`, the concept is not yet clear. Check: the name survives being said aloud to someone outside the team.

## Procedure

1. List the callers (or the plausible next two) and what each needs.
2. Find the concept they share; write its contract in one specific sentence.
3. Move caller-specific wording and behavior out of the module and into the callers or a thin special layer.
4. For each rare case in the core path, extract or route it to a named place; keep a comment or test naming the invariant they share.
5. Check the general interface against the callers: is each use one clear call?
6. Run the tests, including a focused test per isolated case.

## Example

```ts
// Before: one method per entry point. Each re-implements the state change and tangles in its own bookkeeping.
class NotificationService {
  markReadFromBadge(userId: string, id: string): void { /* set read; refresh the badge count */ }
  markReadFromEmailLink(token: string): void { /* resolve the token; set read; log an "email" click */ }
  markReadFromDigest(userId: string, ids: string[]): void { /* set read for each id; log a "digest" click */ }
}

// After: a general store that only knows read state, and a thin layer that knows the entry points.
class NotificationStore {
  private readIds = new Map<string, Set<string>>(); // userId -> ids already read

  /**
   * Marks the notifications read for the user and returns the ids that were unread before.
   * Repeated ids, in one call or across calls, are reported once. Shared by every entry point:
   * an id counts as "newly read" only the first time it flips.
   */
  markRead(userId: string, ids: string[]): string[] {
    const seen = this.readIds.get(userId) ?? new Set<string>();
    this.readIds.set(userId, seen);
    const changed: string[] = [];
    for (const id of ids) {
      if (!seen.has(id)) {
        seen.add(id);
        changed.push(id);
      }
    }
    return changed;
  }
}

class NotificationEntryPoints {
  constructor(
    private store: NotificationStore,
    private linkTokens: { resolve(token: string): { userId: string; id: string } },
    private analytics: { recordClicks(source: "email" | "digest", ids: string[]): void },
  ) {}

  fromBadge(userId: string, id: string): void {
    this.store.markRead(userId, [id]);
  }
  fromEmailLink(token: string): void {
    const { userId, id } = this.linkTokens.resolve(token);
    this.analytics.recordClicks("email", this.store.markRead(userId, [id]));
  }
  fromDigest(userId: string, ids: string[]): void {
    this.analytics.recordClicks("digest", this.store.markRead(userId, ids));
  }
}
```

The store's interface serves any caller that holds ids and has no `source` argument; token resolution and click attribution, the parts that differ per entry point, live in one thin layer, and a fourth entry point adds one method there.

## Anti-patterns

- **Single-caller interface.** Names that tell a screen's story. Detect: a public method used from one place with a name that mentions that place.
- **Vague mega-abstraction.** One generic type configured by many parameters to cover every use. Detect: a name ending in `Generic`, `Manager` or `Processor` and a constructor with many options.
- **Accreted conditionals.** `if (customer.id === ...)` inside a core function. Detect: literals or identifiers of specific tenants in business logic.
- **Special case far from its rule.** A rare case in a distant module that silently relies on an invariant of the general case. Detect: a special-case file with no mention of the invariant.
- **Parallel copies.** The general code duplicated for each special variant. Detect: near-identical functions differing in a few lines.

## Trade-offs and exceptions

- With one caller and no obvious more general concept, keep the interface specific (Added judgment); the source only forbids overfitting when a slightly more general concept is obvious.
- A special case that is not rare (it covers half the traffic) is part of the general case; model it, do not isolate it (Added judgment).
- Isolating a case must not hide the invariant it shares with the general path; keep them findable from each other.
- Some domains legitimately have many special cases (tax rules); isolate them as data or small named rules rather than branches (Added judgment).

## Verification

- [ ] The module can be described in one specific sentence without naming a caller.
- [ ] No caller-specific wording is left in the general interface.
- [ ] The core path contains no branch keyed on a one-off identifier.
- [ ] Each rare case has a name, one home and a focused test.
- [ ] The shared invariant is stated near both the general and the special code.

## Related

`philosophy-of-design-define-errors-away`; `philosophy-of-design-split-or-merge`; `philosophy-of-design-interface-design`; `philosophy-of-design-special-case-reviewer` to review; `philosophy-of-design-special-case-isolator` to move branches out.

## Source

- `General-Purpose vs Special-Purpose Modules`
- `Special-General Decomposition`
- `Combine or Separate Code`: only the rule on keeping normal and special cases from drifting apart.
