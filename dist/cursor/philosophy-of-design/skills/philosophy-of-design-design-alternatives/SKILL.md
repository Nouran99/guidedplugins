---
name: "philosophy-of-design-design-alternatives"
description: "Use before committing to a non-trivial interface, abstraction or decomposition, and whenever two or more designs are being weighed: compare at least two plausible designs on interface simplicity, information hiding, special-case reduction and future cognitive load."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Design alternatives

The rules for comparing designs before building one. Producing the written comparison is the workflow `philosophy-of-design-design-twice`; testing a single design by writing its contract first is `philosophy-of-design-comments-first`.

## When to use

- You are about to add a public interface, a module, a layer or a data ownership boundary.
- The first design that came to mind looks obviously right.
- A review asks "did you consider another way?"
- A comment needed to explain a design has become complicated.

## Rules

1. **For a non-trivial design choice, compare at least two plausible designs before implementing the first one that works.** Check: the plan names two designs and why each is plausible.
2. **Evaluate alternatives by interface simplicity, information hiding, special-case reduction and future cognitive load.** Check: each criterion has a one-line verdict per design.
3. **When an interface or abstraction is unclear, sketch the public contract and its explanatory comments before committing to the implementation.** Check: a contract exists before the body does.
4. **Use comments-first design to clarify abstraction boundaries, not to preserve vague or misleading code.** Check: the sketch changed at least one boundary, or you can say why it did not need to.
5. **Revise the abstraction when the comment needed to explain it becomes complicated.** Check: the contract fits in a few plain sentences.
6. **Do not accept the first design just because it is locally convenient.** Check: the chosen design beat another one on a stated criterion.
7. **Do not use comments to justify a confusing interface instead of changing the interface.** Check: the contract has no "note that" paragraphs about surprising behavior.
8. **Do not document implementation mechanics that callers should not need to know.** Check: the contract mentions no storage, locking or algorithm choice.
9. **Added judgment: the alternatives must differ in an interface or ownership decision.** Two sorting algorithms behind one signature are not design alternatives in this sense; two places where the knowledge lives are. Check: each design has its own call site.
10. **Added judgment: a choice is non-trivial if it changes a public signature, adds a module or layer, moves ownership of data or a rule, or crosses a team boundary.** Smaller choices need no comparison.

## Procedure

1. Write the problem as one sentence in the callers' words.
2. Sketch design A and design B as call sites plus a one-paragraph contract each.
3. Score both on the four criteria of rule 2 and note the cost of each.
4. Choose, and record the deciding criterion and what you accepted as the price.
5. If the contract of the winner is complicated, change the design and rescore (rule 5).
6. Implement the winner only after this.

## Example

```ts
// Need: send a reminder only when the user wants one.

// Design A: callers decide. Preferences are public; each of seven senders checks them.
if (prefs.allows(user, "reminder") && !quietHours.contains(now, user.timezone)) {
  mailer.send(user.email, template("reminder", data));
}

// Design B: the module decides. Preferences, quiet hours and channel choice stay inside.
reminders.send(user, reminder);

// Interface simplicity:    A three concepts per call site      B one call
// Information hiding:      A preference layout and quiet-hours rule reach every sender   B hidden
// Special-case reduction:  A each sender can add its own exception                        B one place
// Future cognitive load:   A a new channel touches every sender                          B one module
// Choice: B. Price accepted: Reminders owns more logic, in exchange for simpler callers.
```

## Anti-patterns

- **First-design acceptance.** The first working idea ships unexamined. Detect: no second design appears anywhere in the plan or description.
- **Straw-man alternative.** The second design is built to lose. Detect: it has no call site of its own, or an obvious flaw nobody would choose.
- **Implementation-only alternatives.** Two ways to code the same interface. Detect: the signatures are identical.
- **Justifying comment.** A long comment defending a confusing interface. Detect: "note that", "be careful", "unlike similar methods".
- **Comparison theater.** A table with no decision recorded. Detect: no named winner or no stated price.

## Trade-offs and exceptions

- Do not run a comparison for every small choice (rule 10). Time-box it; a few minutes with stubs or paper sketches is often enough (Added judgment).
- If only one design is plausible, say why, in a sentence; that is a valid outcome.
- Explicit user requirements, repository conventions and existing public contracts may rule out an alternative; record that as the reason.
- Comments-first design is a way to find boundaries; it does not mean writing documentation for code you plan to keep vague.

## Verification

- [ ] Two designs exist as call sites.
- [ ] All four criteria were scored for each.
- [ ] The choice names its deciding criterion and its price.
- [ ] The contract of the chosen design is short and in the callers' words.
- [ ] No mechanism leaked into the contract.

## Related

`philosophy-of-design-design-twice` to produce the comparison; `philosophy-of-design-comments-first`; `philosophy-of-design-comments-as-design`; `philosophy-of-design-plan` to sequence the work after the choice.

## Source

- `Design Alternatives and Comments-First Design`
