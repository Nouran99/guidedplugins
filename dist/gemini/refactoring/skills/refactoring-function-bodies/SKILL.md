---
name: "refactoring-function-bodies"
description: "Use when a function is long or mixes parsing, validation, computation and I/O, or when temporaries and expressions hide intent. Where to cut a function and the moves inside a body. Parameters are call-signatures; branch structure is conditionals."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "auto"
---

# Function bodies

Where to cut a long function and which moves reshape what is inside it. The boundary of a function (its parameters, flags, argument order) is `refactoring-call-signatures`; the shape of its branching is `refactoring-conditionals`; what it silently reads or writes is `refactoring-hidden-dependencies`.

## When to use

- A function needs scrolling, or you cannot summarize it without "and".
- Parsing, validation, computation and I/O appear in one body.
- A temporary variable is reassigned for different purposes, or an expression needs a comment to be understood.
- Many local variables prevent extracting a block cleanly.
- You are about to add more logic to a function that already mixes responsibilities, abstraction levels, phases or hidden side effects.

## Rules

1. **Split a long function when it mixes responsibilities, levels of abstraction or phases of work.** Length alone is a prompt to look, not a violation. Check: you can name each part by what it achieves.
2. **Extract chunks with names that explain intent.** Check: the name says what, not how; a reader can skip the body.
3. **Do not create micro-method noise with no explanatory value.** An extraction whose name only restates its code adds a jump. Check: every new function carries a meaning the call site did not already show.
4. **One function should usually perform one coherent task, at one abstraction level.** Check: no statement is raw detail next to a call that is a business step.
5. **Split phases such as parsing, validation, computation and I/O when mixed.** Check: each phase can be exercised without running the others.
6. **Remove hidden side effects unless the function's purpose is to cause them, and keep variable scope tight.** Check: each local is declared near its first use and not reused for another meaning.
7. **Delete dead code rather than commenting it out.** Version control remembers. Check: no commented-out blocks remain in the touched function.
8. **Use Extract Method when a fragment has a coherent purpose and a useful name; use Inline Method when the body is clearer than the indirection.** Check: you can state which of the two you are doing and why.
9. **Treat temporaries deliberately.** Inline Temp when a temporary obscures a direct expression; Replace Temp with Query when a calculated value deserves a name and can be reused safely; Introduce Explaining Variable when an expression needs named parts; Split Temporary Variable when one variable carries multiple meanings. Check: no temporary has two meanings, and no one-use temporary merely renames a call.
10. **Remove Assignments to Parameters when mutation obscures what the input meant.** Check: parameters are read-only in the body; a working copy has its own name.
11. **Use Replace Method with Method Object when local state prevents clean extraction, and Substitute Algorithm when a clearer algorithm can replace a tangled one without changing behavior.** Check: the second is backed by tests that cover the old algorithm's edge cases.
12. **Added judgment: choose the extraction boundary at the first line where the reader must change abstraction level, and check what the fragment reads and writes.** A fragment that reads several locals and writes more than one is a method-object or phase-split candidate, not a plain extract. Check: the extracted function has few parameters and a single result.
13. **When a function mixes responsibilities, abstraction levels, phases or hidden side effects, rename, extract, split phases or isolate side effects before adding more logic (compact checklist).** Check: the new logic lands in a function that does one coherent thing, or your notes say why the function was left as it is.

## Procedure

1. Read the function once and summarize it in one sentence; mark every place you hesitated.
2. Mark abstraction levels and phases. Note temporaries with more than one meaning.
3. Do the cheap moves first: split temporaries, remove parameter assignments, inline pointless temporaries.
4. Extract the lowest-level coherent chunk with an intent name; run the tests; repeat until the top reads as an outline.
5. If extraction needs many parameters, introduce a method object or split by phase instead.
6. Stop when the next extraction would only restate its code (`refactoring-stopping-rules`).

## Example

```java
// Before
double statement(Order order) {
    double result = 0;
    for (Line l : order.lines()) {
        double t = l.qty() * l.unitPrice();
        if (l.qty() > 100) t = t * 0.95;
        result += t;
    }
    result += result > 500 ? 0 : 12.5;   // shipping
    System.out.println("total=" + result);
    return result;
}

// After: same arithmetic in the same order, same single log line
double statement(Order order) {
    double goods = goodsTotal(order);
    double total = goods + shippingFor(goods);
    System.out.println("total=" + total);   // logging is an effect: left where it was
    return total;
}

private double goodsTotal(Order order) {
    double sum = 0;
    for (Line line : order.lines()) sum += lineTotal(line);
    return sum;
}

private double lineTotal(Line line) {
    double gross = line.qty() * line.unitPrice();
    return line.qty() > 100 ? gross * 0.95 : gross;
}

private double shippingFor(double goodsTotal) {
    return goodsTotal > 500 ? 0 : 12.5;
}
```

The temporary `t` is now `gross`, one meaning; the shipping decision is named; the log line stays in place because moving or removing it would be an observable change.

## Anti-patterns

- **Confetti.** Detect: many two-line helpers called once, whose names restate their bodies. Treat: inline them (Inline Method).
- **Reused temporary.** Detect: one local assigned for unrelated purposes. Treat: Split Temporary Variable.
- **Parameter overwrite.** Detect: assignment to a parameter. Treat: introduce a local with its own name.
- **Extract with a long parameter list.** Detect: a new function taking five or more locals (the count is Added judgment). Treat: method object, or split phases instead.
- **Commented-out code.** Detect: code in comments inside the body. Treat: delete it.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- A long function that is one flat level, such as a table of field mappings, may be left whole; splitting it by size alone makes it harder to scan. (Added judgment)
- Hot paths that measurably need inlining can stay inline; record the evidence (Added judgment).
- Substitute Algorithm is the riskiest move here; do it only with tests that pin the old behavior. (Added judgment)
- The source's list of mixed phases (parsing, validation, computation, I/O) is a guide, not a required decomposition for every function.

## Verification

- [ ] Each extracted function has an intent name and a meaning the call site did not show.
- [ ] No temporary carries two meanings and no parameter is reassigned.
- [ ] Phases that were mixed are separate, or you can say why they stay together.
- [ ] Observable effects (I/O, logging, ordering) are unchanged.
- [ ] Tests passed after each extraction.

## Related

`refactoring-call-signatures` for the extracted functions' parameters; `refactoring-conditionals` for branching; `refactoring-hidden-dependencies` for side effects; `refactoring-function-reviewer` to review a diff; `/refactoring:smell-to-refactoring` to map a long function to its move.

## Source

- `Long Functions`
- `Function-Level Rules`
- `Composing Methods`
- `Extraction Refactorings`
