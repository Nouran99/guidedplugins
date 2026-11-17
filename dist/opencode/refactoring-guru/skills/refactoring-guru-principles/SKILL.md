---
name: "refactoring-guru-principles"
description: "Applies the Refactoring.Guru rule set to changes of existing code. Use when smells, technique choice, behavior preservation or cleanup scope matter; it routes to the narrower skills, agents and modes of this plugin."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Refactoring.Guru principles

Refactoring is a controlled change to structure, not to behavior. Each one answers a named smell, uses the smallest catalog technique that treats it, has a way to verify, and stops when the smell is gone.

## When the rules apply

- You change existing code and must decide whether structural work comes first, comes afterwards, or does not belong in this change at all.
- A review, a user or your own reading names a smell (long method, feature envy, shotgun surgery, data clump) or you suspect one.
- You must pick between catalog techniques for a diagnosed smell, or check that a technique you are about to perform is safe.
- You are asked to clean up, extract, move, rename, inline, simplify a condition or delete unused code.
- Not for: designing new behavior or architecture (use a design plugin such as `philosophy-of-design`, `clean-architecture` or `ddd`); code whose behavior is unclear or untested (characterize it first, see `legacy-code`); local readability rules such as naming and function shape (see `clean-code`). If you also load the `refactoring` plugin, keep one refactoring rule set as primary; they overlap heavily.

## The bias this rule set corrects

An agent asked to improve code tends to treat refactoring as a general tidy-up: it renames, reformats and restructures whatever looks untidy, folds a behavior change into the same edit, reaches for a pattern because the name sounds modern, and keeps going because the next smell is also visible. The rule set replaces that with a loop that is repeated for each smell:

1. **Diagnose.** Name the visible symptom, the maintenance cost it creates, whether it is local, repeated or architectural, and whether it is a real problem or a style preference.
2. **Treat.** Choose the catalog technique that directly addresses the smell, smaller before larger, and write down the cleaner end state you expect.
3. **Verify.** Identify the check before moving code, run it after each risky step, and stop calling the change a refactoring the moment behavior changes.
4. **Stop.** Stop when the named smell is gone or materially reduced, record other smells separately, and say so when a visible smell is deliberately left.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need, for example `Smell-to-Treatment Priority Map` for the preferred, fallback and risky treatment of one smell, or `Technique Playbook` for the use, avoid, safe-steps and verification entry of one technique.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/refactoring-guru/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention of the source: `MUST` is binding, `SHOULD` is a strong default (deviate only with a stated reason), `MUST NOT` is forbidden, `MAY` is permitted. Added judgment: read technique bullets of the form "Use X when Y" as directives conditioned on Y. Components in this plugin keep that strength: where the source says `SHOULD`, the skill says "prefer" or "should". Text marked "Added judgment" is this plugin's own heuristic, not a rule of the source; text marked "compact checklist" comes from the compressed files only.

## Subagent roles

Names such as `refactoring-guru-lead`, `refactoring-guru-final-gate` and the `...-reviewer` roles in the routing table are subagents. The OpenCode, Gemini CLI, Cursor and Copilot builds ship them as subagents, the MCP server serves them with get_guide, and in Codex they are installed separately; the plain Agent Skills build does not include them. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `refactoring-guru-lead` (delegate) |
| Review the working diff or named paths | `refactoring-guru-review` |
| Where to look: smell hot spots in a directory or repository | `refactoring-guru-audit` |
| One smell: what to do, in what order, when to stop | `refactoring-guru-smell-to-treatment` |
| Plan a non-trivial change before editing | `refactoring-guru-plan` |
| Resolve specific findings | `refactoring-guru-fix`, or `refactoring-guru-refactorer` for a longer list |
| Understand one rule, smell or technique | `refactoring-guru-explain-rule` |
| Walk the review checklist while working | `refactoring-guru-checklist` |
| Strict pass or fail before commit or pull request | `refactoring-guru-final-gate` (delegate) |
| Is this hunk a refactoring, a feature or a bug fix; how to split a mixed patch | `refactoring-guru-classify-change`, `refactoring-guru-intent-reviewer`, `refactoring-guru-mode-labeled-steps` |
| How to carry a refactoring out; separation, small steps, checks | `refactoring-guru-refactoring-process` |
| Whether or when to refactor; third occurrence; technical debt | `refactoring-guru-when-to-refactor`, `refactoring-guru-debt-triage` |
| Which technique among several; reject a mechanical pattern choice | `refactoring-guru-treatment-choice` |
| Another smell appeared; cleanup keeps growing; leave a smell on purpose | `refactoring-guru-stop-and-defer`, `refactoring-guru-scope-guard` |
| Do the checks protect each step; no net exists yet | `refactoring-guru-safety-net-reviewer`, `refactoring-guru-characterizer` |
| Method too long, class too large, fields valid only sometimes | `refactoring-guru-size-smells`, `refactoring-guru-bloat-reviewer` |
| Extracting a fragment, inlining, temporaries, method object | `refactoring-guru-composing-methods`, `refactoring-guru-method-extractor`, `refactoring-guru-method-body-reviewer` |
| Primitives, arrays, magic numbers, long parameter lists, data clumps | `refactoring-guru-data-smells`, `refactoring-guru-data-modeling-reviewer` |
| Value, reference, association, encapsulation changes; new value type | `refactoring-guru-organizing-data`, `refactoring-guru-type-introducer` |
| Signature or call-shape change: query/modifier, flags, setters, error codes | `refactoring-guru-method-call-moves`, `refactoring-guru-call-contract-reviewer` |
| Switch or repeated if chain on a type, mode or status | `refactoring-guru-type-codes-and-switches`, `refactoring-guru-type-switch-reviewer` |
| Simplify a local condition, guard clauses, assertions | `refactoring-guru-conditional-moves` |
| One change touches many files; class changes for many reasons; duplicated logic | `refactoring-guru-change-locality`, `refactoring-guru-change-locality-reviewer` |
| Behavior sits away from its data, data-only classes, classes that know each other's internals | `refactoring-guru-behavior-ownership`, `refactoring-guru-coupling-reviewer` |
| Moving a member, extracting or inlining a class | `refactoring-guru-moving-features`, `refactoring-guru-responsibility-mover` |
| Call chains, pass-through classes, workarounds for a library gap | `refactoring-guru-delegation-and-gaps`, `refactoring-guru-coupling-reviewer` |
| Inheritance that refuses, mirrors or duplicates; pull up, push down, delegation | `refactoring-guru-hierarchies`, `refactoring-guru-hierarchy-reviewer` |
| Unused or speculative code, near-empty classes | `refactoring-guru-dead-weight`, `refactoring-guru-dead-weight-reviewer`, `refactoring-guru-dead-code-remover` |
| Before deleting, renaming or changing something others may reach | `refactoring-guru-public-compatibility`, `refactoring-guru-reachability-check`, `refactoring-guru-compatibility-reviewer` |
| Comments that explain confusing code | `refactoring-guru-explanatory-comments`, `refactoring-guru-comment-reviewer` |
| Session-long behavior: teach the reasoning | `refactoring-guru-mode-mentor` |
| Session-long behavior: ranked findings only | `refactoring-guru-mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `refactoring-guru-mode-pair` |
| Session-long behavior: result first, few lines | `refactoring-guru-mode-terse` |
| Session-long behavior: a smell, technique, check and stop card before every edit | `refactoring-guru-mode-treatment-card` |
| Session-long behavior: every change tagged refactor, feature or bug fix | `refactoring-guru-mode-labeled-steps` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This rule set.

Keep cleanup proportionate to the task: the source allows stopping when the code is cleaner enough for the requested change and further cleanup is speculative. Do not widen scope to satisfy a smell you happened to see.

## Final checklist

- [ ] The change is clearly a refactoring, a feature or a bug fix, and the boundary between them is visible.
- [ ] The code is cleaner in the touched area.
- [ ] A named smell justified each transformation.
- [ ] The smallest suitable technique was used.
- [ ] All relevant tests passed.
- [ ] Any public interface change received compatibility handling.
- [ ] Duplication, bloat, coupling or unclear control flow went down.
- [ ] No speculative abstraction was added.
- [ ] No needless polymorphism, inheritance or bidirectional association was added.
- [ ] Every smell that remains in touched code is explicitly deferred rather than hidden.

When you report the work, say which technique was used, which stop condition was reached, and which validation ran.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Refactoring.Guru is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Refactoring.Guru would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Source and Scope`: only the statement of the modal convention and the fact that the rules are paraphrased guidance for agents.
- `Purpose`
- `Primary Directive`
- `Refactoring Workflow for Agents`
- `Review Checklist`
