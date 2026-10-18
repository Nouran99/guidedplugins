---
name: "static-and-global"
description: "Use when static calls, singletons, global configuration or shared global state block substitution: wrappers, facades, instance delegators, getters, caller migration. Clock, randomness and environment reads are `$legacy-code:hidden-inputs`; misplaced object creation is `$legacy-code:construction-barriers`."
---

# Static and global dependencies

Code that reaches for a static method, a singleton or a global setting cannot be given a different one in a test. This skill puts a wrapper in front of the access path and moves callers over a little at a time. Values that come from the clock, randomness or the environment are `$legacy-code:hidden-inputs`; objects created in the wrong place are `$legacy-code:construction-barriers`; subclass-based getters are tolerated only under `$legacy-code:last-resort-seams`.

## When to use

- Logic calls `Settings.get()`, `Registry.instance()`, a static helper or a package-level variable.
- A test needs two different configurations in the same process and cannot have them.
- Static initialization runs code, reads files or opens connections when the class loads.
- Many callers use the same global and you need to leave a trail of small, safe migrations.

## Rules

1. **Create a wrapper or facade around static and global access.** [MUST] The wrapper is the new seam; production wires it to the old global. Check: the only code that touches the global is the wrapper.
2. **Move callers to the wrapper.** [MUST] Check: a search for the global's name finds the wrapper and a shrinking list of remaining callers.
3. **Inject the wrapper where possible.** [MUST] The qualifier is part of the rule. Added judgment: where injection is not possible yet, pass the wrapper through the nearest seam. Check: the code under test receives the wrapper instead of reaching for it.
4. **Reduce direct calls incrementally.** [MUST] Check: each step migrates a bounded set of callers and leaves the tests green.
5. **Do not add more globals, statics, ambient context or framework reach-through in code that is already hard to test.** [MUST NOT] Check: the diff adds no new singleton read, static call or framework lookup inside logic.
6. **Reduce static initialization side effects.** [MUST] Check: loading the class does nothing observable; setup is lazy or explicit.
7. **Use Encapsulate Global References when globals or singletons prevent substitution.** [SHOULD] Gather the references behind one class whose instance can be replaced. Check: callers go through the instance.
8. **Use Introduce Instance Delegator when static behavior needs an instance seam.** [SHOULD] Add an instance method that calls the static one, then move callers to the instance. Check: the static method has a delegating instance method and callers migrate to it.
9. **Use Replace Global Reference with Getter when direct global access needs a seam.** [SHOULD] Added judgment: if the getter becomes a seam only because a test subclass overrides it, that subclass is a last-resort seam with a cleanup obligation. Check: the getter is the one place the global is read.
10. **Shape the wrapper in the callers' vocabulary.** [Added judgment] Expose the operations callers need, not the global's whole API. Check: the wrapper has no method no caller uses.
11. **Keep production identical by default.** [Added judgment] A legacy entry point that builds the wrapper over the old global keeps existing callers unchanged while they migrate. Check: callers not yet migrated behave as before.
12. **Migrate the callers on the test path first.** [Added judgment] Check: the first migrated callers are those your tests and your change go through.
13. **Do not turn the wrapper into the next global.** [Added judgment] A wrapper reached through another static accessor leaves the dependency where it was. Check: the wrapper arrives through a parameter or field.

## Procedure

1. List the access paths to the global in the code you will change and in the tests you want.
2. Define the narrow wrapper type and one implementation that delegates to the old global.
3. Add a legacy entry point that builds the default wrapper, so nothing breaks.
4. Migrate the callers on the test path to receive the wrapper. Run the tests after each caller.
5. Write the test with a fixed wrapper; keep a test that exercises the real global wiring once.
6. Count remaining direct references and record them in the report.

## Example

```go
// Before: pricing/total.go reaches for a package-level singleton
package pricing

import "shop/settings"

type Line struct{ Cents, Qty int }

func Total(lines []Line) int {
	sum := 0
	for _, l := range lines {
		sum += l.Cents * l.Qty
	}
	rate := settings.Get().TaxRatePercent
	return sum + sum*rate/100
}
```

```go
// After: the global sits behind a wrapper; the old function still works
type TaxRates interface{ TaxRatePercent() int }

type settingsRates struct{}

func (settingsRates) TaxRatePercent() int { return settings.Get().TaxRatePercent }

type Calculator struct{ Rates TaxRates }

func (c Calculator) Total(lines []Line) int {
	sum := 0
	for _, l := range lines {
		sum += l.Cents * l.Qty
	}
	return sum + sum*c.Rates.TaxRatePercent()/100
}

// Legacy entry point: callers keep compiling and migrate one by one.
func Total(lines []Line) int {
	return Calculator{Rates: settingsRates{}}.Total(lines)
}
```

```go
type fixedRate int

func (f fixedRate) TaxRatePercent() int { return int(f) }

func TestTotalAddsTax(t *testing.T) {
	c := Calculator{Rates: fixedRate(20)}
	got := c.Total([]Line{{Cents: 500, Qty: 2}, {Cents: 250, Qty: 1}})
	if got != 1500 { // 1250 plus 20 percent
		t.Fatalf("got %d, want 1500", got)
	}
}
```

Direct references to `settings.Get()` outside the wrapper are now a countable list instead of a hidden property of every function.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Wrapper that is itself global | `Wrapper.instance()` called from logic | Pass it in |
| Wide wrapper | Mirrors every method of the global | Reduce to used operations |
| Big-bang migration | Every caller changed in one step | Migrate by area, test between |
| Test-only global setter | `Settings.set(...)` used only in tests | Wrapper plus injection |
| New reach-through | A fresh `getInstance()` in new code | Receive the wrapper |
| Hidden static init | Class load connects or reads files | Make it lazy or explicit |

## Trade-offs and exceptions

- Injection is "where possible"; a framework that constructs your classes may force a lookup at the entry point. Keep the lookup there.
- Added judgment: for a global used in one place, a single wrapper and a single caller migration may be enough; do not build a framework.
- Replacing the global entirely is a larger change; the source asks for incremental reduction, not elimination.
- Added judgment: a static helper that is pure (no state, no effects) does not need a wrapper. The source's review rules list direct static calls with no such exemption; this one is the plugin's reading, so say it when you skip a helper.

## Verification

- [ ] The global is touched only by the wrapper.
- [ ] The code under test receives the wrapper.
- [ ] Unmigrated callers behave as before.
- [ ] The remaining direct references are counted.
- [ ] No new global, static or ambient lookup was added.
- [ ] Tests ran after each migration step.

## Related

`legacy-code-static-global-reviewer` to review a diff; `legacy-code-global-encapsulator` to make the change; `$legacy-code:hidden-inputs` for clock, randomness and environment; `$legacy-code:construction-barriers` for objects; `$legacy-code:last-resort-seams` for overridden getters.

## Source

- `Static and Global Dependencies`
- `Hidden Inputs`: only the items on static singletons and global configuration.
- `Dependency-Breaking Technique Index`: only Encapsulate Global References, Introduce Instance Delegator and Replace Global Reference with Getter.
- `Hidden Dependency Expansion`
- `Required Moves`: only the rule to wrap static and global access.
- `Testability Improvements`: only the rule to reduce static initialization side effects.
- `Code Generation Rules`: only the preferred first move of wrapping a static call.
- `Handling Risky Areas`: only the subsection on static and global dependencies.
- `Dependency Breaking Rules`: only the move of wrapping static and global access.
