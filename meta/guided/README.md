# guided: the companion of the book plugins

Fourteen plugins in this marketplace turn classic software-engineering books into skills, subagents and modes. This one makes them usable together.
It has no book content of its own: it helps you pick books, remembers your choices per project, reviews with several books at once, and runs
reviews automatically.

| Command | What it does |
| --- | --- |
| `/guided:start` | Orientation: which books are installed, the first command to run in each, and what to set up next. |
| `/guided:which-book` | Looks at your repository (or the task you describe) and recommends one primary and up to two secondary books that do not clash, with the install commands. |
| `/guided:config` | Writes `.guided-plugins.json`: primary and secondary books, strictness, ignored paths, report size, the CI failure level. Every book plugin reads it. |
| `/guided:review` | One review of a diff across the books you chose: each book's lead routes, specialists review in parallel, duplicates merge, and where a secondary book contradicts the primary one it is reported as a disagreement, not a finding. `--json` returns the findings format for tools. |
| `/guided:conflicts` | How two books relate (the verdict from the compatibility guide) and who wins. |
| `/guided:ci-setup` | Writes a GitHub workflow that reviews every pull request (findings as one review with inline comments, SARIF for code scanning, a failing check) and explains the pre-push hook. |

## Install

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install guided-everyday-code@guided-plugins     # a preset: the books and this plugin together
```

Presets (`guided-everyday-code`, `guided-legacy-rescue`, `guided-backend-service`, `guided-domain-model`, `guided-system-design`) are listed in the
repository README. To install by hand: `/plugin install guided@guided-plugins` plus the books you want.

## Cost and limits

- `/guided:review` starts one lead and up to three reviewers per book (at most ten reviewers): it costs several single-book reviews. Use `/<book>:review` when one book is enough.
- The combined review needs the book plugins' subagents. A book that is not installed is skipped and listed under "Not checked".
- It is a model reading code. The merge, the disagreement test and the settings are instructions it follows, not guarantees; the CI runner applies the ignore list, strictness and report size again in code.
- Nothing here edits your files. `/guided:config` writes `.guided-plugins.json`, and `/guided:ci-setup` writes one workflow file, each after you agree.

MIT licensed. Unofficial: not affiliated with or endorsed by the authors or publishers of the books. See the repository NOTICE.
