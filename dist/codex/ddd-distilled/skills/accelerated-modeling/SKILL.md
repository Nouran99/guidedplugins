---
name: "accelerated-modeling"
description: "Use when workflow, events, commands, policies or team language are unclear, when modeling risks turning into detached analysis, or when delivery pressure tempts skipping design. Covers event storming, timeboxes, spikes, scenarios and expert involvement. Procedure: $ddd-distilled:event-storm."
---

# Accelerated modeling

How to learn the domain quickly without either skipping the learning or disappearing into analysis. The book's tools are event storming (or a similar collaborative technique), timeboxes, modeling spikes, expert walkthroughs, scenarios and acceptance tests, plus a record of what was deferred. The interactive procedure is `$ddd-distilled:event-storm`; sizing is `$ddd-distilled:estimate-work`; the debt register is `$ddd-distilled:modeling-debt`.

## When to use

- Nobody can say what happens first, what triggers what, or who decides.
- The team uses three words for one thing and cannot settle them by reading code.
- A design discussion has run past its usefulness without producing a code decision.
- A deadline is pushing the team to write code before the concept is understood.

## Rules

1. **Use event storming or a similar collaborative technique when workflow, events, commands, policies or team language are unclear.** Unclear language is cheaper to fix on a wall than in code. Check: the unclear thing is named, and the people who know it are in the session.
2. **Timebox modeling so it improves implementation instead of becoming detached analysis.** Check: the session has a stated limit and a stated output that feeds the next code change.
3. **Use modeling spikes to reduce uncertainty before committing to a model shape.** Check: each spike has one question, a time limit and an exit decision.
4. **Involve domain experts in scenario walkthroughs, terminology decisions and acceptance criteria.** The code cannot be more correct than the facts. Check: the output says who confirmed each business statement.
5. **Use scenarios and acceptance tests to validate that the model expresses real business behavior.** Check: each modeled behavior has a scenario in business language that the expert accepted.
6. **Track modeling debt when code and language are known to be imperfect but deliberately deferred.** Check: deferred items are in a register with a repayment trigger (`$ddd-distilled:modeling-debt`).
7. **Estimate DDD work from modeling uncertainty, integration risk and implementation cost, not from feature count alone, and treat team skill and expert access as constraints.** Check: an estimate states these inputs (`$ddd-distilled:estimate-work`).
8. **When delivery pressure would skip design, run a short spike, scenario or acceptance test and record the known modeling debt.** (Compact checklist) Check: skipping is never silent; the shortcut and its cost are written down.
9. **An agent is not the domain expert.** (Added judgment) Ask the user for the missing business facts, mark assumptions as provisional, and do not fill gaps with invented rules. Check: every business rule in the output traces to the user, existing code, tests or documents, or carries an "assumed" label.
10. **Turn every session into artifacts the code can use.** (Added judgment) Glossary entries, scenarios, candidate contexts, spike results and debt items. Check: nothing valuable lives only in a conversation.

## Procedure

1. State the uncertainty in one sentence and what it costs if the team guesses wrong.
2. Choose the lightest tool: a scenario walkthrough for one rule, a spike for one question, an event storm for an unclear workflow.
3. Set the time limit and the output before starting.
4. Collect facts from the user and from the code; keep a list of assumptions.
5. Write scenarios in the business's language and ask for confirmation of each.
6. Convert results: terms into the glossary, scenarios into tests, candidate boundaries into the context notes, deferred items into debt.
7. Stop at the limit and decide: is there enough to implement the next slice? If not, plan the next spike rather than extending this one.

## Example

```text
Modeling spike: when is a seat hold released?
Question:  Does a hold expire on a timer, on payment failure, or both?
Timebox:   45 minutes with the box-office lead.
Method:    Walk three scenarios: card declined, browser closed, group of eight splits payment.
Exit:      One sentence the lead agrees with, and the scenarios saved as acceptance tests.
Output:    SeatHeld, HoldExpired and HoldReleased added to the glossary.
           Open question "partial group payment" recorded as modeling debt,
           owner: box-office lead, revisit before group sales launch.
```

The spike ends with a decision the code can use and one explicit loose end, rather than with a longer document.

## Anti-patterns

- **Endless analysis.** Detect: sessions with no limit and no output.
- **Invented rules.** Detect: business statements with no source and no "assumed" label.
- **Silent shortcut.** Detect: a deadline-driven change with no scenario and no debt entry.
- **Workshop theatre.** Detect: a wall of notes that never reaches a glossary, a test or a code decision.
- **Spike without an exit.** Detect: no question, or no condition under which it stops.

## Trade-offs and exceptions

- The rule says "event storming or similar": any collaborative technique that surfaces events, commands and policies fits. Obvious, small changes need none.
- The rule set does not prescribe a step-by-step event storming method; the steps in `$ddd-distilled:event-storm` are this plugin's judgment (Added judgment).
- Timeboxing does not mean skipping hard questions; it means deciding how much certainty is needed before the next slice.
- When no expert is reachable, continue with labeled assumptions and a scheduled confirmation, not with silent guesses.

## Verification

- [ ] The uncertainty is named, with a timebox and an output.
- [ ] Experts confirmed each business statement, or the statement is marked assumed.
- [ ] Scenarios exist in business language for the modeled behavior.
- [ ] Deferred items are recorded as modeling debt.
- [ ] Results reached the glossary, the tests or the context notes.

## Related

`$ddd-distilled:event-storm`; `$ddd-distilled:estimate-work`; `$ddd-distilled:modeling-debt`; `$ddd-distilled:domain-tests`; `$ddd-distilled:adoption-fit`.

## Source

- `Accelerated Modeling and Project Rules`
- `Adoption Fit and Modeling Investment`: only the rule to use scenarios and acceptance tests to validate the model.
