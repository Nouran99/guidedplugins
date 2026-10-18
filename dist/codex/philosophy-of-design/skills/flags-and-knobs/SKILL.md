---
name: "flags-and-knobs"
description: "Use when the signature itself has a boolean or mode parameter that switches behavior, an options bag that keeps growing, or a callback added so one caller can override a step. Decides inside or splits by intent. Not for lines repeated at call sites."
---

# Flags and knobs

Judges parameters and options that make callers choose a behavior. Whether the whole element is well shaped is `$philosophy-of-design:interface-design`; required call order is `$philosophy-of-design:temporal-decomposition`; pushing repeated caller work into the callee is `$philosophy-of-design:pull-complexity-down`.

## When to use

- A signature has a `bool`, an enum or a string that picks between two bodies.
- Call sites contain bare `true`/`false` or `"fast"`/`"safe"` literals.
- A change request is solved by "just add an option" or "pass a callback".
- An options object has grown each release and nobody sets half of it.

## Rules

1. **Treat boolean and mode parameters that switch internal behavior as a warning, usually forbidden.** Check: the first lines of the body branch on the parameter, or call sites pass literals.
2. **Do not add one more flag, callback or conditional instead of improving the abstraction.** Check: the diff adds a parameter whose only caller is the one being fixed.
3. **Treat many configuration flags as a warning.** Check: compare the number of options a typical caller must understand with the number any caller sets.
4. **Decide inside when the module already has the information.** Input size, type, environment and history are known to the callee. Check: for each flag, name the caller who knows something the module does not; if nobody does, remove the flag.
5. **Split by intent when callers want different outcomes.** Two operations, each named for its outcome, beat one operation with a switch. Check: each has its own one-sentence contract and neither needs the other's parameters.
6. **Eliminate arguments that only exist to expose an internal implementation choice.** Algorithm names, buffer sizes, index hints. Check: if the implementation changed, the argument would be meaningless.
7. **Keep the rare control named, optional and out of the common path.** Check: the typical call passes no options at all.
8. **Do not push complexity outward through flags, setup steps and coupled operations.** Check: removing the flag does not just move the work into every caller.
9. **Added judgment: a callback parameter is a flag that carries code.** A hook that lets callers override a step needs the same justification as a flag (a real caller-specific variation), and the module keeps the default behavior.
10. **Added judgment: keep an option only if some real caller sets it, for a reason that can be stated in domain terms.** Check: grep the call sites for non-default values.

## Procedure

1. List every parameter and option and classify it: selects behavior, exposes mechanism, carries caller data, or states a real preference.
2. For selectors, find every call site (search for the literal values) and group callers by what they want.
3. Choose for each selector: decide inside, split into named operations, or keep as a named optional parameter.
4. Introduce the new operations; migrate callers one at a time; delete the flag; update the contract comment and tests.
5. If the old signature is public, keep it as a thin deprecated shim until callers have moved.

## Example

```python
import time

# Before: four parameters, three of them choosing how the function behaves
def fetch_report(report_id, use_cache=True, refresh=False, raw=False, fmt="json"):
    if refresh:
        use_cache = False
    data = _cache.get(report_id) if use_cache else None
    if data is None:
        data = _build(report_id)
        _cache[report_id] = data
    if raw:
        return data
    return _to_json(data) if fmt == "json" else _to_csv(data)

# After: freshness is decided inside; rebuilding is its own operation; formats are methods
FRESH_SECONDS = 60
_cache = {}   # report_id -> (built_at, Report)

def get_report(report_id):
    """Current report, at most FRESH_SECONDS old."""
    hit = _cache.get(report_id)
    if hit and time.monotonic() - hit[0] < FRESH_SECONDS:
        return hit[1]
    return rebuild_report(report_id)

def rebuild_report(report_id):
    """Recompute the report now and replace the cached copy."""
    report = _build(report_id)
    _cache[report_id] = (time.monotonic(), report)
    return report

# Report.as_json() and Report.as_csv() replace the raw/fmt switches.
```

Callers say what they want (`get_report(id).as_csv()`, `rebuild_report(id)`) instead of how the function should behave.

## Anti-patterns

- **Boolean trap.** `render(doc, true, false)`. Detect: literals at call sites that need the signature open to decode.
- **Growing options bag.** A config object that gains a field per request. Detect: fields that no caller sets.
- **Escape-hatch callback.** A hook added so one caller can bypass a step. Detect: a callback parameter with one non-default user.
- **Legacy-mode flag.** A switch kept for a migration that ended. Detect: every call site passes the same value.
- **Mechanism option.** `use_hash_index=True`. Detect: the name describes how, not what.

## Trade-offs and exceptions

- The source calls these signs warnings that are usually forbidden. A single option that callers can choose in their own terms (a time zone, a locale, a limit) is a real parameter, not a mode switch.
- User-facing product options (a CLI `--verbose`) are features, not internal mode switches; this skill is about module and library interfaces (Added judgment).
- When two operations share heavy logic, keep one private core and make both public operations thin over it; do not duplicate the logic.
- Removing a public flag breaks callers; add the new operations first and deprecate.

## Verification

- [ ] No touched public signature has a boolean or mode parameter that picks a behavior.
- [ ] Call sites read as intent (names), not as literals.
- [ ] Every remaining option is set to a non-default value by at least one real caller.
- [ ] The common call passes no options.
- [ ] The contract comment no longer explains flag combinations.

## Related

`$philosophy-of-design:interface-design`; `$philosophy-of-design:pull-complexity-down`; `$philosophy-of-design:strategic-programming` for the "just add a flag" reflex; `philosophy-of-design-interface-reviewer` to review; `philosophy-of-design-interface-simplifier` to rework.

## Source

- `Interface Design Rules`
- `Tactical Complexity Debt`
- `Pull Complexity Downward`: only the rule against pushing complexity outward through flags and setup steps.
