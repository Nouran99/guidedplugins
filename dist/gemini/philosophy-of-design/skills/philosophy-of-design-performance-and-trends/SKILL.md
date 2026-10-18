---
name: "philosophy-of-design-performance-and-trends"
description: "Use when asked to optimize, when a cache or micro-optimization is proposed, or when a pattern, paradigm, framework or fashionable technique is about to be adopted. Requires evidence and hides optimizations behind stable interfaces."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Performance and trends

Judges added complexity that claims a benefit: speed, scalability, or "modern practice". It asks for evidence, and for the added complexity to stay behind a stable interface. Layers that claim no benefit at all are `philosophy-of-design-pass-through-layers`; test coupling is `philosophy-of-design-testing-through-interfaces`.

## When to use

- Someone proposes caching, batching, pooling or a hand-tuned loop.
- A change widens an interface "for performance".
- A pattern, framework, paradigm or technique is proposed because it is current.
- A review asks "do we know this is slow?"

## Rules

1. **Do not sacrifice module depth or information hiding for performance without evidence that the tradeoff matters.** Check: a measurement or profile accompanies the change, not an assumption.
2. **When performance matters, hide optimization details behind stable interfaces so callers do not inherit the complexity.** Check: callers do not pass hints, buffers or pre-sorted inputs to get the fast path.
3. **Prefer measurements and targeted changes over broad speculative tuning.** Check: the change touches the measured hot spot, not every similar function.
4. **Do not adopt a trend, paradigm, pattern or framework unless it reduces complexity in this codebase.** Check: you can name the files or callers that become simpler.
5. **Measure first.** Compact checklist rule: this wording comes from `../philosophy-of-design-principles/references/mini.md`; `full.md` states it as rules 1 and 3 above. Check: the baseline is recorded before the change and compared after.
6. **Keep the common path simple when adding an optimization or an exception path.** Compact checklist rule: it comes from `../philosophy-of-design-principles/references/nano.md` and `../philosophy-of-design-principles/references/mini.md`, not from a section of `full.md`. Check: the typical call reads the same as before.
7. **Keep performance hacks out of the callers' dependencies.** Callers should not depend on implementation detail or performance tricks (the fourth rule under `Information Hiding Rules`). Check: no caller code mentions the optimization.
8. **Added judgment: state the budget and who set it.** Check: the change names the number that matters (latency, memory, cost) and why that number matters to a user or an operator.
9. **Added judgment: keep the evidence next to the code.** Put the measurement in a benchmark or in the pull-request text, and put only the stable invariant in a comment. Numbers in comments rot.
10. **Added judgment: ask of any adoption, "which concrete complexity does this remove here?"** If the answer is only "it is the standard approach", the adoption has no evidence yet.

## Procedure

1. Write the claim: "X is slow/too large/hard to scale" or "pattern P will simplify Y".
2. Obtain evidence: a benchmark, profile or production metric for performance claims; a list of simplified callers for adoption claims.
3. If there is no evidence, stop and say what would be needed. If the evidence shows the cost does not matter, leave the design alone.
4. Place the optimization behind the existing interface; keep the signature stable.
5. Re-measure after the change and record both numbers.
6. Check that callers did not change, and that the common path did not get harder to read.

## Example

```python
# Before: the optimization is the caller's problem
def is_blocked(ip, blocked):
    # `blocked` should be a set; a list works but scans linearly
    return ip in blocked

blocked = set(load_blocklist())          # every caller must remember to do this
if is_blocked(request.ip, blocked): ...

# After: the module chooses the representation; callers see one concept
class Blocklist:
    """Addresses that must be refused. Lookups are exact string matches."""
    def __init__(self, addresses):
        # A frozenset was chosen after a measurement (see bench/blocklist_bench.py).
        self._addresses = frozenset(addresses)

    def contains(self, ip):
        return ip in self._addresses

blocklist = Blocklist(load_blocklist())
if blocklist.contains(request.ip): ...
```

```text
Proposal: put an event bus between OrderService and InventoryService.
Complexity removed in this codebase: none named. Callers simplified: 0 of 1. Evidence: none.
Decision: do not adopt yet. Revisit when a second consumer exists and its callers can be listed.
```

## Anti-patterns

- **Speculative tuning.** An optimization with no measurement. Detect: "should be faster" in the description.
- **Leaky fast path.** Callers pass hints or pre-sorted data to get speed. Detect: parameters named `fast`, `presorted`, `unsafe`.
- **Resume-driven adoption.** A pattern or framework added to be current. Detect: the change adds concepts and removes none.
- **Broad tuning.** Rewriting many functions after profiling one. Detect: a diff much larger than the hot spot.
- **Cargo-cult caching.** A cache without an invalidation story. Detect: no statement of what makes an entry stale.

## Trade-offs and exceptions

- When performance is the product requirement (a latency budget, an embedded device), the evidence bar is met by the requirement and a measurement; the optimization still hides behind the interface (Added judgment).
- Some optimizations must be visible in the interface because callers control the cost (streaming versus buffering). Expose them as semantic choices, not mechanisms (Added judgment).
- Following an established framework convention in an existing code base is not "adoption"; the rule targets new additions (Added judgment).
- Reliability mechanisms such as timeouts and retries are a production-failure concern outside this rule set; use a release-engineering plugin for their policy.

## Verification

- [ ] A baseline and a post-change measurement exist for each performance claim.
- [ ] The public signature did not change to carry the optimization.
- [ ] Each adopted pattern or framework lists the callers that became simpler.
- [ ] The common path reads as before.
- [ ] No comment holds a number that will go stale.

## Related

`philosophy-of-design-pass-through-layers`; `philosophy-of-design-information-hiding`; `philosophy-of-design-strategic-programming`; `philosophy-of-design-evidence-reviewer` to review.

## Source

- `Performance, Trends, and Tests`: the rules on performance evidence and on adopting trends, patterns and frameworks.
- `Information Hiding Rules`: only the rule that callers must not depend on performance hacks (rule 7).
