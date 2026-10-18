---
name: "data-types"
description: "Use when a value's meaning must be decoded: magic numbers, sentinels like -1, units, boolean flags, status strings, parallel arrays. Choose types and constants. Variable lifetime: $code-complete:variables. Flag parameters in a signature: $code-complete:routine-interface."
---

# Data types and data meaning

Decides how a value is represented so that invalid or ambiguous values are hard to express and a reader never has to decode it: types, named constants, units, closed sets, container shapes. How long a variable lives and where it is declared is `$code-complete:variables`; a boolean or magic parameter in a signature is `$code-complete:routine-interface`.

## When to use

- A literal number or string in an expression carries business meaning (`if (status == 3)`, `* 86400`).
- A value uses a sentinel (`-1`, `""`, `null`, `9999-12-31`) to mean something else.
- A name or type hides its unit, range, precision, encoding or owner (`timeout`, `size`, `price`).
- A boolean field has a third situation, or several booleans combine into states.
- Strings are compared against literals for a closed set of alternatives.
- Parallel arrays or positional tuples are passed around.

## Rules

1. **Choose data types that make invalid or ambiguous values harder to represent.** Why: what the type forbids needs no defensive check. Check: for each field ask what invalid value it can hold; if the answer is "many", tighten the type.
2. **Name constants for magic values, units, bounds and sentinel meanings; avoid magic numbers and unexplained sentinel values.** Why: a named constant is searchable and explains itself. Check: no bare literal with business meaning appears in an expression you touched, and `-1`, `0`, `""` and `null` do not stand for "none", "unlimited" or "failed" without a name or a type that says so.
3. **Use booleans only for true binary meanings; replace flag fields with clearer states when needed.** Why: a boolean that grows a third case becomes two booleans with an illegal combination. Check: no pair of booleans has a combination that must never occur.
4. **Use enumerations or named alternatives when a value belongs to a closed set.** Check: no string or integer is compared against a literal to select among a fixed list.
5. **Use arrays, records, maps and tables only where their shape communicates the data meaning.** Check: parallel arrays are one array of records; a tuple passed through several routines has a named type.
6. **Encapsulate unusual data structures behind routines or types that reveal purpose.** Check: callers do not manipulate raw index arithmetic or bit masks.
7. **Keep units, ranges, precision, encoding and ownership visible near the data they affect.** Check: the name, type or documentation says milliseconds or cents, inclusive or exclusive bounds, UTF-8 or bytes, who frees or mutates it.
8. **Use stronger data types when primitives hide meaning.** Rule shared with the variable section of the source. Added judgment: wrap a primitive when two kinds of it can be confused or its rules recur (an id, an amount, a duration); do not wrap every string.
9. Added judgment: exempt trivial literals that carry no business meaning (`0` as a start index, `1` as an increment, `2` in a halving) from rule 2; naming them adds noise.
10. Added judgment: when the language has no sum type or enum, a small set of named constants plus a validating constructor gives most of the benefit.

## Procedure

1. Scan the changed code for literals, sentinels, boolean flags, string comparisons and tuples.
2. For each, write what it means in a sentence, including the unit and the range. If you cannot, find out before changing it.
3. Pick the representation: named constant, enum, wrapper type, record, or an absence type (optional) instead of a sentinel.
4. Introduce it at the point where the data enters the code, then thread it inward; migrate callers in small steps with tests after each.
5. Move validation into the type's constructor so that an existing value is valid (`$code-complete:assertions-and-contracts`).
6. Rename anything whose unit is still invisible.

## Example

```ts
// Before: -1 means unlimited, the unit of `window` is invisible, `plan` is a free string
const config = { plan: "pro", apiQuota: -1, window: 60 };
function canCall(c: typeof config, used: number): boolean {
  return c.apiQuota === -1 || used < c.apiQuota;
}

// After: the sentinel and the unit become part of the type; 0 now simply means "no calls"
type PlanName = "free" | "pro" | "enterprise";
type Quota = { kind: "unlimited" } | { kind: "limited"; callsPerWindow: number };

interface PlanLimits {
  plan: PlanName;
  quota: Quota;
  windowSeconds: number;
}

const config: PlanLimits = { plan: "pro", quota: { kind: "unlimited" }, windowSeconds: 60 };

function canCall(limits: PlanLimits, used: number): boolean {
  return limits.quota.kind === "unlimited" || used < limits.quota.callsPerWindow;
}
```

## Anti-patterns

- **Magic number.** `retries > 3`, `* 86400`. Detect: a numeric literal in a condition or arithmetic whose meaning is not in the line.
- **Sentinel return.** `-1` for "not found". Detect: callers compare with a literal before using the value.
- **Boolean pair.** `isActive` and `isSuspended`. Detect: a combination of flags that must not occur; replace with a state type.
- **Stringly typed set.** `if (kind === "refund")`. Detect: string literals compared in several places; a typo compiles.
- **Unit-less quantity.** `timeout = 30`. Detect: nothing in the name or type says seconds or milliseconds.
- **Parallel arrays.** `names[i]` and `ages[i]`. Detect: loops indexing two or more arrays with the same index.

## Trade-offs and exceptions

- The source asks for named constants for meaningful values; constants for every literal is noise. Keep the exemption in rule 9 and let the repository's style decide the edge cases.
- Wrapper types cost allocation and ceremony. In a hot path or a language without cheap wrappers, a documented alias plus a validating constructor may be the right size.
- Booleans are fine when the meaning is binary and will stay so (`enabled`); the rule is to replace them when a third case appears.
- Existing persisted or wire formats may require the sentinel; keep it at the boundary and convert to the clearer type on entry (`$code-complete:trust-boundaries`).

## Verification

- [ ] No bare literal with business meaning remains in the touched expressions.
- [ ] No sentinel stands for "none", "unlimited" or "failed" without a name or an absence type.
- [ ] No combination of booleans has an invalid state.
- [ ] Closed sets are enums or named alternatives, not string comparisons.
- [ ] Units, ranges and precision are visible in names or types.
- [ ] Tests cover the boundary values of the new type.

## Related

`$code-complete:variables` for scope and reuse; `$code-complete:routine-interface` for flag and magic parameters; `$code-complete:table-driven` when a closed set drives branching; `$code-complete:trust-boundaries` for converting external representations on entry; `code-complete-data-reviewer` to review a diff.

## Source

- `Data Type Rules`
- `Variable and Data Rules`: only the rules on named constants, magic numbers and stronger types.
