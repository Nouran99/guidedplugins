---
name: "philosophy-of-design-temporal-decomposition"
description: "Use when code is organized as prepare/process/finalize phases, objects need staged calls before use, init/open/configure sequences exist, or callers must know a hidden call order."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Temporal decomposition

Judges structure that follows the order of execution instead of the concepts involved, and APIs whose correctness depends on call order. Parameters that select behavior are `philosophy-of-design-flags-and-knobs`; where a piece of knowledge lives is `philosophy-of-design-information-hiding`.

## When to use

- Classes or modules are named for steps: `Loader`, `Parser`, `Validator`, `Finalizer`.
- An object must be configured, opened or initialized before its methods work.
- Documentation says "call X before Y" or a method throws "not initialized".
- Several phases of one job each know the same format or rule.

## Rules

1. **Do not structure modules primarily around execution order if the real structure is conceptual.** Check: ask what the domain calls this piece; if the only name is a time word (`step`, `phase`, `stage`), the concept is missing.
2. **Prefer decomposition around stable concepts and responsibilities.** Check: each module owns a decision that would still exist if the order of steps changed.
3. **Do not force readers to reconstruct the design from time order alone.** Initialization, processing and cleanup stages should not be the only organizing idea. Check: you can explain the module without saying "first ... then ...".
4. **Keep call ordering simple and explicit where it matters.** Check: where order is real, the code shows it (types, a single entry point, a visible sequence), not a comment.
5. **Do not use `prepare`, `process`, `finalize` everywhere without domain concepts.** Check: the three names could be swapped between unrelated modules without changing their meaning.
6. **Do not build APIs that require secret temporal knowledge.** Check: a caller who skips a step gets a compile error, a safe result or a clear failure, never silent wrong output.
7. **Do not use partial objects whose meaning depends on which phase has already run.** Check: after construction, every method is valid to call.
8. **Avoid APIs that make callers stage operations in fragile sequences.** Check: one public operation does the job, or each step's output is the next step's required input.
9. **Added judgment: make necessary order structural.** A factory that returns a ready object, a function that takes the previous step's result type, or a scoped-resource construct (`with`, `defer`, try-with-resources) turns an order rule into something the compiler or runtime enforces.
10. **Added judgment: when order is intrinsic (a protocol handshake, a build pipeline), keep the phases and make them visible.** Name each phase after its domain meaning and type its hand-off.

## Procedure

1. Write the current call sequence and note, for each step, which facts it produces and consumes.
2. For each step, ask whether a domain concept owns it or whether it is only "what happens next".
3. Find knowledge shared by several steps (a layout, a rule) and give it one owner module.
4. Fold the steps that exist only to feed each other behind one operation on that owner.
5. Where order must remain, encode it in types or constructors.
6. Update callers; run the tests, including a test that proves a skipped step is impossible or safe.

## Example

```ts
// Before: phases as methods; the caller carries the order in its head
const job = new ImportJob();
job.setPath(path);
job.readFile();        // must come first
job.parseRows();       // throws "no data" if readFile was skipped
job.validateRows();    // throws "no rows" if parseRows was skipped
job.save(db);

// After: the ledger module owns the layout and hands back only valid rows
// ledger.ts
/** Reads a ledger CSV and returns its rows. Throws LedgerFormatError if any row is malformed. */
export async function readLedger(path: string): Promise<LedgerRow[]> {
  const text = await fs.promises.readFile(path, "utf8");
  return text.split("\n").filter((line) => line.length > 0).map(parseRow).map(requireValid);
}

// caller
await ledgerStore.save(db, await readLedger(path));
```

Reading, parsing and validating all depended on the same file layout; now one module knows it, and no caller can run the steps out of order.

## Anti-patterns

- **Phase objects.** One object that changes meaning as methods are called. Detect: a status or boolean field consulted before every method.
- **Prepare/process/finalize everywhere.** Time words as module names. Detect: modules interchangeable by renaming.
- **Secret order.** The docs say "call `init` first". Detect: methods that throw "not initialized" or "call X before Y".
- **Setters then run.** Configuration spread over many calls before `run()`. Detect: more setter calls than the work they configure.
- **Cleanup choreography.** Callers must close resources in a particular order. Detect: the same close sequence at several sites.

## Trade-offs and exceptions

- Some domains are temporal by nature: protocol handshakes, state machines, multi-stage pipelines. Keep the stages and give each a domain name and a typed hand-off (rule 10).
- A required order that is cheap, obvious and enforced by types is fine; the target is order that callers must remember.
- Builders can be a legitimate answer for objects with many optional parts, provided `build()` returns a fully valid object (Added judgment).
- Keep call ordering explicit; do not hide an order that has real side effects behind a name that suggests otherwise.

## Verification

- [ ] No public method of the touched types can be called in a state where it is invalid.
- [ ] No documentation tells callers to call one thing before another.
- [ ] Module names describe concepts, not steps.
- [ ] The knowledge shared by former phases lives in one module.
- [ ] A test shows that the former out-of-order call is impossible or harmless.

## Related

`philosophy-of-design-information-hiding`; `philosophy-of-design-interface-design`; `philosophy-of-design-split-or-merge`; `philosophy-of-design-temporal-reviewer` to review.

## Source

- `Temporal Decomposition Rules`
- `Interface Design Rules`: only the rule against APIs that require fragile staged sequences.
