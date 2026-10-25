---
name: "pragmatic-programmer-requirements"
description: "Use when a request names a solution instead of a need ('add a cache', 'use a cron job'), a spec keeps growing without removing uncertainty, or the team hesitates. Covers digging for the real requirement. Delivery order is `pragmatic-programmer-tracer-bullets`; a volatile vendor or format choice is `pragmatic-programmer-reversible-choices`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Requirements

Find out what is actually being asked before building what was literally said. This skill separates a durable need from the solution proposed for it, stops specification from growing without reducing risk, and says when to build instead of asking. How to sequence the build is `pragmatic-programmer-tracer-bullets`; decisions that may change later are `pragmatic-programmer-reversible-choices`.

## When to use

- The request names an implementation ("add a Redis cache", "run it as a cron job", "add a column") and not the outcome.
- A requirements document or thread is getting longer while the open questions stay the same.
- The team hesitates, or you feel unsure about the request.
- An old system's behavior is being copied without anyone saying why.

## Rules

1. **Dig for real requirements.** [MUST] Check: you can state the need as an outcome for a named person or system, without naming a technology.
2. **Do not accept current implementation details as requirements.** [MUST NOT] A detail of the existing system or of the proposed fix is a candidate solution until someone says it is a constraint. Check: every item in the request is classified as need, constraint, proposed solution or inherited detail.
3. **Separate durable needs and constraints from solution proposals, growing prose specifications and unresolved hesitation.** [Compact checklist] Check: the restated need contains none of them.
4. **Do not fall into the specification trap, where prose keeps growing but uncertainty does not fall.** [MUST NOT] Check: after each added paragraph, at least one open question has been closed; if none was, stop writing.
5. **Start building a working slice when further specification no longer reduces meaningful risk.** [MUST] Check: the open questions that remain are ones a running slice would answer.
6. **When prose specifications keep growing without reducing uncertainty, build a working slice, an example or a prototype that forces feedback.** [Compact checklist] Check: the chosen artifact names the question it will answer (`pragmatic-programmer-tracer-bullets` or `pragmatic-programmer-prototypes`).
7. **Respect informed hesitation: if the team is not ready, identify the missing information or feedback.** [MUST] Added judgment for an agent: when you are unsure, say what you would need to know instead of guessing. Check: hesitation is turned into a specific missing fact or an experiment.
8. **Ask only questions whose answers would change the work.** [Added judgment] Check: for each question you can say which decision each possible answer would change.
9. **Record a hard implementation requirement as a constraint with its source.** [Added judgment] A compliance rule, a contract or an existing integration can make a detail binding. Check: the constraint names who set it and why.
10. **Restate the need in the requester's vocabulary and offer options.** [Added judgment] Check: the requester can confirm or correct the restatement in one reply.
11. **Do not send the requester a question that a cheap experiment could answer.** [Added judgment] Check: you tried the experiment, or can say why it is not cheap.

## Procedure

1. Copy the request as written.
2. Write the need: who gains what outcome, with a measure if one is known.
3. Classify each element of the request: need, constraint (with source), proposed solution, inherited implementation detail.
4. List the open questions and mark which a running slice would answer.
5. Choose: ask (the answers change the work), build a slice (more writing will not reduce the risk), or proceed (the need is clear).
6. Restate the need and the options to the requester in their words and wait only if the answer changes what you build.

## Example

```text
Request as written
  "Add a Redis cache in front of the product API."

Classification
  Need (inferred, to confirm): the product page loads fast enough during sales.
  Measure unknown: ask what "fast enough" means (target and where it is measured).
  Constraint: none stated. Ask whether Redis is already operated by the team.
  Proposed solution: a Redis cache.
  Inherited detail: none.

Open questions
  1. Where does the time go today? (a profile answers this; no need to ask)
  2. Is stale data acceptable, and for how long? (changes the design: ask)

Restatement to send
  "I understand the goal is product pages that stay fast during sales. I will measure where the
   time goes first. If it is the database, a cache is one option; adding an index or a read replica
   are others. Is some staleness (say, a few minutes) acceptable for prices and stock?"
```

The restatement keeps the cache as an option, asks the one question that changes the design, and answers the other from a measurement.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Solution-shaped ticket | A request naming a tool, column or mechanism and no outcome | Restate the need, keep the proposal as an option |
| Specification marathon | A growing document with a stable list of open questions | Build a slice that forces an answer |
| Question flood | Many questions whose answers would not change the work | Keep only the ones that change a decision |
| Folklore requirement | "The old system does it" with no reason | Ask why, or record it as an inherited detail |
| Silent guess | A plausible reading chosen without saying so | State the reading and proceed, or ask |
| Hesitation ignored | Uncertainty that never became a named missing fact | Turn it into a question or an experiment |

## Trade-offs and exceptions

- Not every request hides a different need. If the need is clear, proceed; digging for its own sake is a ritual (`pragmatic-programmer-ownership`).
- An inherited detail can be a real constraint (users depend on the old behavior, a regulator requires it). The rule asks you to find out, not to discard it.
- When two readings are plausible and the cost of the wrong one is low, Added judgment: pick one, state it, and proceed.
- Asking has a cost for the requester. Added judgment: batch the questions that matter, and propose your default answer to each.

## Verification

- [ ] The need is stated as an outcome with no technology named.
- [ ] Every element of the request is classified as need, constraint, solution or inherited detail.
- [ ] Constraints name their source.
- [ ] Each question asked would change a decision.
- [ ] If specification stopped reducing risk, a slice, example or prototype was chosen.

## Related

`pragmatic-programmer-tracer-bullets` and `/pragmatic-programmer:tracer-plan` for the slice; `pragmatic-programmer-prototypes` for experiments; `pragmatic-programmer-reversible-choices` for choices that may change; `/pragmatic-programmer:plan` to carry the restated need into a plan.

## Source

- `Reversibility, Domain Languages, and Requirements`: only the rules on digging for real requirements, the specification trap, starting a working slice and informed hesitation.
