---
name: "pragmatic-programmer-tracer-bullets"
description: "Use when starting a new capability, sizing or sequencing work, or when many layers are being built before anything runs end to end. Covers thin end-to-end slices, small increments and honest estimates. A throwaway experiment is `prototypes`; the need itself is `requirements`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Tracer bullets

Sequence and size delivery so that a thin, real, end-to-end path runs first and everything else is refined from working feedback. A throwaway experiment is `pragmatic-programmer-prototypes`; deciding what is actually being asked is `pragmatic-programmer-requirements`. To write a slice down, run `pragmatic-programmer-tracer-plan`.

## When to use

- A new capability crosses several layers or systems (UI, API, queue, database, third party).
- The plan is to build the data layer, then the service, then the API, then the UI, with nothing runnable until the end.
- A plan or estimate is requested for work with open unknowns.
- Integration is being postponed "until the pieces are done".

## Rules

1. **Prefer a thin end-to-end slice over a pile of isolated pieces.** [SHOULD] Check: after the first unit of work, one command or test exercises input to output.
2. **Use tracer bullets to validate architecture, integration and assumptions early.** [MUST] Check: the slice crosses every boundary the design depends on (the real database, the real route, the real third-party contract) and the riskiest assumption is among them.
3. **Keep the first slice simple but real enough to prove the path.** [MUST] Simple means trivial logic, one case, hard-coded policy. Real means the actual deployment unit, storage and interfaces. Check: swapping the trivial logic for the real logic changes nothing about the path.
4. **Refine from working feedback instead of predicting everything up front.** [MUST] Check: the second increment was chosen from what the first run showed.
5. **Do not build many layers before anything runs end to end.** [MUST NOT] Added judgment on the working form: at most one layer is in progress without a runnable path through it. Check: you can run the thing today.
6. **Do not wait for perfect certainty before integrating.** [MUST NOT] Check: integration questions are answered by running something, not by writing more design prose.
7. **Do not treat prototypes as production without hardening.** [MUST NOT] See `pragmatic-programmer-prototypes`. Check: the slice is built to be kept; anything disposable is labelled as such.
8. **Break work into pieces that can be reasoned about, tested and corrected.** [MUST] Check: each piece has an observable done condition.
9. **Keep plans and estimates honest about uncertainty.** [MUST] Added judgment on the form: give a range or a confidence with the assumption that would move it, never one number for work with unknowns. Check: each estimate names its biggest unknown.
10. **Prefer small deliverable increments to large hidden progress.** [SHOULD] Check: progress is shown by running behavior, not by "percent done" of an unmerged branch.
11. **Make risk visible early.** [MUST] Added judgment on the how: order increments so the riskiest assumption is tested first, and say which increment retires which risk. Check: the plan lists risks next to the increments that test them.
12. **By default, avoid overcommitting to an architecture before the first end-to-end path works.** [SHOULD] The source states this as a default for generated code. Check: decisions the slice has not yet exercised are marked provisional.

## Procedure

1. Restate the outcome and list the assumptions the design rests on (does the API accept this payload, can the database do this query at this size, does a deployment path exist).
2. Pick the thinnest path: one input, one output, every boundary crossed.
3. Decide what may be trivial (logic) and what must be real (storage, interfaces, deployment).
4. Build it, run it, and record what surprised you.
5. Choose the next increments from the evidence and order them by risk.
6. Update the estimates with what you learned. `pragmatic-programmer-tracer-plan` writes this down as a plan.

## Example

Capability: send each customer a monthly PDF report by email.

```text
Layered plan (first runnable end to end at step 6)
 1. Query layer for every section of the report
 2. Aggregation service
 3. Report templates
 4. PDF renderer integration
 5. Mail provider integration
 6. "Send report" button in the admin UI

Slice plan (runnable after step 1)
 1. Button -> endpoint -> query one aggregate (total orders) -> render a one-line PDF with the
    production renderer in the production container -> send it through the real mail provider
    to a test mailbox. Proving command: the staging pipeline's smoke job.
    Likely discoveries: fonts missing in the container image, provider needs a verified sender.
 2. Add the sections in order of risk: charts (renderer), the largest customer's data volume (query),
    attachments of realistic size (mail).
 3. Add recipients, scheduling and the remaining sections.
Estimate for step 1: one to three days; the unknown is the mail provider's sender verification.
```

The slice proves integration points with three or four lines of logic, and the estimates for later steps are revised from what step 1 reveals.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Horizontal layering | A plan whose first runnable result is its last step | Cut a vertical slice first |
| Integration phase | "Integrate at the end" in a plan | Integrate in the first slice |
| Faked boundary | A slice whose database, queue and third party are all mocked | Make at least the riskiest boundary real |
| No proving command | A slice nobody can run in one step | Define the command or test |
| Endless spec | Prose grows while open questions stay open | Build the slice (`pragmatic-programmer-requirements`) |
| Single-number estimate | One figure for work with unknowns | Range plus the assumption that moves it |
| Prototype as tracer | Throwaway code that is expected to ship | Label it a prototype or harden it |

## Trade-offs and exceptions

- When the path is already proven in the codebase (a similar feature crosses the same boundaries), a slice adds little; build the feature.
- Some boundaries cannot be crossed for real (a vendor without a sandbox). Added judgment: use a recorded contract fixture, mark the assumption as unproven, and schedule the first real call early.
- A tracer slice is built to be extended. If you intend to discard it, it is a prototype and `pragmatic-programmer-prototypes` applies.
- Estimates are an aid for planning, not a promise; the source asks only that they be honest about uncertainty.

## Verification

- [ ] A single command or test runs the whole path.
- [ ] The slice crosses the boundaries the design depends on, with the riskiest one real.
- [ ] Each later increment has a done condition and an associated risk.
- [ ] Estimates are ranges with a named unknown.
- [ ] Unexercised architecture decisions are marked provisional.

## Related

`pragmatic-programmer-tracer-plan` to write the slice; `pragmatic-programmer-slice-reviewer` to review a plan or change; `pragmatic-programmer-prototypes` for disposable experiments; `pragmatic-programmer-requirements` for what is being asked; `pragmatic-programmer-mode-tracer-first` for a session that works this way.

## Source

- `Tracer Bullets and Iterative Delivery`
- `Estimation and Increment Rules`
- `Code Generation Rules`: only the default of incremental end-to-end slices and the avoidance of overcommitting to an architecture before the first end-to-end path works.
