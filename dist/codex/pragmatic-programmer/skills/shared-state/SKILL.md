---
name: "shared-state"
description: "Use when state is mutable and shared (globals, singletons, caches, ambient context, thread-locals), when adding threads, async tasks or locks, or a function reads hidden context. Layering is `orthogonality`; blackboards and call order are `$pragmatic-programmer:shy-code`; releasing locks is `$pragmatic-programmer:resource-discipline`."
---

# Shared state and concurrency

Shared mutable state is expensive: every reader and writer must agree on rules that the code rarely states. This skill decides whether state should be shared, who owns it, and how its rules are made visible. Module boundaries and responsibilities are `$pragmatic-programmer:orthogonality`; releasing locks and other resources is `$pragmatic-programmer:resource-discipline`.

## When to use

- A module-level variable, singleton, cache or registry is written by one part of the code and read by another.
- A function reads configuration, the current user, a clock or a request from ambient context (thread-local, context variable, global) instead of its parameters.
- You are adding threads, async tasks, locks or callbacks.
- Intermittent failures suggest ordering or visibility problems.

## Rules

1. **Treat shared mutable state as expensive.** [MUST] Check: for every piece of shared mutable state you can say why it is shared and what it costs the readers.
2. **Prefer immutability, isolation or explicit synchronization when state is shared.** [SHOULD] Added judgment on the order to try: immutable values first, then state owned by one task or thread, then a guarded structure. Check: the option chosen is the cheapest that is correct.
3. **Keep concurrency assumptions visible.** [MUST] Check: next to each shared field a comment or type says who writes it, who reads it and what guards it.
4. **Do not add asynchronous complexity unless it clearly earns its cost.** [MUST NOT] Check: you can state the benefit (a measured wait you must overlap, a real parallel workload) that justifies the extra states and failure modes.
5. **Minimize hidden couplings through globals, ambient context and shared mutable state.** [MUST] Check: a function's inputs are visible in its signature, apart from stable, documented process-wide configuration.
6. **When shared state, async behavior, locks, ordering or temporal coupling appear, make ownership, synchronization, cleanup and ordering explicit.** [Compact checklist] Check: all four are stated for the construct you added.
7. **Pass context explicitly.** [Added judgment] Hand the clock, the user or the configuration to the function instead of reaching for it. Check: a test can run the function with its own values and no global setup.
8. **Inventory shared state.** [Added judgment] For each item list the writers, the readers and the guard. Check: any item with two writers and no guard is a finding.
9. **Treat caches and derived values as shared state.** [Added judgment] Someone must invalidate them. Check: each cache names its invalidation rule.
10. **Do not hold a lock across a call you do not control.** [Added judgment] Check: lock scopes contain only the shared-state access.
11. **Publish immutable snapshots rather than mutating in place.** [Added judgment] Build the new value off to the side and swap one reference under the guard. Check: readers never see a half-updated value.

## Procedure

1. List shared mutable state in the touched code: module-level mutables, singletons, caches, static fields, thread-locals, context variables, environment reads deep in functions.
2. For each, write the inventory row: writers, readers, guard, invalidation.
3. Choose the cheapest safe option: make it immutable, give it one owner, pass it in, or guard it.
4. For anything asynchronous, state the benefit that earns its cost, or remove it.
5. Write the assumption beside the state.
6. Add a test that exercises two writers or a reader during a write, if the language makes that testable.

## Example

```python
# Before: a module-level dict mutated by a refresh thread and read by request handlers
_rates = {}

def refresh_rates():                      # runs in a background thread
    _rates.clear()
    _rates.update(fetch_rates())          # a handler can read between clear() and update()

def convert(amount, currency):
    return amount * _rates[currency]      # KeyError for a moment after every refresh
```

```python
# After: one owner, one writer, readers always see a complete snapshot
class RateBook:
    """Latest exchange rates. Writer: the refresh thread only (replace). Readers: any thread (get)."""

    def __init__(self):
        self._lock = threading.Lock()
        self._rates = {}

    def replace(self, new_rates):
        snapshot = dict(new_rates)         # built outside the lock
        with self._lock:
            self._rates = snapshot         # swap in one step

    def get(self, currency):
        with self._lock:
            return self._rates[currency]

def convert(amount, currency, rates: RateBook):    # the dependency is visible in the signature
    return amount * rates.get(currency)
```

The guard, the writer and the readers are stated in the class, handlers never observe an empty table, and tests pass their own `RateBook`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Mutable global | Module-level `dict`, `list` or object that functions modify | Own it in a class, pass it in |
| Ambient read | A function that calls `current_user()` or reads an env var deep inside | Pass the value as a parameter |
| Unguarded cache | A cache with several writers and no lock or invalidation rule | Guard it and name the invalidation |
| Singleton with state | A singleton holding mutable fields used across features | Inject an owned instance |
| Async for its own sake | Tasks or threads added with no stated benefit | Remove, or state the benefit |
| Lock around a call out | A lock held while calling another system | Copy what you need, release, then call |
| Half-published update | Clear-then-fill of a shared collection | Build a new value and swap |

## Trade-offs and exceptions

- The source treats shared mutable state as expensive, not forbidden. Some state is inherently shared (a connection pool, a metrics registry); make it explicit and owned.
- Stable process-wide configuration read at startup is a mild form of ambient context. Added judgment: acceptable when it is read once, validated, and not mutated afterward.
- Language runtimes differ in what is atomic. Do not rely on a specific interpreter's guarantees for correctness unless the code says so.
- Deep treatment of concurrency models (actors, STM, memory models) is outside this book's rules; use this skill to decide whether to share and to make the assumptions visible.

## Verification

- [ ] Every shared mutable item in the change has a stated owner, writers, readers and guard.
- [ ] No function in the change reads hidden context it could receive as a parameter.
- [ ] Any asynchronous construct added has a stated benefit.
- [ ] No lock is held across a call to code you do not control.
- [ ] A test exercises the state with its own instance rather than a global.

## Related

`pragmatic-programmer-shared-state-reviewer` to review a diff; `$pragmatic-programmer:orthogonality` for responsibilities and layering; `$pragmatic-programmer:shy-code` for blackboards and call order; `$pragmatic-programmer:resource-discipline` for lock release.

## Source

- `State and Concurrency Rules`
- `Orthogonality Rules`: only the rule to minimize hidden couplings through globals, ambient context and shared mutable state.
