---
name: complexity-management
description: "Use when code is hard to hold in your head: tangled routines, duplicated logic, clever expressions, growing special cases. One branch: /code-complete:control-flow. One routine: /code-complete:routine-design. To refactor: /code-complete:refactoring-judgment."
---

# Complexity management

Treats rising complexity as a defect risk and asks of a change: does a maintainer now have to keep more in mind, or less? It is the symptom-and-judgment skill; the fix for a specific branch, routine, class or data problem lives in the skill that owns it.

## When to use

- A change makes a routine or module harder to explain than it was.
- The same rule, constant or algorithm appears in several places, so one change needs several edits.
- A one-liner or compressed expression needs more than one read.
- Each new requirement adds another special case or flag to existing code.
- You are choosing between a clever design and a plain one.

## Rules

1. **Treat rising complexity as a defect risk.** Why: more interacting parts means more states no one tested. Check: compare before and after on what a reader must hold: live variables, paths, special cases, flags that interact.
2. **Prefer simple code over clever code.** Why: cleverness saves keystrokes once and costs interpretation every time. Check: a colleague can say what the block does after one read, without running it.
3. **Break apart large or tangled routines and modules.** Why: parts that can be understood alone can be verified alone. Check: each part has a name and a purpose; the split follows the seams the code already has (`/code-complete:routine-design`, `/code-complete:class-design`).
4. **Remove duplication that multiplies maintenance effort.** Why: duplicated knowledge diverges. Check: change one business rule and count the places that need editing; more than one is duplication worth removing.
5. **Choose designs that reduce the amount a maintainer must keep in working memory.** Check: related state is kept together, scope is narrow, and a routine's meaning does not depend on distant code.
6. **Write code primarily for human readers.** Foundational rule. Check: the first reader is a colleague who did not write it.
7. **Favor clarity, locality and explicitness over trickiness.** Foundational rule. Check: what a routine needs is visible at the call or declaration; there is no action at a distance.
8. **Do not optimize for cleverness, minimal keystrokes or fashionable idioms at the cost of clarity.** Primary directive. Check: the shorter form is not chosen only because it is shorter.
9. **Do not write dense tricks or compressed expressions that save lines but increase interpretation cost.** Forbidden pattern. Check: no expression nests more than one idea that a reader must unpack in their head.
10. Added judgment: not all duplication is waste. Two similar blocks that change for different reasons are cheaper than a shared abstraction that serves both badly; remove duplication of knowledge, not of shape.
11. Added judgment: each flag or special-case branch added to existing logic multiplies paths; when a third case arrives, look for a table (`/code-complete:table-driven`) or a named concept before adding another branch.
12. Added judgment: count simplification honestly. Moving complexity into a helper with a vague name, or into configuration, relocates it; it is only reduced when the reader needs to know less.

## Procedure

1. Describe the changed code in plain words. Where the description needs "except" or "unless", mark the spot.
2. Look for repeated knowledge: the same constant, rule or conversion in several places.
3. Look for density: nested ternaries, chained calls with embedded logic, regex doing three jobs, comprehensions with side effects.
4. For each hit choose the owning skill's fix and apply it in a small step: name a predicate, extract a routine, introduce a table, move a responsibility.
5. Keep the behavior; run the tests after each step.
6. Re-describe the code in plain words. If the description got shorter, the change was a simplification.

## Example

```python
# Before: one expression does extraction, counting, sorting and truncation
def top_domains(emails, n=3):
    return sorted({d: sum(1 for e in emails if e.split("@")[1] == d) for d in {e.split("@")[1] for e in emails}}.items(), key=lambda kv: (-kv[1], kv[0]))[:n]

# After: each step has a name; the tie-break rule is stated where it is applied
from collections import Counter

def domain_of(email: str) -> str:
    return email.rsplit("@", 1)[1]

def top_domains(emails: list[str], limit: int = 3) -> list[tuple[str, int]]:
    counts = Counter(domain_of(e) for e in emails)
    # most frequent first; equal counts ordered alphabetically so the result is deterministic
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:limit]
```

For well-formed addresses (exactly one `@`) the two versions return the same list; the first also scans the list once per distinct domain.

## Anti-patterns

- **One-line wonder.** A dense expression that needs a debugger to read. Detect: a line wider than the screen with nested lambdas, or a ternary inside a ternary.
- **Copy-paste divergence.** Two copies of a rule where only one was fixed. Detect: nearly identical blocks in different files.
- **Flag accretion.** Boolean options added one per requirement. Detect: a routine with three or more booleans that interact (Added judgment: a search aid, not a limit).
- **Relocated complexity.** Logic pushed into a `Helper` whose name explains nothing. Detect: a new routine you cannot name without "process" or "handle".
- **Premature shared abstraction.** A generic routine with parameters for each caller's differences. Detect: its parameter list is the union of its callers' needs.

## Trade-offs and exceptions

- Duplication across modules that evolve independently is often cheaper than coupling them; the source asks to remove duplication that multiplies maintenance effort, not all repetition.
- A compact idiom that the whole team knows (a comprehension, a pipeline) is not clever for that team; the test is the reader's effort, not the line count.
- Sometimes complexity belongs to the problem, not the code. Then name it and contain it in one place rather than spreading it.
- Performance code may be denser by necessity; the source allows it only when the trade-off is explicit and measured (`/code-complete:performance-tuning`).

## Verification

- [ ] A colleague could explain the changed code after one read.
- [ ] Each business rule or constant exists in one place.
- [ ] No expression packs several steps that a reader must unpack.
- [ ] The change did not add a flag or special case where a named concept or table would do.
- [ ] The tests passed before and after.

## Related

`/code-complete:control-flow` for branches; `/code-complete:routine-design` and `/code-complete:class-design` for splitting; `/code-complete:table-driven` for special-case growth; `/code-complete:refactoring-judgment` for how to change structure safely; `code-complete:complexity-reviewer` to review a diff.

## Source

- `Complexity Management Rules`
- `Foundational Construction Rules`
- `Primary Directive`
- `Cleverness over Clarity`
- `Review Rules`: only the item on duplicated logic.
