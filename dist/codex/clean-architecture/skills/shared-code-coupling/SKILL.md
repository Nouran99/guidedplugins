---
name: "shared-code-coupling"
description: "Use when about to remove duplication, create or grow a common, shared, utils, base or core module, or merge use cases for convenience. Covers when sharing couples different actors and when duplication is the right choice. A single growing class is service-sprawl."
---

# Shared code and coupling

Owns the decision to share code between use cases, features or components, and the growth of modules whose only purpose is to be shared. A single class that has accumulated actions is `$clean-architecture:service-sprawl`; the shape of the folders is `$clean-architecture:screaming-structure`; cycles between components are `$clean-architecture:component-coupling`.

## When to use

- You see two similar blocks and want to extract one function or base class.
- You are about to add a file to `utils`, `common`, `shared`, `base` or `core`.
- Two use cases are being merged because they look alike.
- A change for one feature keeps breaking an unrelated feature through a shared helper.

## Rules

1. **Do not remove duplication if the shared code would tie together use cases that different actors change.** `[MUST NOT]` Check: name the actor or owner behind each caller of the proposed shared function; if they differ and would ask for different changes, keep the copies.
2. **Do not combine unrelated use cases because operational wiring is easier.** `[MUST NOT]` Check: a merged class or module serves one action or one actor.
3. **Avoid shared "common" packages that create sideways coupling.** `[MUST NOT]` Check: features do not import each other's internals or a catch-all package to reach each other.
4. **Do not use generic utility, shared, base or core folders as architecture escape hatches, and do not build generic abstractions with no clear ownership or convenience modules that hide bad dependency direction.** `[MUST NOT]` unless explicitly required and justified. Check: every module in such a folder has a named owner and a business or policy reason to exist.
5. **Let inner layers own the abstractions they need and outer layers implement them, and prefer stable dependencies.** `[MUST]` for the ownership half (`Non-Negotiable Rules` rule 10, and the checklist item that ports are owned by inner layers); `[SHOULD]` for choosing stable targets, the `Prefer Stable Dependencies` heading. A shared module is acceptable when it is inner-layer policy that many things depend on; it is dangerous when it is a convenient place for volatile code. Check: the shared module imports nothing outward.
6. **Apply SRP: keep code that changes for different actors or reasons apart.** `[MUST]` Check: a shared function with flags or optional parameters that each serve one caller is two functions fused together.
7. **Give shared code an owner and a capability name.** Added judgment: `invoice-address`, `carrier-label`, `late-fee-policy`. Check: the module's name would still make sense if its first caller disappeared.
8. **Share on cohesion, copy on divergence.** Added judgment: ask "if actor A requests a change here, must actor B's behavior change?" If yes, share. If no, copy, and let each copy evolve. Check: you can answer the question for each pair of callers.
9. **Share stable domain concepts, not one actor's behavior.** Added judgment: a plain `Address` or `Money` value used by both billing and shipping is shared policy-free data; a function that decides how an address prints for a carrier is shipping's behavior. Check: the shared module holds data definitions and invariants, and no formatting or presentation choices.
10. **Treat a flag added to a shared function as a warning.** Added judgment: the second boolean parameter usually marks the moment two actors started pulling in different directions. Check: the function's parameters include a flag for each caller.

## Procedure

1. List the places where the candidate duplication occurs and what each caller is for.
2. For each pair of callers, answer rule 8's question. Record the actor and the reason to change.
3. If the callers share an actor and a reason to change, extract the shared code into a module named for the capability and placed with its owner.
4. If they do not, leave the copies; add a short comment naming the sibling so a later reader knows it was deliberate.
5. For code already in a catch-all folder, return each piece to its owner, one at a time, with the tests green.
6. Check that the shared module imports only inward or same-layer code.

## Example

```ts
// Before: shared/formatAddress.ts serves billing and shipping, and grows a flag per caller
export function formatAddress(
  a: Address,
  opts: { upper?: boolean; includeName?: boolean; vatId?: string } = {},
): string {
  const lines = [
    opts.includeName === false ? undefined : a.name,
    a.line1,
    a.line2,
    `${a.postcode} ${a.city}`,
    a.country,
    opts.vatId && `VAT ${opts.vatId}`,
  ].filter(Boolean) as string[];
  const text = lines.join("\n");
  return opts.upper ? text.toUpperCase() : text;
}
```

```ts
// After: the stable concept is shared; each presentation belongs to its actor
// domain/address.ts
export interface Address {
  name: string;
  line1: string;
  line2?: string;
  postcode: string;
  city: string;
  country: string;
}

// shipping/carrierLabel.ts: changes when the carrier changes its label format
export const carrierLabelLines = (a: Address): string[] =>
  [a.line1, a.line2, `${a.postcode} ${a.city}`.toUpperCase(), a.country.toUpperCase()].filter(
    (line): line is string => !!line,
  );

// billing/invoiceAddress.ts: changes when invoice legal requirements change
export const invoiceAddressLines = (a: Address, vatId?: string): string[] =>
  [a.name, a.line1, a.line2, `${a.postcode} ${a.city}`, a.country, vatId && `VAT ${vatId}`].filter(
    (line): line is string => !!line,
  );
```

A legal change to invoices no longer risks the shipping labels, and each function has one reason to change. The duplicated filtering expression is small and deliberate.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Junk-drawer module | `utils`, `common`, `helpers` with unrelated functions and rising import counts | Return each function to its owning capability |
| Flag-fused function | A shared function with boolean or option parameters that each serve one caller | Split into one function per caller |
| Shared base class | A base class extended by unrelated use cases for convenience | Composition, or independent classes |
| Cross-feature internals | One feature importing another's non-public modules | Expose a use case or port, or copy |
| Premature DRY | Extraction after the second occurrence by different actors | Revert to copies; revisit when they change together |
| Core package | A package named `core` or `base` that imports outward | Move policy inward and details outward |

## Trade-offs and exceptions

- Duplication has a cost. If both copies must always change together for the same actor and reason, sharing is correct; the rule is aimed at coupling across different actors.
- Stable, tiny, policy-free helpers used everywhere (a standard-library wrapper, a value type) are acceptable shared code when they sit in an inner layer and import nothing outward. Added judgment.
- Added judgment (an application of the rule against coupling different actors, not a separate rule of the source): across deployable components, a copied function is often cheaper than a shared library that forces coordinated releases (`$clean-architecture:component-grouping`).
- Generic abstractions with no clear ownership are forbidden "unless explicitly required and justified"; write the justification where the next reader will find it.

## Verification

- [ ] For each proposed shared piece you named the actors of its callers.
- [ ] No shared function carries a flag that serves one caller.
- [ ] Every module in a shared folder has an owner and a capability name.
- [ ] The shared module imports nothing from an outer layer.
- [ ] Deliberate duplicates carry a note naming their sibling.
- [ ] The tests pass after each move.

## Related

`$clean-architecture:service-sprawl` for one class doing too much; `$clean-architecture:component-coupling` for cycles; `$clean-architecture:screaming-structure` for the tree; `clean-architecture-sprawl-reviewer` to review a diff.

## Source

- `Utility Dumping Grounds`
- `Prefer Stable Dependencies`
- `Non-Negotiable Rules`: only rule 10, outer layers implement interfaces the inner layers own.
- `Boundary Cost, Deployment, and Operations`: only the rules against combining unrelated use cases for wiring and against removing duplication that couples different actors.
- `Paradigm and Component Rules`: only SRP, separating code that changes for different actors or reasons.
- `When Tradeoffs Are Necessary`: only documenting a justified exception.
