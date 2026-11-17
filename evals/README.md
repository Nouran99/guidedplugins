# Eval suites

One suite per plugin, in `evals/<slug>/`. They answer one question with numbers: **does installing the plugin make an agent's review better than
the same agent without it, and does it stay quiet on code that is fine?** They run with `claude plugin eval` (Claude Code 2.1.269 or later),
which runs each case in a throwaway workspace, once with the plugin and once without, and scores both with the same graders.

The suites live outside `plugins/` on purpose: nothing here ships to people who install a plugin.

```bash
node scripts/validate-evals.mjs                 # structure only; no model calls
node scripts/run-evals.mjs clean-code           # runs the suite; spends model usage (about $2 for one plugin at one run per case)
node scripts/run-evals.mjs all --max-cost-usd 5 --runs 1   # the cap applies to each pass of each plugin, not to the whole run
node scripts/summarize-evals.mjs                # rewrites docs/EVALS.md from evals/summary/*.json
```

## What a suite contains

Three or more **detect** cases and at least one **control** case.

```text
evals/<slug>/<case>/
  case.yaml        schema_version "1.1", name, description, tags: [detect] | [control], execution (turns, timeout, read-only tools), context.scaffold_script
  scaffold.sh      writes the fixture (a few small files) into the empty workspace; no network
  prompt.md        "Review <path> before I merge it. ... Do not edit any file."
  graders/*.md     one grader per planted violation (type: llm), plus optional regex graders
```

- **detect**: a fixture of one to seven small files (typically 100 to 300 lines in total; the validator caps each file at 160 lines) with five to seven violations planted from *different rule clusters of the book*, each a thing the
  book's rules say to flag. One `llm` grader per violation (weight 1, or 2 for the one the book is most about) states what a review must say to
  pass. The score is therefore the share of the planted violations the review found. One obvious defect is not enough: a capable model finds it
  with or without the plugin (the first pilot case did exactly that, delta 0), so plant the things a generalist review skips because it ranks
  correctness first: hidden side effects, mixed levels of abstraction, vendor types in business code, missing seams, unstable dependencies.
- **control**: code that follows the book, usually larger than a detect fixture because it carries the tests and constants the book wants to see. The graders fail a review that invents a design or style problem, asks for a rewrite, or flags
  something the book permits. Include whatever the book wants to see (tests, named constants, a documented limit) so the control is clean by the
  plugin's own rules, and word the prompt so that "nothing needs to change" is an acceptable answer.

The natural prompt never names the plugin or its skills. That is the fair baseline: what a user types without the plugin.

## What the runner adds

For every detect and control case the runner generates a **slash variant** inside its temporary copy (`<case>--slash`): the same fixture and
the same graders, but the prompt is the plugin's own workflow (`/<slug>:review <path>`), plus checks that the report has the plugin's header and
`Why:` and `Fix:` lines. The slash variants run plugin-only, because the baseline arm cannot run a slash command. Per fixture you therefore get
three numbers: **baseline** (natural prompt, no plugin), **natural with the plugin** (do the auto skills fire on their own?) and **slash** (the
plugin's workflow).

## Writing a good case

1. Read the plugin (`plugins/<slug>/README.md`, the hub `skills/principles/SKILL.md`, `skills/review/SKILL.md` and the specialist skills) and
   pick violations that the plugin's own rules name. Do not plant something the plugin does not flag.
2. Vary the languages across the cases of a suite (TypeScript, Python, Java, Go, C#, Kotlin, Ruby, Rust) and keep the fixtures realistic: a
   service, a repository, a handler, a test file, not a toy that announces its flaws.
3. Never mark the flaws in the code (no `// BAD:` comments, no names like `badFunction`).
4. Write every `llm` grader as `PASS if ... FAIL if ...`, one violation each, short. Accept any reasonable wording of the fix.
5. Run `node scripts/validate-evals.mjs <slug>`. Run the suite only when you want numbers; each case costs model usage.

## Reading the results

`evals/results/` (git-ignored) has the full run: prompts, grader verdicts, judge votes and costs. `evals/summary/<slug>.json` (committed) keeps the
scores. [docs/EVALS.md](../docs/EVALS.md) is generated from the summaries and says which model, Claude Code version, runs per case and date they
come from. One run per case is a smoke test with noise; three or more per case before you rely on a difference.
