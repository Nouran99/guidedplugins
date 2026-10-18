---
name: "refactoring-guru-explanatory-comments"
description: "Use when a comment explains what confusing code does, sits above a block that could be named, or guards a hidden assumption. Decides rename, extract variable, extract method or assertion versus keeping a comment for rationale; performing the extraction is composing-methods."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Explanatory comments

Owns the Comments smell: a comment that says what unclear code does instead of why the code exists. The decision is whether the comment should become a name, a variable, a method or an assertion, or stay. Performing the extraction is `refactoring-guru-composing-methods`; the smell is not about the amount of commenting, only about comments that compensate for structure.

## When to use

- A comment precedes a block and summarizes it ("// check if eligible").
- A comment explains a cryptic variable, a magic expression or the meaning of a flag.
- A comment states an assumption about state ("here status is always X").
- A reviewer asks whether a long comment could be a function name.

## Rules

1. **Treat a comment as a smell when it explains what unclear code does rather than why it exists.** The comment is a symptom of missing structure. Check: delete the comment mentally; if the reader now has to decode the code, the structure is the problem.
2. **Replace explanatory comments with better names, extracted variables, extracted methods or assertions** (`SHOULD`). Check: the information in the comment now lives in an identifier or a check that the compiler or tests see.
3. **Prefer names and extracted methods before comments** (`SHOULD`). Check: the order you tried is visible in the change: rename or extract first, comment last.
4. **Do not use comments as deodorant for confusing structure** (`MUST NOT`). Check: a comment never apologizes for the next five lines.
5. **Use Extract Variable when an expression is hard to understand in place.** Introduce an immutable local close to its use, name the concept and keep the evaluation order. Do not use it when the variable merely repeats the expression mechanically. Check: the name says what the value means, not how it is computed.
6. **Use Extract Method when a fragment needs a comment to say what it does** (`SHOULD`), naming it by purpose. Check: the method name is a rephrased comment, and the fragment hides no important side effect.
7. **Use Rename Method when a method name hides intent,** so callers need not read the body. Do not use it when the rename churn is unrelated to the change. Check: the new name is used at every call site and the old comment is gone.
8. **Use Introduce Assertion for hidden state assumptions** (the fallback rung) to make an invariant explicit. Put it at the boundary of the assumption. Check: a test or a deliberate violation produces a clear failure.
9. **Use assertions for invariants, not for normal validation or recoverable errors** (`SHOULD`), and never for normal user input or expected absence (`MUST NOT`). Check: the assertion could only fail through a programming mistake.
10. **Keep comments for rationale, non-obvious constraints, external contracts and algorithms that resisted simplification** (`SHOULD`; also `MAY` per the smell exceptions). Check: the comment says why, names a constraint or cites a contract.
11. **Do not delete comments before the code has become self-explanatory** (the risky rung). Check: the name or assertion that replaces a comment exists before the comment is removed.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Comments | Extract Variable, Extract Method, Rename Method | Introduce Assertion for hidden state assumptions | Deleting comments before the code has become self-explanatory |

## Procedure

1. List the comments in the touched code. Sort each into: what, why, constraint or contract, assumption.
2. For each "what": try rename, extract variable, extract method, in that order of size.
3. For each "assumption": decide whether it is an invariant (assert) or a normal input (validate).
4. Keep every "why", "constraint" and "contract" comment, and check that it is still true.
5. Remove a comment only after its replacement exists and tests pass.

## Example

One comment says what, one states an assumption and one says why. The what-comment becomes names, the why-comment stays next to the code it explains, and the assumption becomes an assertion in a separate step because that step can change behavior.

```python
# Before
def can_access(sub, today):
    # active, or lapsed no more than grace_days ago
    if sub.status == "active":
        return True
    # status is "lapsed" here
    # Billing keeps serving customers while payment retries run; see the payments runbook.
    return (today - sub.renews_on).days <= sub.grace_days

# After, step 1 [rename and extract; behavior unchanged]
def is_active(sub):
    return sub.status == "active"

def is_within_grace_period(sub, today):
    # status is "lapsed" here
    # Billing keeps serving customers while payment retries run; see the payments runbook.
    return (today - sub.renews_on).days <= sub.grace_days

def can_access(sub, today):
    return is_active(sub) or is_within_grace_period(sub, today)

# Step 2 [separate behavior note, needs the owner's decision]
#   replace the first comment in is_within_grace_period with:
#   assert sub.status == "lapsed", "only lapsed subscriptions have a grace period"
```

Step 1 is a refactoring: for every status, including an unexpected third one, the result is the same as before. The what-comment is gone because two names now carry it; the assumption comment stays until its replacement exists. Step 2 would make a third status fail loudly instead of being treated as lapsed, which changes behavior, so it is reported and decided separately rather than folded into step 1.

## Anti-patterns

- **Comment as caption.** A comment above every block of a long method. Detect: comments whose text matches the intent of the next ten lines.
- **Narrating variable.** `# tmp holds the sum` next to `tmp`. Detect: a comment that renames an identifier.
- **Assertion as validation.** `assert user_input...` on external input. Detect: an assert on data that arrives from a user, a file or a network.
- **Deleted rationale.** Removing a why-comment while "cleaning up". Detect: a removed comment containing "because", a ticket id or a contract name.
- **Stale comment.** A kept comment that no longer matches the code. Detect: a comment mentioning a parameter or branch that no longer exists.

## Trade-offs and exceptions

- Comments that explain why, external constraints or algorithms that have already resisted simpler structure may stay; the source permits it.
- An assertion can be disabled in some runtimes; if the assumption protects data or security, use a real check and an explicit error instead.
- Added judgment: adding an assertion is behavior-preserving only when the invariant holds for every state the code can reach. If any caller can reach another state, the assertion changes behavior; label it and report it instead of counting it as refactoring.
- Added judgment: a public API comment (docstring) that documents a contract is not the smell; it is the "external contract" the source says to keep.

## Verification

- [ ] Each remaining comment explains why, a constraint, a contract or a non-obvious algorithm.
- [ ] Each removed comment has a replacing name, variable, method or assertion.
- [ ] No assertion guards normal input or recoverable errors.
- [ ] Extracted names state purpose.
- [ ] Tests ran after each extraction or rename.

## Related

`refactoring-guru-composing-methods` for Extract Method and Extract Variable; `refactoring-guru-conditional-moves` for Introduce Assertion mechanics; `refactoring-guru-method-call-moves` for Rename Method; `refactoring-guru-comment-reviewer` to review a diff.

## Source

- `Dispensables`: only the Comments entry.
- `Comments`
- `Smell-to-Treatment Priority Map`: only the Comments row.
- `Smell Exception Rules`: only the rule that comments explaining why may stay.
- `Long Method`: only the rule to extract a fragment that needs a comment.
- `Safety and Tradeoff Rules`: only the preferences for names and extracted methods before comments, and for assertions on invariants.
- `Composing Methods Playbook`: only the Extract Variable entry.
- `Conditional and Method Call Playbook`: only the Introduce Assertion and Rename Method entries.
- `Decision Anti-Patterns`: only the rule on assertions for normal input.
