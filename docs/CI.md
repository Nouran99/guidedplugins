# Reviews in CI, hooks and scripts

The book plugins review a diff when you ask. This page runs the same review **without you**: on every pull request, before a push, or from a
script, and turns the result into things tools understand: SARIF for GitHub code scanning, a pull request review with inline comments, a job summary,
and an exit code.

Everything here is optional, needs [Claude Code](https://code.claude.com) (`claude`) signed in or with `ANTHROPIC_API_KEY`, and **sends the diff to the
Anthropic API**. A review costs model usage. Measured: a single-book `/<book>:review` of one small file cost 0.17 to 0.31 dollars (mean 0.23, 25 runs of the eval suites); the combined `/guided:review` of two books on a small diff cost about 1.1 dollars (one run). Cost grows with the size of the diff and the number of books; a diff of several hundred lines or three or four books will cost more, and that is not measured here. `--max-budget-usd` is a ceiling (default 2 dollars for the runner, the Action and the hook); a review stopped by it counts as "could not run" (exit 2), so the money is spent and the hook lets the push through.
The reviewer gets the read tools (Read, Grep, Glob) and `git diff|log|show|status|blame|ls-files`. It has no edit or write tool, but those git commands are not a sandbox: a flag such as `--output=<file>` can still write a file in the checkout. Run it in a throwaway checkout (the Action does) and keep secrets out of that job.

## GitHub pull requests

Copy [examples/guided-review.yml](examples/guided-review.yml) to `.github/workflows/guided-review.yml` and add a repository secret `ANTHROPIC_API_KEY`.
On each push to a pull request the action:

1. installs Claude Code and the book plugins named in `.guided-plugins.json` (or in `books:`), plus `guided` when there are several;
2. reviews `origin/<base>...HEAD` and writes `report.json`, `report.sarif`, `summary.md`, `review.json` and `diff.patch`;
3. adds the summary to the job, uploads the SARIF to code scanning, and posts one pull request review with inline comments on the changed lines (a finding that an earlier run already posted is not posted again; "the same" means the same book, rule, path and text of the cited line, so a shifted line number or different wording does not matter, but a finding reported for different text or under a different rule name is new);
4. fails the job when a finding reaches `fail-on` (default `major`), or when the review could not run.

Pull requests from forks have no secrets, so the action prints a notice and passes. The action pins nothing: use a release tag or a commit SHA once
the repository publishes one.

## Before a push

```bash
cd ~/work/app
node /path/to/guidedplugins/scripts/install-git-hook.mjs          # ./.git/hooks/pre-push; --uninstall removes it
git push                                                          # reviews the commits being pushed, blocks on a blocker
GUIDED_SKIP=1 git push                                            # skip once
GUIDED_FAIL_ON=major git push                                     # stricter, once (blocker | major | minor | nit | never)
GUIDED_BUDGET=3 git push                                          # dollars per review (default 2)
```

The hook blocks only when a finding reaches `GUIDED_FAIL_ON` (default `blocker`; it does not read `failOn` from `.guided-plugins.json`, which is for CI). If `claude` is missing or the review cannot run, it says so and lets the
push through: a hook that fails closed on a network error teaches people to disable it.

## From a script

```bash
node /path/to/guidedplugins/scripts/guided-review-ci.mjs --base origin/main            # exit 0 pass, 1 findings at the gate, 2 could not run
node /path/to/guidedplugins/scripts/guided-review-ci.mjs --staged --fail-on never      # report on the staged changes, never fail
node /path/to/guidedplugins/scripts/guided-review-ci.mjs --books clean-code --dry      # show the command, run nothing
```

| Flag | Meaning |
| --- | --- |
| `--base REF` `--head REF` | Review `REF...HEAD` (default: the working tree against `HEAD`). `--staged` reviews the index. |
| `--books a,b` | Books to apply (default: `primary` and `secondary` of `.guided-plugins.json`). One book runs `/<book>:review`; several run `/guided:review`. |
| `--fail-on LEVEL` | `blocker`, `major`, `minor`, `nit` or `never` (default: `failOn` of the settings file, else `major`). |
| `--max-budget-usd N` | Spending ceiling for the review (default 2). |
| `--model M` | Model for the review (default: the Claude Code default). |
| `--plugin-dir DIR` | Load a plugin from a folder (development). |
| `--out DIR` | Where the results go (default `.guided-review/`). |

## The findings format

A review asked for JSON returns one object that matches [findings.schema.json](findings.schema.json): the books used, the scope, a list of findings
(`severity` blocker, major, minor or nit; `path`; `line`; `rule`; `why`; `fix`; `confidence`), notes where books disagree, and what was and was not
checked. `scripts/findings-convert.mjs` converts it:

```bash
node scripts/findings-convert.mjs report.json --to sarif --out guided.sarif
node scripts/findings-convert.mjs report.json --to markdown
node scripts/findings-convert.mjs report.json --to github-review --diff pr.diff --out review.json
node scripts/findings-convert.mjs claude-output.json --from-claude --to gate --fail-on major
```

Every book plugin's `review` workflow returns this format when its arguments contain `--json` (or the caller supplies the schema, as the runner
does), and `/guided:review` returns it for a combined review.

## What to expect

- A model reads the diff, so two runs on the same pull request can differ. The gate is a signal, not a proof; tune it with `failOn` and `strictness`.
- Findings on lines outside the diff go into the review body, because GitHub only accepts inline comments on changed lines.
- Prompt injection: the reviewed code is data. The skills tell the model to ignore instructions inside it, and the reviewer has no edit or write tool, but treat a
  review of untrusted code (a fork) like any model output.
- `scripts/selftest-ci.mjs` tests all of this with stand-ins for `claude` and `gh` (no network, no model). It is not a substitute for one real run on your repository.

## Other agents

The runner starts `claude -p` and reads its `structured_output`. A different agent can feed the same pipeline: run your agent's review of the diff, make it produce a report in the
[findings format](findings.schema.json) (the book skills' `--json` mode describes it), save it as `report.json`, then use `scripts/findings-convert.mjs` for SARIF, the pull
request review and the gate, and `scripts/github-post-review.mjs` to post. Nothing else in the plumbing is specific to Claude Code.

