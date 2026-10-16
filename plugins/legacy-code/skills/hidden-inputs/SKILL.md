---
name: hidden-inputs
description: "Use when a test is not repeatable because code reads the clock, random numbers, environment variables, thread-local state or the implicit current user or request. Your own static singletons and global config are `static-and-global`; outgoing effects are `hard-outputs`."
---

# Hidden inputs

A hidden input is a value the code reads from its surroundings instead of receiving. A test cannot control it, so a test cannot repeat. This skill makes those values explicit. Static singletons and global configuration appear in the same upstream list but are handled by `/legacy-code:static-and-global`; what the code does to the outside world is `/legacy-code:hard-outputs`.

## When to use

- A test passes today and fails after midnight, in another time zone or on another machine.
- Output depends on a random value or on an environment variable set in a shell.
- Code reads "the current user" or "the current request" from thread-local or ambient state deep inside logic.
- You want to characterize a function and its result changes between runs.

## Rules

1. **When legacy code is hard to test, look for hidden inputs: current time, random values, environment variables, thread-local state, static singletons, global configuration and the implicit current user or request.** [MUST] The source lists hidden inputs, hard outputs and construction problems as three peer categories to look for; this skill owns the first. Check: you searched the code under test for each kind and listed what you found.
2. **Inject clocks, random generators, external interfaces and hard collaborators.** [MUST] Check: a test supplies its own clock or generator and does not depend on the real one.
3. **Remove direct dependence on time, randomness, files, network, process environment, globals, frameworks and static construction where they block testing.** [MUST] The qualifier matters: leave a clock call alone if no test needs to control it. Check: each input you changed blocked a test you needed.
4. **Do not add more ambient context in code that is already hard to test.** [MUST NOT] Check: the diff adds no new clock call, environment read, thread-local lookup or global read inside logic.
5. **Hand static singletons and global configuration to `/legacy-code:static-and-global`.** [Added judgment] The fix for those is a wrapper and caller migration, not a value parameter. Check: no singleton is "fixed" here by passing a value that leaves the singleton in place.
6. **Read the value once, at the edge, and pass it down.** [Added judgment] Check: the clock, environment or ambient lookup appears in one entry function, not at several depths.
7. **Pass a value when one reading is enough; inject a source when the code reads repeatedly or must advance.** [Added judgment] A `now` argument is the smallest form; a clock object is for loops, retries and timeouts. Check: a function that reads time twice does not take two unrelated `now` values by accident.
8. **Randomness: accept the generator, or a seed, and let the caller choose.** [Added judgment] Check: a test can supply a fixed sequence and assert on the exact outcome.
9. **Environment variables and configuration: convert to a plain value at the composition edge and pass the value.** [Added judgment] Check: logic code never calls `getenv`; only wiring does.
10. **Ambient user or request: pass an explicit context at the entry point.** [Added judgment] Keep the ambient lookup in the one adapter that fills the context. Check: no function below the entry point imports the request or user lookup.
11. **Keep production behavior the default.** [Added judgment] The edge supplies the real clock, generator or variable, so existing callers do not change. Check: every legacy call site still compiles and behaves as before, or each is migrated in a separate step.
12. **Pin first when you can; when the input itself stops every repeatable pin, inject conservatively first and pin straight after.** [Added judgment] Conservative means the signature is kept, the real source is the default and only the one read changes. Check: either the pins exist before the injection, or the injection changes no result for existing callers and the pin is the next step.

## Procedure

1. Search the code under test: `now(`, `Date.now`, `time.time`, `Math.random`, `random.`, `getenv`, `process.env`, thread-local accessors, request or user lookups. List each with its location.
2. For each, decide whether a test you need is blocked. Leave the rest.
3. Choose the form from rules 6 to 10 and add the parameter or collaborator, defaulting to the real source at the edge.
4. Update the one place that supplies the default; keep legacy callers working.
5. Write the repeatable test with a supplied value. Run all tests.
6. Report inputs found but left alone, and why.

## Example

```python
# Before: two hidden inputs, the clock and an environment variable
import os
from datetime import datetime, timezone

def trial_banner(user):
    days_left = (user.trial_ends - datetime.now(timezone.utc)).days
    if os.environ.get("PROMO_MODE") == "1" and days_left <= 3:
        return "Last days: upgrade at half price"
    if days_left <= 0:
        return "Your trial has ended"
    return f"{days_left} days left"
```

```python
# After: both are inputs with the old behavior as the default
def trial_banner(user, now=None, promo_mode=None):
    if now is None:
        now = datetime.now(timezone.utc)
    if promo_mode is None:
        promo_mode = os.environ.get("PROMO_MODE") == "1"
    days_left = (user.trial_ends - now).days
    if promo_mode and days_left <= 3:
        return "Last days: upgrade at half price"
    if days_left <= 0:
        return "Your trial has ended"
    return f"{days_left} days left"
```

```python
# tests/test_trial_banner.py
from datetime import datetime, timezone
from types import SimpleNamespace

from billing.banners import trial_banner

ENDS = SimpleNamespace(trial_ends=datetime(2025, 3, 10, tzinfo=timezone.utc))

def test_days_left_is_counted_from_the_supplied_time():
    now = datetime(2025, 3, 1, tzinfo=timezone.utc)
    assert trial_banner(ENDS, now=now, promo_mode=False) == "9 days left"

def test_ended_trial_without_promo():
    now = datetime(2025, 3, 12, tzinfo=timezone.utc)
    assert trial_banner(ENDS, now=now, promo_mode=False) == "Your trial has ended"

def test_promo_mode_wins_even_after_the_trial_ended():
    # CHARACTERIZATION: unclear if intended; preserved from the legacy code.
    now = datetime(2025, 3, 12, tzinfo=timezone.utc)
    assert trial_banner(ENDS, now=now, promo_mode=True) == "Last days: upgrade at half price"
```

The last test pins an odd legacy result instead of fixing it. Existing callers `trial_banner(user)` behave exactly as before.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Clock below the entry point | `now()` inside a helper three calls deep | Read at the edge, pass down |
| Mock-the-clock-globally | A patch of the time module for the whole test run | Inject the value or a clock object |
| Seedless randomness | `random` calls with no way for the caller to choose | Accept the generator |
| Env read in logic | `getenv` inside a rule | Convert at wiring |
| Ambient context spread | Another function reads the request lookup | Pass the context |
| Breaking inputs nobody tests | Parameters added for values no test needs | Revert; the qualifier is "where they block testing" |

## Trade-offs and exceptions

- The source asks to break these only where they block testing; do not thread a clock through code no test touches.
- Added judgment: a global patch of the time module can be an acceptable stopgap in a language where nothing else is possible; mark it as a last-resort seam (`/legacy-code:last-resort-seams`).
- Thread-local state may be required by a framework; keep the lookup in the framework-facing adapter.

## Verification

- [ ] Every hidden input found is listed, changed or consciously left.
- [ ] A test supplies its own value and is repeatable.
- [ ] The real source is the default at the edge.
- [ ] No new ambient read was added inside logic.
- [ ] Legacy callers behave as before.
- [ ] Singletons and globals were handed to the right skill.

## Related

`legacy-code:hidden-input-reviewer` to review a diff; `legacy-code:boundary-wrapper` to build the clock, generator or environment collaborator; `/legacy-code:characterization-tests` for pinning; `/legacy-code:static-and-global` for singletons; `/legacy-code:seams` for classifying the seam.

## Source

- `Hidden Inputs`
- `Dependency Breaking Rules`
- `Required Moves`: only the rule to inject clocks, random generators, external interfaces and hard collaborators.
- `Non-Negotiable Rules`: only the rule to break dependencies deliberately.
- `Hidden Dependency Expansion`: only the rule not to add ambient context in hard-to-test code.
- `Default Workflow for Legacy Changes`: only the steps on characterizing where possible and then breaking the blocking dependency.
