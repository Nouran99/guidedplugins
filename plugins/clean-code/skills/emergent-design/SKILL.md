---
name: emergent-design
description: "Use when choosing between two designs, deciding whether to add an abstraction, class, layer or dependency, or tempted to redesign. Applies the four-criteria tie-breaker and boring solutions; removing duplication, dead code or pass-through layers is /clean-code:smells-redundancy."
---

# Emergent design

How to choose the shape of code without designing it all up front: let tests, duplication removal and clear intent push the design, and keep the amount of structure to what is needed. Executing a restructure is `/clean-code:refactoring-steps`; removing wasteful structure by name is `/clean-code:smells-redundancy`.

## When to use

- You must choose between two designs, or between adding structure and leaving code plain.
- You are about to add an interface, factory, layer, plugin point or dependency.
- A first draft works but looks rough.
- Someone proposes a redesign of a module that currently works.
- A change request tempts you to optimize something nobody has measured.

## Rules

1. **Prefer the design that passes every relevant test, carries no duplication, shows its intent and needs the fewest classes and methods.** Check: a design that fails a relevant test loses; between designs that pass, prefer the one that satisfies more of the remaining criteria. Added judgment: the source lists the four criteria without ranking them, so when they split, use the conventional order of the simple-design rules (tests, duplication, intent, size) as a tie-breaker, not as a strict lexicographic rule.
2. **Reach clean code by refining working drafts; do not expect the first version to be clean.** A rough draft that works and is tested is a good start. Check: the first commit-sized state passes tests; cleanliness comes in later rounds.
3. **If a draft starts out rough, keep improving its names, structure and tests until the intent is plain.** Check: after each round, reading the code takes less effort than before.
4. **Do not launch a grand redesign if small refinements can safely restore the design.** Check: you can list the small steps that reach the better shape; if you can, take them.
5. **Apply the Boy Scout Rule to code you touch, with cleanup sized to the task.** Check: the cleanup is on code the change reads or modifies. Added judgment: it is also smaller than the change itself; the source says only "proportional".
6. **Prefer plain, explicit solutions that are easy to maintain.** Check: a new teammate could modify it without learning a technique.
7. **Prefer the standard library and patterns the project already uses over a new dependency. Do not add a dependency unless it clearly lowers total complexity.** Check: you can state what code the dependency removes and what it costs in upgrade burden and surface area.
8. **Follow the project's established conventions unless they conflict with these rules or the user asks for something else.** Check: new code looks like its neighbors.
9. **Keep interfaces narrow and make every state transition easy to see.** Check: the public surface lists what callers need today; every state change is a named operation.
10. **Avoid optimizing early; tune only with measurements or a known requirement in hand.** Check: a measurement or a stated requirement exists, and the optimized code is isolated and commented with the reason.
11. **Pay technical debt down rather than relocating it.** Added judgment, elaborating on that rule: moving a conditional into a config file, a plugin registry or a framework annotation does not remove it. Check: the complexity went down for the reader, not just out of sight.
12. **Introduce an abstraction when a second real use or a clarity gain appears, not before.** Added judgment, consistent with the fewest-classes criterion. Check: you can point at two uses, or at a concrete comprehension win.

## Procedure

1. List the candidate designs, including "leave it plain".
2. Score each against the four criteria: tests pass, duplication gone, intent clear, fewest classes and methods. If they split, apply the conventional order from rule 1 as a tie-breaker (Added judgment) and state it.
3. If both are equal, pick the one that matches existing conventions and adds fewer concepts.
4. For a dependency, write the removed code and the new surface area side by side.
5. For a performance idea, find or request the measurement. Without one, defer and note it.
6. Draft, run the tests, then refine in rounds: names, then structure, then duplication, then tests.
7. Stop when the four criteria hold and the diff is proportional to the task.

## Example

```python
# Proposed: a pluggable strategy factory for one notification channel
class NotificationStrategy(ABC):
    @abstractmethod
    def deliver(self, user, message): ...

class EmailStrategy(NotificationStrategy):
    def deliver(self, user, message):
        send_email(user.email, message)

class NotificationStrategyFactory:
    _registry = {"email": EmailStrategy}
    @classmethod
    def create(cls, kind):
        return cls._registry[kind]()

notify = NotificationStrategyFactory.create("email").deliver

# Chosen: the plain function passes the tests, has no duplication, states intent,
# and has the fewest classes. Add structure when a second channel actually exists.
def notify(user, message):
    send_email(user.email, message)
```

When SMS arrives, the function gains a parameter or a second function, and the tests tell you whether the shape holds.

## Anti-patterns

- **Speculative generality.** Interfaces with one implementation, options nobody sets, hooks for hypothetical needs. Detect: one implementer, no test double, no second caller.
- **Grand redesign.** A proposal to rewrite a working module before listing incremental steps. Detect: no step list, no tests-first plan.
- **Dependency for a one-liner.** A package added for a function you could write in ten lines. Detect: the import is used once.
- **Premature optimization.** Caches, pools or hand-tuned loops with no measurement. Detect: no benchmark, no requirement in the commit or comment.
- **Debt relocation.** A branch replaced by configuration or reflection that is harder to read. Detect: tracing a case now requires opening three files.
- **Convention fork.** A new pattern next to an established one for the same job. Detect: two ways of doing it in the same module.

## Trade-offs and exceptions

- The four criteria are a tie-breaker, not a procedure, and their order is Added judgment. Judgment about what "expresses intent" still matters.
- Sometimes an abstraction is required by a framework, a public contract or a test seam; that is a stated reason, not speculation.
- Known requirements justify design earlier than the code demands (for example, a second channel is on this sprint's board).
- When a user asks for a specific design, follow it and mention the conflict; the user's instruction ranks above this skill.
- This skill does not forbid planning. It asks that structure be earned by the problem at hand.

## Verification

- [ ] The chosen design passes all relevant tests.
- [ ] It has no new duplication and expresses intent at least as well as the alternatives.
- [ ] It uses no more classes, methods or layers than the alternatives.
- [ ] Any new dependency has a stated benefit larger than its cost.
- [ ] Any performance work has a measurement or a requirement behind it.
- [ ] The diff is proportional to the task.

## Related

`/clean-code:refactoring-steps` for moving safely; `/clean-code:successive-refinement` for the draft-and-refine loop; `/clean-code:smells-redundancy` for named wasteful structure; `clean-code:simplicity-reviewer` to review a diff.

## Source

- `Emergent design and successive refinement`
- `Implementation preferences`
- `Core clean code principles`
- `Refactoring rules`: only the rule to prefer the simplest design that passes all relevant tests.
