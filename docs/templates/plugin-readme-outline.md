# Plugin README outline

Section order is fixed; headings must contain the key word shown. Minimum 7,000 characters of real content.

1. `# <Book title>` plus one sentence, then a short badge-free summary of what is inside (counts come from the generated block).
2. `## Overview`: the book in your words (thesis, who it is for), what this toolkit adds, and when *not* to use it.
3. `## Installation`: `/plugin marketplace add <owner>/<repo>`, `/plugin install <slug>@guided-plugins`, local `--plugin-dir`, enabling the `inject_rules` option, uninstalling.
4. `## Components`: keep the generated block between `<!-- COMPONENTS:START -->` and `<!-- COMPONENTS:END -->`; add one paragraph on how the pieces fit (router -> reviewers -> implementers -> gate).
5. `## Usage walkthroughs`: at least five scenarios (for example: reviewing a PR, planning a risky change, learning mode, auditing a repo, fixing findings). Each: situation, exact commands, what you get.
6. `## How it maps to the book`: table of upstream section -> components. (Section names only; no book text.)
7. `## Works with other plugins`: 3-5 siblings, verdict and overlap from `docs/compatibility`, one recommended pairing, and what to avoid loading together.
8. `## Limitations`: rule-based guidance is not measured quality; context cost; where the book's advice is contested; what this plugin cannot detect.
9. `## Attribution and license`: MIT, built on `ciembor/agent-rules-books`, unofficial, links to `LICENSE` and `NOTICE.md`.
