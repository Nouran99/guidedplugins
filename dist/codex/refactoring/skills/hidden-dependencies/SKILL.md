---
name: "hidden-dependencies"
description: "Use when code reads globals, singletons, the clock, environment, config or ambient request context, or a function has side effects its name hides. What code reads from outside its signature; who may write shared state is mutation-control."
---

# Hidden dependencies

Code that needs something it does not declare is hard to change safely: you cannot see what it depends on, and you cannot run it in isolation. This skill makes those inputs explicit and isolates side effects. Who is allowed to write shared state is `$refactoring:mutation-control`; the shape of the parameter list that results is `$refactoring:call-signatures`.

## When to use

- A function calls the clock, a random source, an environment variable, a settings module or a singleton in its body.
- A test must set global state or monkeypatch to exercise a function.
- A function named like a query (`get`, `is`, `find`) writes, logs, sends or caches something.
- Changing code requires knowing much more of the system than the code shows.

## Rules

1. **Reduce reliance on globals, singletons and ambient context.** Check: the function's behavior can be explained from its arguments and its own object.
2. **Make dependencies explicit where possible.** Check: each input the function reads appears as a parameter, a constructor argument or a field set at creation.
3. **Refactor toward injection, parameters or clear ownership (not toward a new ambient mechanism).** Check: you did not replace one global with a service locator or a context object that holds everything.
4. **Remove hidden side effects unless the function's purpose is to cause them.** Check: the name, return type and documentation of the function admit every effect it performs.
5. **Isolate side effects from computation.** Move the effectful call to the edge so the core is a pure calculation where practical. Check: the computing function can be called in a test without any setup beyond its arguments.
6. **Look for code that requires too much context to change safely and treat it as a review signal; fix what blocks the requested change.** Check: list what you had to read elsewhere to understand the function; each item is a candidate hidden input.
7. **Added judgment: classify the hidden input before fixing it.** Clock, randomness, environment or config, global registry, singleton or static mutable, thread-local or request context, filesystem or network, process state. Check: each hidden input has a category and a planned explicit form.
8. **Added judgment: take the smallest first step.** Add the input as a parameter whose default preserves the old behavior, migrate callers, then remove the default. For a value the callee should own, move it behind the object that owns it. Check: after the first step no caller had to change.
9. **Added judgment: do not use a mutable default to carry a hidden input.** A default evaluated once at definition time (for example `now=datetime.now()` as a Python default) freezes the value. Use a sentinel and resolve it at call time, or require the argument. Check: the default is a sentinel, not a computed value.
10. **Added judgment: keep ambient lookups at the edges.** Entry points (handlers, `main`, job runners) may read the environment and the clock and pass the values inward. Check: the number of places that read each ambient source is small and at the boundary.

## Procedure

1. Read the function and list everything it reads or does beyond its arguments and return value.
2. Classify each (rule 7). Mark which are effects and which are inputs.
3. Pick the first input; add it as a parameter, keeping the old behavior for existing callers; run tests.
4. Migrate callers; the edge supplies the ambient value. Remove the compatibility default.
5. Move effects to the edge or name them honestly.
6. Repeat; stop when the function can be understood and tested from its signature.

## Example

```python
# Before: depends on the clock and a settings global; hard to test, hard to reason about
def is_trial_expired(account):
    return datetime.now(timezone.utc) > account.trial_ends_at + timedelta(days=settings.TRIAL_GRACE_DAYS)

# After: the inputs are in the signature; the edge supplies the ambient values
def is_trial_expired(account, now, grace_days):
    return now > account.trial_ends_at + timedelta(days=grace_days)

# handler (edge)
expired = is_trial_expired(account, datetime.now(timezone.utc), settings.TRIAL_GRACE_DAYS)

# test: no patching
def test_trial_expires_after_grace():
    account = Account(trial_ends_at=datetime(2025, 1, 10, tzinfo=timezone.utc))
    assert is_trial_expired(account, datetime(2025, 1, 18, tzinfo=timezone.utc), 7)
    assert not is_trial_expired(account, datetime(2025, 1, 16, tzinfo=timezone.utc), 7)
```

The function computes the same value as before for the same inputs; only where the inputs come from has moved.

## Anti-patterns

- **Service locator.** Detect: a `get_service("x")` call replacing a singleton access. Treat: pass the dependency instead.
- **God context.** Detect: one object that carries everything and is passed everywhere. Treat: pass only what each function needs.
- **Query with an effect.** Detect: a read-named function that writes, logs or sends. Treat: split the effect out or rename the function to say what it does.
- **Frozen default.** Detect: a default argument that calls the clock or reads config at import time. Treat: sentinel resolved at call time.
- **Test that patches the world.** Detect: heavy patching in tests to set ambient state. Treat: inject the value.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- A function whose purpose is to cause an effect (send mail, write a file) may keep the effect; make it named and obvious.
- A small program or script may legitimately read config at the top; the rule is about code that is hard to change safely, not about every `os.environ` access. (Added judgment)
- Dependency injection frameworks are not required; plain parameters and constructors are the first choice (Added judgment).
- Changing where a value is read can change behavior (for example reading config once at startup versus per call); keep the old timing unless you decide otherwise (`$refactoring:behavior-preservation`). (Added judgment)

## Verification

- [ ] The function's inputs are all visible in its signature or its constructor.
- [ ] Hidden side effects are removed, isolated at the edge, or named honestly.
- [ ] No ambient mechanism replaced another.
- [ ] Reading time or evaluation count of each ambient value is unchanged.
- [ ] A test can call the function with no global setup.

## Related

`$refactoring:mutation-control` for writes to shared state; `$refactoring:call-signatures` for the resulting parameter list; `$refactoring:ownership` for clear ownership of a value; `refactoring-dependency-reviewer` to inventory hidden inputs in a diff.

## Source

- `Global Data and Hidden Dependencies`
- `Function-Level Rules`: only the rule on hidden side effects.
- `Review Rules`: only the hidden side effects, global state reliance and code-needs-too-much-context items.
- `Code Generation Rules`: only the first move to isolate side effects.
