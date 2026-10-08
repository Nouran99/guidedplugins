---
name: pull-complexity-down
description: "Use when the same setup, validation or special-handling lines are repeated at the call sites of one callee, when a module offloads decisions to its users, or when a simpler public contract would justify a more complex implementation."
---

# Pull complexity downward

Moves work that every caller repeats into the module that owns the knowledge, even when that module's implementation grows. Where knowledge lives is `/philosophy-of-design:information-hiding`; the shape of one element is `/philosophy-of-design:interface-design`; parameters that choose behavior are `/philosophy-of-design:flags-and-knobs`.

## When to use

- The same preparation (normalizing, deriving a header, choosing a default) appears before many calls to one function.
- Call sites carry guards that the callee could apply.
- A module's easy implementation was achieved by adding parameters or setup steps for its users.
- A review comment says "every caller has to remember to ...".

## Rules

1. **Put complexity in one place rather than many.** Check: the intricate logic exists once, in the module that owns the underlying knowledge.
2. **Hide intricate logic behind a simpler public contract.** Check: the contract is shorter than the logic it hides.
3. **Prefer a slightly more complex implementation if it makes all callers simpler.** Check: the implementation diff grows; the sum of caller diffs shrinks.
4. **Remove repeated reasoning burdens from call sites.** Check: after the change, a caller does not need to remember a rule to call correctly.
5. **Do not push complexity outward through flags, setup steps or coupled operations.** Check: the change does not add parameters or required sequences for callers.
6. **Do not repeat the same special handling in many places.** Check: search for the repeated guard or conversion; after the change one copy remains, in the owner.
7. **Do not make all callers responsible for one module's awkwardness.** Check: no caller works around a quirk of the callee.
8. **Simplify all callers, even if the implementation grows slightly.** When generating code, treat caller simplicity as the goal of the design. Check: you can show the before and after call site.
9. **Pull down only what the lower module owns.** Added judgment: the lower module must already have the information to decide (it holds the data, the format or the policy). Check: the new logic uses only facts the module knows; otherwise the knowledge belongs elsewhere or is a real caller choice.
10. **Added judgment: leave a narrow, named override for a caller that truly knows better.** Check: the override exists only if a real caller needs it, and the default serves everyone else.

## Procedure

1. Find the repetition: search for the same two or three lines before calls to the same function, or the same guard around a result.
2. Write down the fact each repetition encodes (a content type rule, a normalization, a default).
3. Confirm the callee owns or can cheaply get that fact (rule 9).
4. Move the logic into the callee and state it in the contract comment.
5. Remove the repeated code from callers; remove parameters that only carried the derived value.
6. Keep an override only if a caller needs it; test the default path and the override.

## Example

```go
// Before: every caller derives the content type and checksum before every Put.
func (s *Store) Put(key string, data []byte, contentType, sha256hex string) error

sum := sha256.Sum256(img)
err := store.Put("avatars/"+id, img, http.DetectContentType(img), hex.EncodeToString(sum[:]))

// After: the store derives both; callers pass what they have.
// Put stores data under key. The content type is detected from the bytes and a SHA-256
// checksum is recorded so that Get can verify the object.
func (s *Store) Put(key string, data []byte) error {
	sum := sha256.Sum256(data)
	return s.client.upload(key, data, http.DetectContentType(data), hex.EncodeToString(sum[:]))
}

// A rare caller that knows the type better has a named override.
func (s *Store) PutWithType(key string, data []byte, contentType string) error {
	sum := sha256.Sum256(data)
	return s.client.upload(key, data, contentType, hex.EncodeToString(sum[:]))
}

err := store.Put("avatars/"+id, img)
```

The store grew by a few lines; every call site shrank and lost the chance to pass a wrong checksum.

## Anti-patterns

- **Caller ceremony.** The same preparation before each call. Detect: repeated lines before calls to one function.
- **Option outsourcing.** Parameters that hand the callee's decision to every caller. Detect: arguments most callers pass identically.
- **Setup choreography.** `create`, `configure`, `start` driven by callers. Detect: the same sequence at several sites.
- **Duplicate guard clauses.** The same pre-check in every caller. Detect: identical `if` statements before calls.
- **Convenience wrappers at every call site.** Each team writes its own `uploadAvatar`. Detect: several local helpers around one function.

## Trade-offs and exceptions

- Do not pull down what the lower module cannot know. A caller's business choice (retention, audience) stays with the caller; the module offers it as a named parameter.
- Pulling complexity down must not create an unfocused module; take only complexity that belongs to the module's own abstraction (Added judgment).
- Security- and safety-sensitive logic moved into a shared module deserves its own focused tests, because every caller now depends on it.
- If a caller's special need is genuinely rare, keep the default simple and offer the override rather than complicating the common path.

## Verification

- [ ] The repeated code now exists once, in the owning module.
- [ ] No new parameter, flag or required sequence was added for callers.
- [ ] The contract comment states what the module now does for the caller.
- [ ] Every call site is simpler, or at least unchanged.
- [ ] Tests cover the default path and any override.

## Related

`/philosophy-of-design:information-hiding`; `/philosophy-of-design:interface-design`; `/philosophy-of-design:flags-and-knobs`; `philosophy-of-design:caller-burden-reviewer` to review; `philosophy-of-design:module-deepener` to delegate the move.

## Source

- `Pull Complexity Downward`
- `Complexity Spread`
- `Code Generation Rules`: only the rule to simplify all callers even if the implementation grows slightly.
