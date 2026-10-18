---
name: "prototypes"
description: "Use when building a throwaway experiment, spike or proof of concept, or when prototype, spike or demo code is about to be reused in production. Covers what it proves, isolation, and the discard-or-harden decision. A kept thin slice is `$pragmatic-programmer:tracer-bullets`; generated scaffolds are `$pragmatic-programmer:generators-and-dsls`."
---

# Prototypes

A prototype exists to answer a question, then to be discarded or deliberately hardened. This skill governs the experiment and its graduation. The path you intend to keep and extend is `$pragmatic-programmer:tracer-bullets`; to write the charter or review a promotion, run `$pragmatic-programmer:prototype-charter`.

## When to use

- Someone asks for a spike, proof of concept, demo or "quick experiment".
- A decision depends on whether an approach, library or algorithm works at all.
- Prototype, spike or demo code is about to be imported by, copied into or merged with production code.
- A prototype's result is being quoted as a delivery date or as evidence of performance.

## Rules

1. **Use prototypes to learn, not to pretend you are done.** [MUST] Check: the prototype has a stated question, and nobody reports "done" on the strength of it.
2. **Be explicit about what a prototype proves and what it does not.** [MUST] Check: a header or charter has a "Proves" line and a "Does not prove" line.
3. **Write the question down before the first line of code.** [Added judgment] Check: the question can be answered yes or no, or with a number, from the prototype's output.
4. **Do not let experimental shortcuts silently become production defaults.** [MUST NOT] Added judgment on what to list: hard-coded paths or credentials, no error handling, in-memory storage, a single-user assumption, no authorization, fixed sleeps, no tests. Check: every shortcut is listed where the next reader will see it.
5. **Carry forward only the lessons or code that still deserve to survive.** [MUST] Check: for each file there is a decision: discard, rewrite from the lessons, or harden and keep.
6. **Do not promote experimental code to production without redesign or hardening.** [MUST NOT] Check: promotion is a change like any other, with tests, error handling and review.
7. **When prototype code, scaffolds, diagrams, specs or tool output start becoming production truth, inspect, understand, harden, replace or reject them deliberately.** [Compact checklist] Check: the moment production code imports prototype code is noticed and decided, not drifted into.
8. **Isolate the prototype.** [Added judgment] Give it its own directory, branch or flag and a name that says what it is. Check: a search of production paths finds no import of the prototype.
9. **Choose between a prototype and a tracer slice by what you need to learn.** [Added judgment] Prototype: "can this work, or which option is better", and you expect to throw the code away. Tracer slice: the path is intended, unproven end to end, and will be extended. Check: the choice and its reason are stated.
10. **Bound the experiment.** [Added judgment] Decide in advance what evidence or how much time ends it. Check: a stopping condition exists.
11. **Record the lessons where the team will find them.** [Added judgment] The code may be deleted; the findings must not be. Check: the result is in an issue, decision note or commit message.

## Procedure

1. Write the question and the stopping condition.
2. Choose the lightest medium that can answer it: a script, a notebook, a mock-up, a paper sketch.
3. Write the header: Proves, Does not prove, Shortcuts, Fate.
4. Build it in an isolated place and run it.
5. Record the answer and the surprises.
6. Decide the fate of each artifact: discard, rewrite from the lessons, or harden. If hardening, list what is missing (tests, error handling, security, observability) and do it as a normal change.
7. Delete what is not carried forward.

## Example

A spike to find out whether fuzzy matching can find duplicate customers well enough to automate merges.

```python
# PROTOTYPE - not for production. Lives in experiments/dedupe_spike/; production code must not import it.
# Question: does fuzzy matching on name + postcode separate true duplicates from near-misses
#           on the 2,000-row sample export?
# Proves (if it works): the approach and a usable score threshold on that sample.
# Does not prove: speed on millions of rows, behavior on non-Latin names, behavior under concurrent writes.
# Shortcuts: reads a CSV from the developer's disk, no tests, prints instead of logging, thresholds hard-coded.
# Stop when: the false-positive list has been reviewed by support, or after two days.
# Fate: keep the findings (threshold analysis, sample of false positives). Rewrite the normalizer with tests.
#       Discard everything else.
```

Outcome note, written when the spike ends: "Fuzzy matching on name plus postcode found 91% of known duplicates on the sample with 3 false merges in 400 candidates; false merges need human review. Production work: a candidate queue with manual confirmation, not automatic merge." The numbers are illustrations. The prototype code is deleted; the note and the normalizer's lessons survive.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Promoted spike | `experiments/` or `spike/` code imported from production paths | Rewrite or harden under review |
| Demo in main | "temporary demo" code merged with no marker | Label and isolate, or remove |
| Hidden shortcuts | A prototype with no list of what it skips | Write the Shortcuts line |
| Prototype as evidence | A prototype's speed or success quoted as a production estimate | State what it does not prove |
| Tested into permanence | A few tests added to a prototype until nobody dares delete it | Decide its fate first |
| Endless experiment | A prototype with no stopping condition | Add one, or stop |

## Trade-offs and exceptions

- Sometimes a prototype turns out good enough to keep. The source allows carrying code forward when it deserves to survive; what it forbids is doing so silently. Harden it as a deliberate change.
- A prototype need not be code. A mock-up or a paper sketch answers some questions at lower cost (Added judgment).
- Demo code with a known, short lifetime is fine when it is labelled and isolated.
- If the path is certain and only unproven end to end, a thin slice you keep is better than a prototype you discard (`$pragmatic-programmer:tracer-bullets`).

## Verification

- [ ] The question and the stopping condition were written before the code.
- [ ] The header lists what it proves, does not prove, and its shortcuts.
- [ ] No production path imports the prototype.
- [ ] Every artifact has a fate: discard, rewrite or harden.
- [ ] The findings are recorded somewhere that outlives the code.

## Related

`$pragmatic-programmer:prototype-charter` to write or audit the charter; `pragmatic-programmer-provenance-reviewer` to review code of unclear origin; `$pragmatic-programmer:tracer-bullets` for the kept path; `$pragmatic-programmer:generators-and-dsls` for scaffolds and generated code.

## Source

- `Prototyping Rules`
- `Prototype Fossilization`
- `Tracer Bullets and Iterative Delivery`: only the anti-pattern of treating prototypes as production without hardening, and the contrast with a slice that is refined from feedback.
