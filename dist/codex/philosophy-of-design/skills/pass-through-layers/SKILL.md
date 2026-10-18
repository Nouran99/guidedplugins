---
name: "pass-through-layers"
description: "Use when a class, service, facade, adapter or helper module mostly forwards calls, wraps a library without simplifying it, or only renames obvious operations; also before adding such a layer."
---

# Pass-through layers

Recognises forwarding layers in existing code and refuses them in new code. Designing a module that is deep from the start is `$philosophy-of-design:deep-modules`; the safe editing loop for removing one layer is `$philosophy-of-design:collapse-layer`.

## When to use

- A `*Service`, `*Manager`, `*Helper`, `*Wrapper` or `*Facade` whose methods each call one collaborator.
- A stack trace shows several frames with the same arguments.
- You are about to introduce a layer "for separation" or "in case we swap the library".
- A wrapper exists around a library and the library's own API would read just as well.

## Rules

1. **Do not create pass-through service classes.** A class whose methods call one collaborator with the same arguments adds a name and a hop, not a simplification. Check: each public method body is one call with its parameters passed straight through.
2. **Do not write thin wrappers around libraries that simplify nothing.** Check: the wrapper's method list is the library's method list, with the same arguments and the same errors.
3. **Do not add helper modules that only rename obvious operations.** Check: the helper's name is a synonym for the standard call inside it.
4. **Before adding a module, layer, service, helper, wrapper, facade, pattern, option, callback or argument, prove it hides more complexity than it adds.** Check: you can write "callers no longer need to know X" where X is a real fact and not "the library's name".
5. **Treat a layer that mostly redirects calls as shallow.** A layer that changes vocabulary (domain words in, vendor words out) hides something; one that keeps the vocabulary only adds hops. Check: compare one method signature on each side; identical types and arguments mean redirect only.
6. **Do not preserve a boundary only because it already exists** when it exposes almost as much complexity as it hides. Check: ask what breaks if the layer is deleted today.
7. **Do not add wrappers and facades that add names but not simplification.** Check: the facade has about as many public names as the subsystem calls a typical caller needs.
8. **Collapse by moving the real work to the owner.** If the layer holds the only validation, defaulting or translation, move it into the module that owns the knowledge before deleting the layer. Check: the tests that covered the layer's logic pass against the owner.
9. **Added judgment: a layer is justified when it is the single place that hides a volatile decision** (a vendor's vocabulary, a file layout) by presenting the caller's vocabulary. That is information hiding (`$philosophy-of-design:information-hiding`); the layer must then own the whole translation and the vendor type must stop at its edge.

## Procedure

1. Inventory candidates: classes named like services, managers, helpers, wrappers or facades, and small files that hold one class with delegating methods.
2. For each public method, note arguments in against arguments forwarded, errors in against errors out, and vocabulary in against vocabulary out.
3. Classify: redirect only (collapse), translating (keep, and check it owns the translation fully), hiding a volatile decision (keep, and make sure vendor types end at it).
4. For redirect-only layers, list the callers, point them at the collaborator (or at a deeper owner operation if they repeat a sequence), delete the layer, and run the tests.
5. If you were about to add a layer, write the "no longer need to know" sentence first and stop if you cannot.

## Example

```python
# Before: a wrapper that mirrors the client and adds a hop
class CacheWrapper:
    def __init__(self, client):
        self._client = client
    def get(self, key):
        return self._client.get(key)
    def set(self, key, value):
        return self._client.set(key, value)
    def delete(self, key):
        return self._client.delete(key)

# every caller still builds keys, serializes values and decides lifetimes
raw = cache.get(f"profile:{user_id}")
profile = json.loads(raw) if raw else load_profile(user_id)

# After: the layer owns key naming, serialization and lifetime
import json

class ProfileCache:
    """Profiles by user id. A miss is filled from `loader`; entries expire after `ttl_seconds`."""
    def __init__(self, client, ttl_seconds=300):
        self._client = client
        self._ttl = ttl_seconds

    def load(self, user_id, loader):
        key = f"profile:v2:{user_id}"
        raw = self._client.get(key)
        if raw is not None:
            return json.loads(raw)
        profile = loader(user_id)
        self._client.set(key, json.dumps(profile), ex=self._ttl)
        return profile
```

The wrapper was removable because it simplified nothing; the replacement earns its place because callers no longer know the key scheme, the encoding or the lifetime.

## Anti-patterns

- **Passive service.** A service between a controller and a repository that forwards every method. Detect: identical signatures on both sides.
- **Mirror wrapper.** A class listing the vendor's methods under the same names. Detect: diff the two method lists.
- **Rename helper.** A function whose body is one standard-library call. Detect: the helper's name explains nothing the call does not.
- **Facade of everything.** A facade that re-exports every subsystem operation. Detect: facade size grows with the subsystem.
- **Layer cake.** Controller, service, manager, repository, DAO where only the ends do work. Detect: four frames in a trace with the same arguments.

## Trade-offs and exceptions

- A layer that translates between vocabularies or hides a volatile third-party detail is not a pass-through layer (rules 5 and 9).
- Frameworks sometimes require a class shape (a controller, a handler). Keep the required shell as thin as the framework demands and put the logic in a deeper module below it, not in more layers.
- Collapsing a layer that is part of a published API is a breaking change; deprecate first (Added judgment).
- A seam added only so tests can substitute a dependency is a cost the book warns about. Prefer passing the dependency as a narrow parameter over introducing a layer for it (Added judgment).

## Verification

- [ ] Every layer left in the touched code can finish "callers no longer need to know ...".
- [ ] No method body in the touched code is a bare delegation.
- [ ] Logic that lived in a removed layer now lives in its owner, with tests passing.
- [ ] No new wrapper, facade or helper was added without that sentence.
- [ ] Callers of a removed layer were updated in the same change.

## Related

`$philosophy-of-design:deep-modules` for the target; `$philosophy-of-design:split-or-merge` for boundaries between units; `$philosophy-of-design:collapse-layer` to edit; `philosophy-of-design-depth-reviewer` to review; `philosophy-of-design-module-deepener` to delegate.

## Source

- `Module Depth Rules`
- `Avoid Shallow Modules`
- `Shallow Decomposition`
- `Combine or Separate Code`: only the rule on keeping a boundary that exposes almost as much as it hides.
- `Code Generation Rules`: only the avoid-by-default list on pass-through layers and needless tiny abstractions.
