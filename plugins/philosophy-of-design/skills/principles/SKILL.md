---
name: principles
description: "Applies A Philosophy of Software Design to module, API and refactoring decisions. Use for any task that creates, reviews or changes code where complexity, module depth, information hiding, interface shape or tactical patching matter."
---

# A Philosophy of Software Design principles

Fight complexity directly: a change is good when the next reader has fewer things to hold in mind and the next change touches fewer places, not when the code is shorter, smaller or more familiar.

## When the rules apply

- You design or change a module, class, service, package or public API, and the main risk is that callers must know too much.
- A feature feels awkward: one edit spreads across files, a reviewer has to reconstruct hidden dependencies, or the obvious fix adds another flag.
- You are about to add a layer, wrapper, helper, option, callback, pattern or framework and need to show it earns its place.
- You review a diff, a design note or a refactoring for depth, leakage, special cases, comments, names or test coupling.
- A user asks why a design is hard to live with, or which of two designs is better.
- Not for: dependency direction between architectural layers (use a Clean Architecture plugin), line-level readability hygiene such as small-function cleanup of touched code (use a Clean Code plugin, and see the README for how the two disagree), production failure policy such as timeouts and retries (use a release-engineering plugin), or reshaping untested legacy code (characterize first with a legacy-code plugin, then come back).

## The bias this rule set corrects

An agent that has produced working code tends to treat "it passes, the pieces are small, the pattern is familiar" as proof of simplicity. So it wraps a library in a class that forwards every call, splits a function into five three-line helpers, adds a boolean parameter for the new caller, exposes one more field so a second module can finish the job, and writes a comment above an awkward name. Each step looks like good practice. Added together they increase the number of facts a reader must hold, scatter one decision across files, and push work onto every caller. The discipline this rule set asks for is to judge each change by its effect on the reader's burden and on future change: hide more behind a stable interface, remove special cases from callers, and treat surprise and long explanations as evidence that the abstraction is wrong. It is also a discipline of proportion: the improvement lives in the code the task touches, not in a rewrite.

## Loading the rules

1. For every design or code decision, Read `${CLAUDE_SKILL_DIR}/references/mini.md` first.
2. Read `${CLAUDE_SKILL_DIR}/references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `${CLAUDE_SKILL_DIR}/references/nano.md` is the compact always-on form; the optional SessionStart hook injects it.

Modal convention: an unqualified rule is a MUST, `Prefer` is a SHOULD, `Do not`, `Avoid` and `Never` are MUST NOT, unless the user explicitly overrides it. Skills in this plugin keep that strength: where the source says "Prefer", the skill says "Prefer". Text marked "Added judgment" is this plugin's own heuristic, not a rule of the source.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `philosophy-of-design:lead` (delegate) |
| Review the working diff or named paths | `/philosophy-of-design:review` |
| Complexity health of a directory or repository | `/philosophy-of-design:audit` |
| Which modules are shallow, ranked | `/philosophy-of-design:depth-map` |
| A change felt awkward, touched many files, or was hard to follow | `/philosophy-of-design:symptom-trace`, `/philosophy-of-design:complexity-symptoms`, `philosophy-of-design:complexity-reviewer` |
| Plan a non-trivial change before editing | `/philosophy-of-design:plan` |
| Choosing between two designs for an interface or module | `/philosophy-of-design:design-twice`, `/philosophy-of-design:design-alternatives` |
| Pin down a module's contract before writing the body | `/philosophy-of-design:comments-first`, `philosophy-of-design:contract-writer` |
| Resolve named findings | `/philosophy-of-design:fix` |
| Understand one rule or its exceptions | `/philosophy-of-design:explain-rule` |
| Walk the final checklist while working | `/philosophy-of-design:checklist` |
| Strict pass or fail before commit or pull request | `philosophy-of-design:final-gate` (delegate) |
| Designing a module so its interface is small and the work behind it is real | `/philosophy-of-design:deep-modules`, `philosophy-of-design:depth-reviewer` |
| A service, wrapper, facade or helper only forwards calls | `/philosophy-of-design:pass-through-layers`, `/philosophy-of-design:collapse-layer`, `philosophy-of-design:module-deepener` |
| Format, storage shape, protocol or representation known by several modules | `/philosophy-of-design:information-hiding`, `philosophy-of-design:leakage-reviewer` |
| Shape of a public function, method or API | `/philosophy-of-design:interface-design`, `philosophy-of-design:interface-reviewer`, `philosophy-of-design:interface-simplifier` |
| Boolean or mode parameters, configuration knobs, callbacks added to avoid a decision | `/philosophy-of-design:flags-and-knobs` |
| Callers must call things in a fixed order, or code is prepare/process/finalize | `/philosophy-of-design:temporal-decomposition`, `philosophy-of-design:temporal-reviewer` |
| Callers repeat the same setup, checks or special handling | `/philosophy-of-design:pull-complexity-down`, `philosophy-of-design:caller-burden-reviewer` |
| Validation and exceptions piling up around an operation | `/philosophy-of-design:define-errors-away`, `philosophy-of-design:exception-reviewer` |
| Rare cases cluttering the main path, or an interface fitted to one caller | `/philosophy-of-design:generality-and-special-cases`, `philosophy-of-design:special-case-reviewer`, `philosophy-of-design:special-case-isolator` |
| Quick patch, copy and paste, one more exposed detail | `/philosophy-of-design:strategic-programming`, `philosophy-of-design:tactical-patch-reviewer` |
| Comments that narrate, excuse, or are missing where a contract belongs | `/philosophy-of-design:comments-as-design`, `philosophy-of-design:comment-reviewer` |
| Long function or many tiny helpers, pass-through variables | `/philosophy-of-design:functions-and-variables`, `philosophy-of-design:function-depth-reviewer` |
| Extract, split or merge functions, classes, files or services | `/philosophy-of-design:split-or-merge`, `philosophy-of-design:split-merge-reviewer` |
| Naming, conventions across related operations, surprising behavior | `/philosophy-of-design:naming-and-obviousness`, `philosophy-of-design:naming-reviewer` |
| Optimization, caching, or adopting a pattern, framework or paradigm | `/philosophy-of-design:performance-and-trends`, `philosophy-of-design:evidence-reviewer` |
| Tests that reach into internals or force exposure | `/philosophy-of-design:testing-through-interfaces`, `philosophy-of-design:test-contract-reviewer`, `philosophy-of-design:test-writer` |
| Session-long behavior: teach the reasoning | `/output-style philosophy-of-design:mentor` |
| Session-long behavior: ranked findings only | `/output-style philosophy-of-design:strict-reviewer` |
| Session-long behavior: small narrated steps | `/output-style philosophy-of-design:pair` |
| Session-long behavior: result first, few lines | `/output-style philosophy-of-design:terse` |
| Session-long behavior: design before code, two designs for non-trivial choices | `/output-style philosophy-of-design:architect` |
| Session-long behavior: end every code answer with a complexity ledger | `/output-style philosophy-of-design:complexity-ledger` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep cleanup within the scope of the task. The book asks for a clearer structure after a substantial edit; it does not ask for a rewrite. When the right fix is larger than the request, finish the request and propose the larger change instead of making it silently.

## Final checklist

The first eight are the source's review checklist; the last two come from its compact checklist.

- [ ] The change reduced cognitive load, or at least did not raise it.
- [ ] The touched module is deeper than before, or no shallower.
- [ ] More complexity sits behind a stable interface.
- [ ] Special-case handling at call sites went down, not up.
- [ ] An implementation detail was removed from the public surface, or at least none was added.
- [ ] No pass-through layer, thin wrapper or rename-only helper was added.
- [ ] The interface describes the abstraction, not the mechanism.
- [ ] Future changes are more local, not just this one more convenient.
- [ ] Names are precise and consistent, comments are current and not duplicative, and repository conventions were followed.
- [ ] Common cases are automatic, and rare controls, performance tricks, special cases and exception details stay out of the common path; any added complexity has evidence or a caller need behind it.

Added judgment: items 4 and 5 ask for a reduction or a removal. Read them as "not worse" when the change touches no call sites or no public surface, or mark them n/a with the reason. Treating an item without evidence as a failure is this plugin's own gate rule; the source only says that any no means revise.

If any answer is no, revise before shipping. `/philosophy-of-design:checklist` walks this list with evidence, and `philosophy-of-design:final-gate` returns PASS or FAIL on the first eight. When you report the work, say briefly what changed, which tests or checks ran, and any unresolved trade-off.

## Source

- `Purpose`
- `Primary Directive`
- `Core Complexity Rules`
- `Review Checklist`
- `Final Instruction`
