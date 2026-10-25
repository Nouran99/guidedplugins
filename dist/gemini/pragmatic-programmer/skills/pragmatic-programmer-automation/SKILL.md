---
name: "pragmatic-programmer-automation"
description: "Use when work depends on repeated manual steps: setup, build, test, lint, package, deploy or release rituals, README step lists, 'works on my machine' scripts, or bulk edits made by hand. Slow or flaky checks are `pragmatic-programmer-feedback-loops`; code derived from a spec is `pragmatic-programmer-generators-and-dsls`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Automation

Turn repeated, error-prone or easy-to-forget work into a script that lives with the code. This skill covers setup, build, test, lint, format, package, deploy and release steps, and bulk mechanical edits. How fast and how clearly checks report is `pragmatic-programmer-feedback-loops`; deriving code from a specification is `pragmatic-programmer-generators-and-dsls`; to scan a repository for rituals, run `/pragmatic-programmer:manual-step-hunt`.

## When to use

- A README or wiki lists numbered steps a person must follow to build, test, set up or release.
- "It works on my machine", or local commands differ from what CI runs.
- A release depends on someone remembering prerequisites.
- You are about to make the same mechanical edit by hand in many files.
- A document describes what a script ought to do, and no such script exists.

## Rules

1. **Automate repetitive, error-prone or easy-to-forget tasks.** [MUST] Check: for each such task there is a command that does it.
2. **Prefer repeatable scripts over tribal-knowledge commands.** [SHOULD] Check: a new contributor can run the task from the repository alone.
3. **Make build, test, lint, format, package and deploy steps reproducible.** [SHOULD] Check: from a clean checkout, one documented command produces the same result on two machines.
4. **Keep local automation aligned with the project's shared build, test and release automation.** [MUST] Check: the local command and CI call the same script or target, not two copies of the steps.
5. **Do not hand-do tasks that should be scripted.** [MUST NOT] Added judgment on the threshold: when a step has been done by hand twice and a third time is plausible, script it. Check: no instruction asks a person to repeat a sequence a script could run.
6. **Do not ship "works on my machine" build steps or hidden local environment assumptions.** [MUST NOT] Check: the script states its prerequisites (tool versions, environment variables) and fails clearly when one is missing.
7. **Do not run releases as manual rituals with many hidden prerequisites.** [MUST NOT] Check: a release is one command plus approvals, and its prerequisites are checked by the command.
8. **Do not let documentation describe what a script should do instead of having the script, and do not let checklists stand in for automation.** [MUST NOT] Check: a step list in prose points to a script, or is a script.
9. **Keep automation versioned with the code.** [Compact checklist] Check: scripts, build files and CI definitions are in the same repository and change in the same pull request as the code they serve.
10. **Know the tools that amplify correctness and speed, and improve the toolchain when repeated friction appears.** [MUST] Check: friction you hit twice is either fixed in the toolchain or on the follow-up list.
11. **Use shell tools for exploration, automation and repeatable transformations where they fit, editor capabilities to reduce repetitive manual edits, and text-manipulation scripts for systematic changes that would be error-prone by hand.** [MUST] The qualifier "where they fit" is the source's and stays. Check: a bulk rename or rewrite is a reviewable script or codemod, and its result was inspected.
12. **Use source control for every meaningful project, including small or solo work.** [MUST] Check: scripts and configuration are tracked, not left in a home directory.
13. **Make destructive automation opt-in.** [Added judgment] A script that deletes, deploys or migrates defaults to a dry run or requires an explicit flag. Check: running it with no arguments changes nothing irreversible.

## Procedure

1. List the manual steps involved in the task, in order, including the ones that live only in someone's memory.
2. Mark each: repeated, error-prone, easy to forget, or one-off. Keep the first three.
3. Write one script (or build target) that performs the steps, checks its prerequisites, stops on the first failure and prints what it did.
4. Make CI and local runs call that script.
5. Replace the prose step list with one line that names the script.
6. Run the script from a clean checkout and fix what it assumed.

## Example

```text
Before (README)
  To check a change: 1. run the linter. 2. run the tests. 3. build the wheel. 4. If CI fails because
  you forgot step 1, run it and push again. Release: follow docs/release.md (11 steps).
```

```bash
#!/usr/bin/env bash
# scripts/check.sh - the single command for "is this change ready". CI runs the same script.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v ruff >/dev/null   || { echo "check.sh: ruff is not installed (see CONTRIBUTING.md)" >&2; exit 2; }
command -v pytest >/dev/null || { echo "check.sh: pytest is not installed (see CONTRIBUTING.md)" >&2; exit 2; }

ruff check .
pytest -q
python -m build --wheel --outdir dist/ >/dev/null
echo "check.sh: all steps passed"
```

```text
After (README)
  To check a change: scripts/check.sh. CI job "check" runs the same script.
```

Local runs and CI cannot drift because they share the script, a missing tool fails with a message that says what to install, and the README no longer holds a procedure.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Procedure in prose | A numbered list of commands in a README or wiki | Put the commands in a script; link to it |
| Two copies of the steps | CI file and local docs list different commands | One script, called from both |
| Machine-specific build | Absolute paths, unpinned tools, undeclared environment variables | Declare prerequisites and check them |
| Release ritual | A release document with many steps and manual approvals of each | One command with a dry run and explicit approvals |
| Hand-made bulk edit | The same change typed into many files | A script or codemod, reviewed |
| Orphan script | A script in a personal directory that the team depends on | Commit it and review it |

## Trade-offs and exceptions

- Not everything deserves a script. A step done once, or one that needs human judgment every time, stays manual; the source targets repetitive, error-prone and easy-to-forget work.
- Automation has a maintenance cost. Added judgment: a small script that fails loudly beats a framework nobody understands.
- Scripts that touch production, databases or shared infrastructure need approvals and dry runs; this skill never asks an agent to run them for real (rule 13).
- Plain text and open formats for scripts and configuration are preferred where practical (`pragmatic-programmer-reversible-choices`).
- Production-grade deployment safety (idempotent, resumable rollouts) is the territory of a Release It! plugin.

## Verification

- [ ] Each repeated step in the task is performed by a script or build target.
- [ ] Local runs and CI call the same entry point.
- [ ] The script checks its prerequisites and fails with a clear message.
- [ ] Scripts and configuration are versioned with the code.
- [ ] Destructive actions require an explicit flag or default to a dry run.

## Related

`/pragmatic-programmer:manual-step-hunt` to scan a repository; `pragmatic-programmer-automation-reviewer` to review a diff; `pragmatic-programmer-automation-scripter` to write the script; `pragmatic-programmer-feedback-loops` for check speed; `pragmatic-programmer-dry-knowledge` for duplicated process steps.

## Source

- `Automation Rules`
- `Manual Everything`
- `Tooling Rules`
- `Basic Tool Rules`: only the rules on source control, shell tools, editor capabilities and text-manipulation scripts.
- `DRY Rules`: only the rule to avoid duplicated process steps that can be automated.
