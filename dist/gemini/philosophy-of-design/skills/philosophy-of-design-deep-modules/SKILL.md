---
name: "philosophy-of-design-deep-modules"
description: "Use when designing or reviewing a class, module, service or package: judge whether its interface is small and meaningful relative to the work it hides, and whether it carries its own weight."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Deep modules

Designs and judges modules by the ratio of what callers must learn to what the module does for them. Recognising and removing forwarding layers is `philosophy-of-design-pass-through-layers`; deciding where one unit ends and another begins is `philosophy-of-design-split-or-merge`.

## When to use

- You are creating a class, package or service, or reshaping one.
- A module has many public methods and each does little.
- Callers must read the implementation to use a module correctly.
- A review asks "what does this module actually do for its callers?"

## Rules

1. **Design modules to hide meaningful internal complexity.** A module earns its place by absorbing work callers would otherwise do or know. Check: complete "after this module exists, a caller no longer has to ..." with something real.
2. **Prefer a small interface with strong semantics over a large surface with minor helpers.** One operation that does the whole job beats five that must be combined in the right order. Check: count the calls a typical caller makes to finish one job; the target (Added judgment) is about one.
3. **Make each module carry its own weight.** Check: delete the module in your head. If callers get simpler, it was cost; if they only get longer, it was value.
4. **Treat a module that only forwards work as usually too shallow.** Check: every public method body is a single call to one collaborator with the arguments passed straight through.
5. **Compare interface weight with implementation weight.** A module is shallow when its interface exposes almost as much complexity as its implementation. Check: write the contract (inputs, outputs, guarantees, failure behavior); if it is nearly as long and intricate as the code, the module is shallow.
6. **Judge depth by what the caller must understand, not by line count.** Do not optimize for shorter files or fewer lines if complexity rises. A large implementation behind a short contract is the goal. Check: measure the contract, not the file.
7. **Give the interface strong semantics.** Guarantees such as what is normalized, ordered, atomic or idempotent let callers stop checking. Check: callers do not re-validate or re-normalize what the module returns.
8. **Absorb the step every caller performs next to your module.** If every caller does A then B, a deeper module does both. Check: search for the same two calls in sequence at several sites (`philosophy-of-design-pull-complexity-down`).
9. **Added judgment: judge depth against the callers that exist or that this task adds.** A module can be deep for one set of callers and shallow for another; do not invent speculative callers to justify surface area.
10. **Added judgment: depth is a property of the outside view.** Private helpers inside a deep module are fine. Check: no helper is exported only because it was convenient to test or reuse.

## Procedure

1. List the jobs callers need done, as verbs from the callers' point of view.
2. Draft the smallest interface that completes each job.
3. Write the contract comment. If it grows long or conditional, simplify the interface or move complexity inward.
4. Move behind the interface the work callers do today: normalization, defaults, ordering, bookkeeping.
5. Compare before and after by contract length and by calls per job.
6. Migrate callers one at a time and run the tests after each.

## Example

```ts
// Before: a shallow service; every caller assembles the real work.
class UserService {
  constructor(private repo: UserRepository) {}
  findByEmail(email: string) { return this.repo.findByEmail(email); }
  save(user: User) { return this.repo.save(user); }
}
// each caller
const email = raw.trim().toLowerCase();
if (await service.findByEmail(email)) throw new Error("taken");
await service.save(new User(email, await hash(password)));

// After: one operation hides normalization, hashing and the uniqueness race.
type Registration = { ok: true; id: string } | { ok: false; reason: "email-taken" };

class Accounts {
  constructor(private store: UserStore, private hasher: PasswordHasher) {}

  /** Registers an account. Emails are compared case-insensitively and without surrounding spaces. */
  async register(rawEmail: string, password: string): Promise<Registration> {
    const email = rawEmail.trim().toLowerCase();
    const id = await this.store.insertIfAbsent(email, await this.hasher.hash(password));
    return id === null ? { ok: false, reason: "email-taken" } : { ok: true, id };
  }
}
```

Callers now make one call and cannot get the check-then-insert race wrong, because the store's atomic `insertIfAbsent` is hidden behind the contract.

## Anti-patterns

- **Pass-through service.** Every method is one delegating line. Detect: method bodies equal to `return this.x.sameName(args)`.
- **Representation-shaped interface.** One getter and one setter per internal field. Detect: public accessors that mirror the private fields one to one.
- **Public utilities used once.** Helpers exported "for reuse" with a single caller. Detect: exported names with one reference.
- **Depth by volume.** A big method with a dozen parameters: the work is inside but the interface is as complex as the implementation. Detect: a contract that needs a table to explain.

## Trade-offs and exceptions

- Shallow is not the same as short. A small module that is the only home of a real decision (a retry schedule, a file layout) hides something and is fine (Added judgment).
- Do not hide so much that callers cannot influence a decision they truly must control; keep that control narrow and named for the caller's intent.
- Public libraries and frameworks may force a class shape; keep the forced shell thin and put the substance in a deeper module behind it.
- Performance-driven exposure of internals needs evidence: `philosophy-of-design-performance-and-trends`.

## Verification

- [ ] One sentence states what callers no longer need to know.
- [ ] A typical job takes about one call.
- [ ] The contract is shorter and simpler than the implementation.
- [ ] No caller re-normalizes or re-checks the results.
- [ ] Any helper added is private.

## Related

`philosophy-of-design-pass-through-layers` for the opposite case; `philosophy-of-design-interface-design` for the shape of each element; `philosophy-of-design-information-hiding` for what to hide; `philosophy-of-design-depth-reviewer` to review a diff; `/philosophy-of-design:depth-map` for an inventory.

## Source

- `Module Depth Rules`
- `Prefer Deep Modules`
- `Avoid Shallow Modules`: the forwarding-module rule (4) and the interface-versus-implementation weight rule (5).
- `Primary Directive`: only the line against optimizing for shorter files or fewer lines (6).
