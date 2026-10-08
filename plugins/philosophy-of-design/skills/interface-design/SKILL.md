---
name: interface-design
description: "Use when shaping a single public function, method, class or API element: design it around what callers need to know, not how the implementation works. Narrow but meaningful, names that reveal the abstraction."
---

# Interface design

Shapes one public element at a time: its operations, parameters, return values and names. Parameters that select behavior are covered in depth by `/philosophy-of-design:flags-and-knobs`; call order by `/philosophy-of-design:temporal-decomposition`; where knowledge lives by `/philosophy-of-design:information-hiding`.

## When to use

- You are writing the signature of a new public function, method or endpoint.
- A call site needs several lines of setup before the one line that matters.
- A signature has arguments that only make sense to someone who knows the implementation.
- A review asks whether an API is "easy to use correctly".

## Rules

1. **Design interfaces around what clients need to know, not how the implementation works.** Check: every parameter and return value can be explained in the caller's vocabulary.
2. **Keep interfaces narrow but meaningful.** Narrow means few things to learn, not few characters; each operation should do a complete job. Check: no caller composes three calls to get one result.
3. **Avoid APIs that require callers to stage operations in fragile sequences.** Check: the common call works without a prior setup call.
4. **Eliminate arguments that only exist to expose internal implementation choices.** Buffer sizes, algorithm names, index hints. Check: if the implementation changes, the argument either stays meaningful or goes away.
5. **Use names and method shapes that reveal the abstraction, not the mechanism.** Check: the name describes the outcome (`register`), not the steps (`insertRowAndSendHash`).
6. **Prefer, as signs of a good interface: few methods, strong semantic guarantees, limited required context, and callers who need not understand the internals.** Check: a new teammate can use it from the contract comment alone.
7. **Treat these as warnings, usually forbidden: many configuration flags, call-order traps, several setup methods required before use, and boolean or mode parameters that switch internal behavior.** Check: search the signature for `bool`, `mode`, `options` bags and `init`/`setup` methods.
8. **Design the common call site first.** Added judgment: write the three most frequent callers as code before fixing the signature. Check: each is one line without setup.
9. **Make the common case automatic and keep rare controls out of the common path.** Check: defaults serve the typical caller; rare options sit behind named parameters or a separate operation.

## Procedure

1. List who will call this and what each caller wants done.
2. Write those calls as code on paper. Delete every argument or step the caller would not choose themselves.
3. Draft the signature from the calls, naming the outcome.
4. Write the contract comment (what it guarantees, what it does on bad input). If the comment needs mechanism words, return to step 2.
5. Check the signature for flags, setup methods and mechanism arguments; apply `/philosophy-of-design:flags-and-knobs` if any appear.
6. Implement behind the signature. Callers must not need to change when the implementation does.

## Example

```python
# Before: a staged API with mechanism-flavored configuration
exporter = CsvExporter()
exporter.set_path("out/orders.csv")
exporter.set_delimiter(",")
exporter.set_encoding("utf-8")
exporter.set_rows(rows)
exporter.open()
exporter.write_header()
exporter.write_rows()
exporter.close()

# After: one operation; the rare control is a named keyword
import csv

def export_csv(path, rows, *, columns=None):
    """Write `rows` (dicts) to `path` as UTF-8 CSV with a header line, replacing any existing file.

    Columns default to the keys of the first row, in order. With no rows and no
    `columns` the file is created empty."""
    names = list(columns) if columns is not None else (list(rows[0]) if rows else [])
    with open(path, "w", newline="", encoding="utf-8") as f:
        if names:
            writer = csv.DictWriter(f, fieldnames=names, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(rows)
```

Eight calls and an ordering rule became one call; delimiter and encoding stopped being the caller's concern.

## Anti-patterns

- **Setup ritual.** Several calls before the first useful one. Detect: methods that throw "not initialized".
- **Mechanism argument.** `use_index=True`, `buffer_size=4096`. Detect: arguments whose meaning requires reading the body.
- **Representation-shaped methods.** Getters and setters for every field. Detect: public accessors in 1:1 correspondence with private fields.
- **Kitchen-sink function.** One function with a dozen optional parameters. Detect: a docstring longer than the body.
- **Mode switch.** A boolean or enum that changes what the function fundamentally does. Detect: `if mode == ...` at the top of the body.

## Trade-offs and exceptions

- The source marks bad interface signs as warnings that are usually forbidden, not always forbidden. A single caller-meaningful option can be right; ask whether a caller can reasonably choose it without implementation knowledge.
- Narrow is not minimal. Removing an operation that every caller then re-implements makes the interface wider in practice (Added judgment).
- Public APIs with existing clients may need the old shape to remain; add the narrow operation, deprecate the old one.
- Wire or file formats that the interface must expose are part of the contract; document them.

## Verification

- [ ] The most common call is one line with no prior setup.
- [ ] No parameter requires knowledge of the implementation to choose.
- [ ] The contract comment fits in a few sentences and uses the callers' words.
- [ ] No boolean or mode parameter switches internal behavior.
- [ ] Changing the implementation would not change any signature.

## Related

`/philosophy-of-design:flags-and-knobs`; `/philosophy-of-design:temporal-decomposition`; `/philosophy-of-design:information-hiding`; `/philosophy-of-design:comments-first` to test a signature by writing its contract; `philosophy-of-design:interface-reviewer` to review; `philosophy-of-design:interface-simplifier` to rework a signature.

## Source

- `Interface Design Rules`
- `Code Generation Rules`: only the steps to design the narrowest strong interface around a concept and to simplify callers.
- `Interface Leakage`
