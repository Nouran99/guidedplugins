---
name: generators-and-dsls
description: "Use when code is generated, scaffolded or produced by a tool or macro, when a small domain language or rules file is proposed, or when metaprogramming hides behavior. Existing copies of a rule are `dry-knowledge`; scripts for repeated work are `automation`; throwaway code is `prototypes`."
---

# Generators, domain languages and metaprogramming

Machinery that writes, derives or hides code can remove duplication, and can also hide behavior nobody understands. This skill keeps the source specification authoritative and the output understood. Choosing an owner among copies that already exist is `/pragmatic-programmer:dry-knowledge`; throwaway code that is about to become production is `/pragmatic-programmer:prototypes`; scripts for repeated work are `/pragmatic-programmer:automation`.

## When to use

- A tool generates code from a schema, a specification or a template (clients, types, models, scaffolds).
- Someone proposes a rules file, configuration language or small DSL so domain people can state rules.
- Metaprogramming (macros, decorators that rewrite behavior, reflection, dynamically built names) is added or reviewed.
- Generated output, a scaffold or a tool's suggestion is about to be trusted without having been read.
- Behavior works and nobody can say why.

## Rules

1. **Use code generators to remove duplicated mechanical work, and keep the source specification authoritative.** [MUST] Check: the spec is the thing people edit; the generated output can be thrown away and recreated from it.
2. **Never edit generated output by hand; change the specification and regenerate.** [Added judgment] Check: generated files carry a header that says so and names the command that regenerates them.
3. **Make generation reproducible and versioned.** [Added judgment] One command, a pinned generator version, inputs in version control. The source also prefers inspectable plain text for generated sources where practical [SHOULD]. Check: regenerating on a clean checkout yields no diff.
4. **Do not rely on generated code, tools, specifications or formal methods you do not understand.** [MUST NOT] Check: you can explain at least one generated output by reading it, and you know what the tool assumes.
5. **Use metaprogramming only when it reduces duplication or improves adaptability without hiding behavior.** [MUST NOT] Outside those conditions it is forbidden. Check: a reader can find where a behavior comes from with a text search or go-to-definition, and stack traces stay readable.
6. **Use a small domain language when it expresses domain rules more directly than general-purpose code.** [MUST] The condition is the point: it must read more directly. Check: the rule in the language is shorter and clearer than the code it replaces.
7. **Keep domain languages readable by the people who must validate or change them.** [MUST] Check: a domain owner can read a rule file and say whether it is right.
8. **Keep the language small.** [Added judgment] If it needs variables, loops and functions, you are building a general language; prefer a table or configuration with validation until a real need appears. Check: the grammar fits on one screen.
9. **Validate rule files at load time and point at the line.** [Added judgment] Version the format (`/pragmatic-programmer:reversible-choices`). Check: a bad row produces a message with the file, the line and the problem.
10. **When prototypes, scaffolds, diagrams, specs, formal models or tool output start becoming production truth, inspect, understand, harden, replace or reject them deliberately.** [Compact checklist] Check: a generated scaffold was read and trimmed before it was committed.
11. **When tool-derived or generated behavior is unexplained, prove it with data before depending on it.** [Compact checklist] Check: a test or measurement supports the behavior you rely on.

## Procedure

1. Identify the spec: the one artifact people should edit (schema, template, rules file).
2. Check the generator is reproducible: one command, pinned version, no manual post-editing.
3. Mark generated files with a header; keep them out of hand edits (a lint rule or review check helps).
4. Read a sample of the output and the tool's assumptions; write down what you learned.
5. For a rules language: write three real rules in it, ask a domain owner to read them, then build the loader with validation.
6. For metaprogramming: confirm a search finds the behavior and a traceback points to it.
7. Run the tests; regenerate and confirm no diff.

## Example

Shipping fees were an `if` ladder in code and a spreadsheet in finance. A tiny rules table makes the table the specification. The file below is `shipping_fees.csv`, owned by finance and reviewed in pull requests; its first line is the header the loader reads.

```text
country,max_weight_kg,fee_eur
DE,2,4.90
DE,999,7.90
FR,2,6.90
FR,999,10.90
```

```python
import csv
from decimal import Decimal

def load_fee_table(path):
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        for line_no, row in enumerate(csv.DictReader(f), start=2):
            try:
                rows.append((row["country"], Decimal(row["max_weight_kg"]), Decimal(row["fee_eur"])))
            except (KeyError, TypeError, ArithmeticError) as err:    # bad or missing cell
                raise ValueError(f"{path}:{line_no}: bad fee row {row!r}") from err
    rows.sort(key=lambda r: (r[0], r[1]))                            # smallest weight band first, per country
    return rows

def shipping_fee(table, country, weight_kg):
    weight = Decimal(str(weight_kg))
    for c, max_kg, fee in table:
        if c == country and weight <= max_kg:
            return fee
    raise LookupError(f"no shipping fee for {country} at {weight_kg} kg")
```

Finance changes a fee by editing a row. A malformed row fails at load with the file and line, and the code that reads the table is a dozen lines instead of a branch per country.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Hand-edited output | Diffs inside files that say "generated" | Edit the spec, regenerate |
| Unreproducible generation | Generated files that change when regenerated, or need manual steps | One command, pinned versions |
| Scaffold accepted whole | Generated boilerplate committed unread | Read it, trim it, own it |
| Invisible behavior | Methods created from strings, behavior with no definition to find | Make the definition searchable, or drop the trick |
| Language creep | A rules file with loops, variables and functions | Return to a table, or accept you are building a language and own it |
| Unvalidated rules | A rules file parsed with no error reporting | Validate at load with file and line |
| Unexplained success | A generated test suite that passes and nobody can say what it checks | Prove it with data |

## Trade-offs and exceptions

- Generation is a build step and a maintenance cost. Added judgment: generate when duplication is real and mechanical and the spec is genuinely simpler than the output.
- Metaprogramming that frameworks provide (decorators for routes, ORM model definitions) is normal usage. The rule targets behavior hidden in your own code, not use of a framework's documented mechanisms.
- Generated sources may be committed or built on demand. Either is fine if the spec is authoritative and regeneration is reproducible.
- A rules file needs a review process of its own (pull requests, validation in CI) or it becomes an unreviewed back door (Added judgment).

## Verification

- [ ] The specification is the file people edit and the output regenerates with one command.
- [ ] Generated files are marked and no hand edits exist in them.
- [ ] You read a sample of the output and can explain it.
- [ ] Any metaprogramming is findable by search and readable in a traceback.
- [ ] A domain owner has read a sample of any rule language, and bad rules fail with file and line.

## Related

`/pragmatic-programmer:dry-knowledge` for copies that already exist; `pragmatic-programmer:provenance-reviewer` to review code of unclear origin; `/pragmatic-programmer:prototypes` for experiments that start to ship; `/pragmatic-programmer:automation` for the generation command.

## Source

- `Basic Tool Rules`: only the rules on code generators with an authoritative specification, inspectable generated sources and not relying on tools you do not understand.
- `Reversibility, Domain Languages, and Requirements`: only the rules on small domain languages and keeping them readable by the people who validate them.
- `Resource and Coupling Rules`: only the rule on metaprogramming.
