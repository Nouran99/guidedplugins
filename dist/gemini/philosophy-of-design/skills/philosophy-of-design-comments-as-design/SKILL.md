---
name: "philosophy-of-design-comments-as-design"
description: "Use when writing, reviewing or deleting comments and doc comments: contracts, invariants, hidden design decisions and rationale belong in comments; narration or excuses for poor names and structure do not."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Comments as design

Decides which comments earn their place and what a comment is telling you about the design. Drafting a contract before the body exists is the workflow `/philosophy-of-design:comments-first`; renaming identifiers is `philosophy-of-design-naming-and-obviousness`.

## When to use

- You are writing a doc comment for a public function, class or module.
- A comment explains what a line does, or why a confusing name is confusing.
- A comment is long, or keeps growing with each change.
- A public element has no comment and callers have to read its body.

## Rules

1. **Make comments reduce complexity, not narrate obvious code.** Check: remove the comment in your head; if the reader loses no fact they could not read from the code in seconds, delete it.
2. **Write comments for interface contracts.** What the element does for the caller, what it takes and returns, what it guarantees, how it behaves at the edges. Check: every public element a caller could misuse has one, in the caller's vocabulary.
3. **Write comments for non-obvious invariants.** Check: a field or structure whose validity rule is not visible in its type has the rule beside it.
4. **Write comments for hidden design decisions.** Check: a choice a reader would otherwise "fix" (a deliberate ordering, a deliberately slow path) carries its reason.
5. **Write comments for the reason an abstraction exists.** Check: a module-level comment says what the module is for and what it is not for.
6. **Write comments for tricky implementation facts that callers do not need to know, and keep them with the implementation.** Do not document implementation mechanics in the interface comment. Check: the interface comment contains nothing a caller should not rely on.
7. **Do not use comments to compensate for bad naming.** Rename instead. Check: a comment restates or explains an identifier.
8. **Do not use comments to compensate for poor decomposition or confusing control flow.** Restructure instead. Check: banner comments inside one function body; comments that narrate each branch.
9. **Do not use comments to compensate for a missing abstraction.** Check: a comment tells callers how to combine several calls to get one result; create that operation.
10. **Redesign when the comment needed gets long, duplicates the code, justifies a confusing interface, or explains usage by exposing internals.** Check: you cannot state the contract without exceptions to the exceptions.
11. **Added judgment: change the comment in the same diff as the behavior.** A comment that disagrees with the code is worse than none. Check: for every changed behavior in the diff, the contract text was re-read.

## Procedure

1. List the public elements the change adds or alters. For each, check that a contract comment exists or that the name and types make the contract obvious.
2. Classify every comment in the touched code: contract, invariant, decision, reason, tricky fact (keep, check accuracy), or narration and compensation (delete, rename, restructure, or move to the right place).
3. If a contract cannot be written briefly in the callers' words, treat that as a finding about the interface (`philosophy-of-design-interface-design`), not as a writing problem.
4. Place each comment where its reader is: contracts on the interface, implementation facts inside.
5. Re-read the result as a caller who cannot see the body.

## Example

```ts
// Before: narration, bad names, and no contract
// Cache class
class Cache {
  // map of entries
  private m = new Map<string, { v: unknown; t: number }>();
  constructor(private ttl: number) {}
  // get the value
  get(k: string) {
    // check if present
    const e = this.m.get(k);
    // check expiry
    if (!e || Date.now() > e.t + this.ttl) return undefined;
    return e.v;
  }
}

// After: names carry the "what"; comments carry the contract and the decision
/** In-memory cache with a fixed time-to-live. Not shared across processes. */
class TtlCache<V> {
  // Expired entries are skipped on read and overwritten on write, never purged, so a lookup
  // stays constant-time at the price of holding stale values until they are replaced.
  private entries = new Map<string, { value: V; storedAt: number }>();

  constructor(private readonly ttlMs: number) {}

  /** The value stored for `key` within the last `ttlMs` milliseconds, or `undefined`. Never throws. */
  get(key: string): V | undefined {
    const e = this.entries.get(key);
    return e && Date.now() - e.storedAt <= this.ttlMs ? e.value : undefined;
  }

  set(key: string, value: V): void {
    this.entries.set(key, { value, storedAt: Date.now() });
  }
}
```

Five narrating comments disappeared into names and structure; three comments remain because they hold facts the code cannot show (the scope of the cache, a storage decision, the contract of `get`).

## Anti-patterns

- **Narrator.** A comment that repeats the next line. Detect: comment and code share most of their words.
- **Name excuse.** `// number of retries` above `n`. Detect: a comment that defines an identifier.
- **Section banner.** Header comments dividing one function into parts. Detect: three or more banners inside a body (the function wants a different decomposition; the count is Added judgment).
- **Mechanism in the contract.** The interface comment describes data structures or algorithms. Detect: words callers should not rely on (lock names, table names).
- **Stale contract.** Behavior changed and the text did not. Detect: compare the comment to the tests.

## Trade-offs and exceptions

- Some style guides treat comments as a failure of naming. This book does not: it asks for fewer narrating comments and more contract, invariant and rationale comments. Where a repository forbids doc comments, record the contract in types, assertions or module documentation and say so (Added judgment).
- Trivial accessors and self-evident one-liners need no comment when the name and type state the contract.
- Follow the repository's doc-comment convention (JSDoc, godoc, docstrings); the rules here are about content.
- A short comment that marks a deliberate oddity ("do not reorder: the checksum covers the previous row") is a hidden design decision and belongs.

## Verification

- [ ] Every new public element has a contract comment or an obvious contract.
- [ ] No comment narrates a line or excuses a name.
- [ ] Every remaining comment states a contract, invariant, decision, reason or tricky fact.
- [ ] Interface comments contain no implementation mechanics.
- [ ] Comments for changed behavior were updated in the same diff.

## Related

`/philosophy-of-design:comments-first` for the contract-before-code workflow; `philosophy-of-design-naming-and-obviousness`; `philosophy-of-design-interface-design`; `philosophy-of-design-comment-reviewer` to review; `philosophy-of-design-contract-writer` to write contracts.

## Source

- `Comment Rules`
- `Design Alternatives and Comments-First Design`: only the rules on what comments may and may not do.
