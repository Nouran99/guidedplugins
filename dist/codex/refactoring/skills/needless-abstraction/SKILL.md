---
name: "needless-abstraction"
description: "Use when a class or layer only forwards calls, an interface has one implementation, a library has one caller, or code exists just in case. Removes weight that exists; merging copies is duplication, hierarchies are inheritance-moves, whether to keep cleaning is stopping-rules."
---

# Needless abstraction

Abstractions are costs: every layer is a jump for the reader and a file to keep consistent. This skill removes the ones that no longer earn their place, and refuses to add the ones that have not yet. Deciding whether more cleanup is justified at all is `$refactoring:stopping-rules`; reshaping inheritance is `$refactoring:inheritance-moves`; merging copies is `$refactoring:duplication`.

## When to use

- A class whose methods only call the same-named methods on another object.
- An interface or abstract class with exactly one implementation and no second planned.
- A "common" library or `utils` package imported from a single place.
- A wrapper, factory or strategy that was added "for flexibility" and never used.
- A reviewer asks for an interface "in case we need another one".

## Rules

1. **Remove forwarding layers that add no value.** Check: a class or function that only delegates, without hiding detail, adding policy or adapting a type, is removed.
2. **Delete abstractions created "just in case" if they are not earning their keep.** Check: you can name what each one makes easier today.
3. **Inline accidental abstractions and collapse unnecessary layers.** Check: the call path from entry point to behavior got shorter.
4. **Delete or inline abstractions that no longer pay for themselves.** Check: an abstraction that once had a second user and now has one is a candidate.
5. **Use Inline Class when a class no longer earns its existence, and Remove Middle Man when a forwarding object no longer hides useful detail.** Check: the class has no behavior or invariant of its own.
6. **Do not introduce interfaces or strategy hierarchies before a second real need appears (Do not).** Check: you can name the second implementation or caller that exists or is committed to now.
7. **Do not create common libraries for one caller (Do not).** Check: the code lives with its only caller until a second one exists.
8. **Do not replace understandable duplication with unclear shared code.** Check: the abstraction is not harder to read than the copies it replaced.
9. **Avoid vague utilities, pass-through layers and just-in-case interfaces that do not improve changeability (compact checklist).** Check: each remaining layer has a named benefit.
10. **Added judgment: the evidence test.** For each abstraction write down what it hides (detail, policy or an adapted type), its real variants today (implementations, not callers) and its callers. A forwarder that hides nothing is inlined whatever its caller count; callers only size the work. An interface, strategy or factory with zero or one variant and no substitute in use is inlined. Keep an abstraction that hides something and has two or more variants with different behavior, or a stated current need; a concrete class that hides detail or owns an invariant already has its need. Check: the list is written down, not assumed.
11. **Added judgment: a test double can be a real second need, but only if you actually use one.** An interface introduced so a test can substitute a collaborator earns its place when such a test exists; the rest of the interface surface does not. Check: the test that uses the substitute exists.
12. **Added judgment: choose between Hide Delegate and Remove Middle Man by whether the forwarding hides detail callers should not know.** Too much forwarding is a middle man; too little is a client that knows the collaborator. Hide Delegate itself is owned by `$refactoring:ownership`; this skill decides only when the forwarding has stopped paying. Check: the decision follows from what callers need, not from taste.

## Procedure

1. List the abstractions in the touched area: interfaces, wrappers, factories, strategies, utility modules.
2. For each, apply the evidence test (rule 10).
3. For pure forwarders (any caller count) and for interfaces, strategies or factories with zero or one variant: inline the layer (move its code into its users), one call site at a time, running tests.
4. Delete the emptied class, interface or module.
5. If a reviewer proposes a new abstraction, ask for the second need; if none, record that and decline.

## Example

```go
// Before: an interface with one implementation, and a service that only forwards
type UserStore interface {
	Get(id string) (User, error)
}

type pgUserStore struct{ db *sql.DB }

func (s pgUserStore) Get(id string) (User, error) { /* query */ return User{}, nil }

type UserService struct{ store UserStore }

func (s UserService) GetUser(id string) (User, error) { return s.store.Get(id) }

// After: callers use the store directly; no interface, no pass-through
type UserStore struct{ db *sql.DB }

func (s UserStore) Get(id string) (User, error) { /* query */ return User{}, nil }
```

If a test later needs a fake store, define the interface then, next to the code that consumes it (rule 11).

## Anti-patterns

- **Pass-through service.** Detect: every method is a one-line call to the same-named method of one collaborator, however many callers use it. Treat: Remove Middle Man.
- **Single-implementation interface.** Detect: one class implements it and no test double does. Treat: delete the interface.
- **One-caller library.** Detect: a package or module imported from one place. Treat: inline it into the caller.
- **Speculative parameter.** Detect: a parameter, option or hook nobody passes. Treat: Remove Parameter.
- **Wrapper that renames.** Detect: a class whose only change is different method names. Treat: inline, or rename at the source.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Public API boundaries may keep an interface for compatibility even with one implementation; say so in a note. (Added judgment)
- Forwarding that adapts a third-party type or isolates a framework is not pass-through; it hides detail. (Added judgment)
- Removing a layer that other code or other teams depend on is a change for them; check the callers (`$refactoring:behavior-preservation`). (Added judgment)
- The source's "second real need" is a judgment call; if a second implementation is already scheduled, state it and keep the abstraction. (Added judgment)

## Verification

- [ ] Each remaining abstraction hides detail, enforces policy or adapts a type, and has at least two real variants or a stated, current need.
- [ ] No class exists that only forwards calls.
- [ ] No interface was added without a second implementation or a test that uses a substitute.
- [ ] The path from entry point to behavior is not longer than before.
- [ ] Tests passed after each inlining.

## Related

`$refactoring:stopping-rules` for whether to continue; `$refactoring:inheritance-moves` for Collapse Hierarchy; `$refactoring:duplication` for the opposite pressure; `refactoring-abstraction-reviewer` to judge each abstraction in a diff.

## Source

- `Middle Man and Speculative Generality`
- `Abstracting Too Early`
- `Class and Module Rules`: only the rule to delete or inline abstractions that no longer pay for themselves.
- `Simplification Refactorings`: only inlining accidental abstractions and collapsing unnecessary layers.
- `Moving Features`: only Inline Class and Remove Middle Man.
