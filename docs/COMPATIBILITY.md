# Plugin compatibility

Which of the 14 plugins to install together, which to treat as alternatives, and which pairs need an explicit arbiter. It is written for someone choosing a set of plugins to install, not for someone building one.

The ratings come from the pairwise compatibility notes in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books), at upstream commit `893a88a6fce3a80c565bf39ac65021b43a8b2990`, the commit every plugin here was built from. This project is unofficial and is not affiliated with or endorsed by the books' authors or publishers; see [NOTICE.md](../NOTICE.md).

**In short**

- Choose at most one primary rule set and turn that plugin's `inject_rules` option on. Bring every other plugin in per task, through its commands, agents or output styles.
- Of the 91 pairs, 78 are rated complementary, 11 overlap and 2 conflicting.
- `data-intensive-apps`, `release-it`, and `legacy-code` have no overlap or conflicting pair with any other plugin: all 13 pairs of each are complementary.
- The other 11 plugins fall into three groups whose members compete for the same decisions. Choose one primary per group; see [section 4](#4-finding-a-pair).
- The ratings say whether two rule sets are likely to give an agent competing instructions. They do not measure whether any combination improves code quality, and upstream says so itself.

Contents: [1 How to read it](#1-how-to-read-this-document) · [2 The loading rule](#2-the-loading-rule) · [3 All 91 pairs](#3-all-91-pairs) · [4 Finding a pair](#4-finding-a-pair) · [5 Pairs to be careful with](#5-pairs-to-be-careful-with) · [6 Recommended bundles](#6-recommended-bundles) · [7 What the plugin READMEs say](#7-what-the-plugin-readmes-say-about-pairings) · [Updating this document](#updating-this-document)

## 1. How to read this document

### Verdicts

Each pair of books has one verdict. The meanings are upstream's; the last column is this project's reading of them.

| Verdict | Upstream meaning | What it means for your setup |
| --- | --- | --- |
| Complementary | Can be combined as equal active guidance without one book arbitrating the other. | Both can be installed. Use the second one when its trigger is present in the task. |
| Overlap | Choose one: the books apply similar pressure, compete for the same decision layer, or one is a narrower substitute for the other. | Make one primary. Use the other only for a narrow, named sub-decision, or not at all. |
| Conflicting | Do not load together as equal active rule sets. | Same as overlap, with more care: the two can push opposite decisions on the same code. |

Every overlap and conflicting pair document also has a "Use Together When" section naming a narrow case where the two may still be used together, usually with one book primary and the other limited to a specific sub-decision. A non-complementary verdict therefore means "do not make both primary", not "never install both".

### The three percentages

- **Conflict**: how much the active guidance can push opposite decisions.
- **Overlap**: how much the guidance pushes the same decisions or covers the same failure modes.
- **Complementarity**: how much the guidance works at different levels and strengthens the pair.

The three are separate estimates, not shares of a whole, and they do not add up to 100. Across the 91 pairs, conflict runs from 8% to 66%, overlap from 34% to 90%, and complementarity from 30% to 80%.

The verdict is not a function of one number. Two examples from the data:

- `refactoring` and `refactoring-guru` have almost no conflict and the highest overlap in the set (conflict 8%, overlap 90%, complementarity 30%). They give the same advice, so loading both costs context and adds no new instruction.
- `clean-architecture` and `ddd` have high overlap and the highest conflict of any complementary pair (conflict 36%, overlap 62%, complementarity 70%), yet they are rated complementary because they work at different levels: dependency direction on one side, model language and boundaries on the other.

A workable reading order is the verdict first, then conflict for the risk of opposite instructions, then overlap for the amount of repeated context.

### What the data can and cannot tell you

1. **The scores are qualitative.** They are estimates grounded in cited lines of each book's compact `mini` rule file. For pairs it considered high-risk, upstream also required outside sources. 16 of the 91 pair documents used outside sources: all 13 non-complementary pairs and three complementary pairs (`philosophy-of-design` + `refactoring`, `clean-architecture` + `ddd`, and `data-intensive-apps` + `release-it`). The other 75 rest on the `mini` files alone, and many of them share one loading decision across a family of pairs (for example, 32 pairs score exactly 12% / 38% / 78%).
2. **Nothing was measured on real tasks.** Upstream's criticism notes call its compatibility calls qualitative and source-based, and not validated by task runs. They also list the lack of any measurement of improvement as the strongest open criticism of the whole project. This document therefore never says that a combination improves code quality, only that two rule sets are or are not likely to compete.
3. **Only pairs are rated.** There is no upstream rating for three or more rule sets loaded together. The bundles in [section 6](#6-recommended-bundles) are inferred from pair ratings: every pair inside a bundle is complementary.
4. **The ratings cover rule sets, not plugins.** Each plugin adds skills, subagents and output styles on top of its rule set. Those additions were not rated.
5. **A verdict is not a quality judgment.** Upstream describes the `ddd` and `ddd-distilled` overlap as a substitute decision, not a statement that one book is better.

### Names

Plugin slugs are used throughout. The upstream matrix uses short names and the upstream folder names, so this table maps them.

| Plugin | Book | Upstream folder | Short name in the upstream matrix |
| --- | --- | --- | --- |
| `clean-code` | Clean Code (Robert C. Martin) | `clean-code` | CleanC |
| `philosophy-of-design` | A Philosophy of Software Design (John Ousterhout) | `a-philosophy-of-software-design` | APoSD |
| `clean-architecture` | Clean Architecture (Robert C. Martin) | `clean-architecture` | CleanA |
| `code-complete` | Code Complete (Steve McConnell) | `code-complete` | CodeC |
| `data-intensive-apps` | Designing Data-Intensive Applications (Martin Kleppmann) | `designing-data-intensive-applications` | DDIA |
| `ddd` | Domain-Driven Design (Eric Evans) | `domain-driven-design` | DDD |
| `ddd-distilled` | Domain-Driven Design Distilled (Vaughn Vernon) | `domain-driven-design-distilled` | DDD Distilled |
| `ddd-implementing` | Implementing Domain-Driven Design (Vaughn Vernon) | `implementing-domain-driven-design` | IDDD |
| `enterprise-patterns` | Patterns of Enterprise Application Architecture (Martin Fowler) | `patterns-of-enterprise-application-architecture` | PoEAA |
| `refactoring` | Refactoring (Martin Fowler) | `refactoring` | Refactoring |
| `refactoring-guru` | Refactoring.Guru (website) | `refactoring-guru` | Ref Guru |
| `release-it` | Release It! (Michael T. Nygard) | `release-it` | Release It |
| `pragmatic-programmer` | The Pragmatic Programmer (Andrew Hunt, David Thomas) | `the-pragmatic-programmer` | PragProg |
| `legacy-code` | Working Effectively with Legacy Code (Michael Feathers) | `working-effectively-with-legacy-code` | WELC |

Each pair is stored once upstream, as `docs/compatibility/<earlier folder>/<later folder>.md`, where "earlier" is alphabetical order of the upstream folder names. For example, `ddd` and `enterprise-patterns` is `docs/compatibility/domain-driven-design/patterns-of-enterprise-application-architecture.md`.

## 2. The loading rule

### What upstream says

Upstream's usage guide gives one rule for combining books: use the smallest mechanism that still changes the agent's decisions, start with one primary rule set, prefer skills for book-specific guidance, and prefer scoped or on-demand loading over global loading. When a task needs more than one book, keep one primary always-on rule set and move the rest to on-demand mechanisms. Its guidance for Claude Code also warns against mixing many conflicting imports, and its criticism notes list context bloat as a real risk of loading many rule sets at once. The pair documents apply the same rule pair by pair.

### What it means for these plugins

| Mechanism | What it does | How to use it |
| --- | --- | --- |
| [`inject_rules`](USAGE.md#2-turn-on-the-always-on-rules-inject_rules) plugin option | Off by default. When on, a session-start hook adds the plugin's compact rule file (`nano.md`) to every new, cleared or compacted session. | Turn it on for **at most one** plugin: the primary. In a session: `/plugin configure <plugin>@guided-plugins`. |
| Skills Claude loads on its own | Rule clusters with a trigger description. Claude picks them up when the task matches. Their descriptions sit in context on every turn: 18 to 20 per installed plugin. | Not a mechanism for secondary books. It is the reason to install few plugins. |
| Skills you run by name | Workflows such as `review`, `plan`, `audit`, `explain-rule`, `checklist` and `fix`, plus book-specific ones. Run as `/<plugin>:<name>`. | The main way to bring a second book into one task. |
| Subagents | A `lead` router, read-only specialist reviewers, implementers and a `final-gate`. Claude delegates, or you ask for `@agent-<plugin>:<name>`. | A second opinion from another book on one diff, for example its `final-gate`. Run one `lead` at a time when you plan by hand; `/guided:review` is the exception. |
| Output styles | `/output-style <plugin>:<mode>` changes how the whole session behaves (`mentor`, `strict-reviewer`, `pair`, `terse` and one book-specific mode). | Switching the working mode for a session. |

Upstream recommends the `mini` rule files as the working layer, and for an always-on rule it suggests one carefully chosen `mini`, with `nano` if `mini` is too large for the tool or project. These plugins make a different choice for the hook: it injects `nano` (1.2 to 2.8 KB) rather than `mini` (3.8 to 8.1 KB) to keep the always-on cost small. Each plugin's `principles` skill then reads `mini` on demand for design decisions and `full` only when `mini` does not settle a trade-off.

In practice:

1. Choose as primary the plugin whose risk shows up in most of your tasks. The starting points in the [README](../README.md#choosing-plugins) help.
2. Turn `inject_rules` on for that plugin only.
3. Bring a second book in for one task by running one of its commands, for example `/refactoring:review` on the working diff, or by asking for `@agent-release-it:final-gate` before you merge.
4. Do not run the `lead` agents of several books at once to plan one task by hand; pick one as the router. The exception is `/guided:review` (the `guided` plugin), which asks each book's lead only to choose that book's reviewers and merges the findings itself.
5. For complementary pairs, load the second book only when its trigger is present. Most of the upstream pair documents say the same: load only the rule set whose trigger is actually present.
6. For a pair that is not complementary, say who arbitrates. A prompt such as this one is enough:

```text
Use ddd as the primary rule set for this change. Use enterprise-patterns only to choose the persistence
pattern for the order repository, and do not add or remove domain-model structure because of it.
```

Installed plugins keep their self-loading skills active, so a second plugin that is installed can still be pulled in by Claude whenever its descriptions match. For complementary pairs that is the intent. For overlap and conflicting pairs, the safer setup is to install only the primary, or to try the other plugin for one session with `claude --plugin-dir ./plugins/<slug>` from a checkout of this repository. That advice is this project's judgment about how Claude Code activates skills, not part of any upstream rating.

Example setup for a developer who works mostly on everyday application code and sometimes touches untested code:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install clean-code@guided-plugins
/plugin install refactoring@guided-plugins
/plugin install legacy-code@guided-plugins
```

Then enable `inject_rules` for `clean-code` only, with `/plugin configure clean-code@guided-plugins` (the other ways are in [USAGE.md](USAGE.md#2-turn-on-the-always-on-rules-inject_rules)), and bring the other two in per task:

```text
/legacy-code:characterize apply_discounts
/refactoring:plan "split apply_discounts into pricing and persistence"
```

## 3. All 91 pairs

Pairs are listed in the order of the catalog in the [README](../README.md#the-plugins): by the first plugin's position, then by the second plugin's position. Each pair appears once. Verdicts other than complementary are in bold. The 13 bold rows are discussed in [section 5](#5-pairs-to-be-careful-with).

| Plugin A | Plugin B | Verdict | Conflict | Overlap | Complementarity |
| --- | --- | --- | ---: | ---: | ---: |
| `clean-code` | `philosophy-of-design` | **Overlap** | 55% | 72% | 42% |
| `clean-code` | `clean-architecture` | Complementary | 16% | 35% | 76% |
| `clean-code` | `code-complete` | **Overlap** | 30% | 78% | 45% |
| `clean-code` | `data-intensive-apps` | Complementary | 10% | 35% | 80% |
| `clean-code` | `ddd` | Complementary | 14% | 38% | 74% |
| `clean-code` | `ddd-distilled` | Complementary | 14% | 38% | 74% |
| `clean-code` | `ddd-implementing` | Complementary | 14% | 38% | 74% |
| `clean-code` | `enterprise-patterns` | Complementary | 16% | 38% | 72% |
| `clean-code` | `refactoring` | Complementary | 12% | 38% | 78% |
| `clean-code` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `clean-code` | `release-it` | Complementary | 12% | 34% | 78% |
| `clean-code` | `pragmatic-programmer` | **Overlap** | 24% | 68% | 54% |
| `clean-code` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `philosophy-of-design` | `clean-architecture` | Complementary | 28% | 44% | 68% |
| `philosophy-of-design` | `code-complete` | Complementary | 20% | 50% | 62% |
| `philosophy-of-design` | `data-intensive-apps` | Complementary | 10% | 35% | 80% |
| `philosophy-of-design` | `ddd` | Complementary | 14% | 38% | 74% |
| `philosophy-of-design` | `ddd-distilled` | Complementary | 14% | 38% | 74% |
| `philosophy-of-design` | `ddd-implementing` | Complementary | 14% | 38% | 74% |
| `philosophy-of-design` | `enterprise-patterns` | Complementary | 16% | 38% | 72% |
| `philosophy-of-design` | `refactoring` | Complementary | 28% | 46% | 74% |
| `philosophy-of-design` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `philosophy-of-design` | `release-it` | Complementary | 12% | 34% | 78% |
| `philosophy-of-design` | `pragmatic-programmer` | Complementary | 20% | 50% | 62% |
| `philosophy-of-design` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `clean-architecture` | `code-complete` | Complementary | 16% | 35% | 76% |
| `clean-architecture` | `data-intensive-apps` | Complementary | 10% | 35% | 80% |
| `clean-architecture` | `ddd` | Complementary | 36% | 62% | 70% |
| `clean-architecture` | `ddd-distilled` | Complementary | 22% | 55% | 68% |
| `clean-architecture` | `ddd-implementing` | **Overlap** | 46% | 66% | 58% |
| `clean-architecture` | `enterprise-patterns` | **Overlap** | 44% | 64% | 52% |
| `clean-architecture` | `refactoring` | Complementary | 12% | 38% | 78% |
| `clean-architecture` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `clean-architecture` | `release-it` | Complementary | 12% | 34% | 78% |
| `clean-architecture` | `pragmatic-programmer` | Complementary | 16% | 35% | 76% |
| `clean-architecture` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `code-complete` | `data-intensive-apps` | Complementary | 10% | 35% | 80% |
| `code-complete` | `ddd` | Complementary | 14% | 38% | 74% |
| `code-complete` | `ddd-distilled` | Complementary | 14% | 38% | 74% |
| `code-complete` | `ddd-implementing` | Complementary | 14% | 38% | 74% |
| `code-complete` | `enterprise-patterns` | Complementary | 16% | 38% | 72% |
| `code-complete` | `refactoring` | Complementary | 12% | 38% | 78% |
| `code-complete` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `code-complete` | `release-it` | Complementary | 12% | 34% | 78% |
| `code-complete` | `pragmatic-programmer` | **Overlap** | 18% | 64% | 58% |
| `code-complete` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `data-intensive-apps` | `ddd` | Complementary | 10% | 35% | 80% |
| `data-intensive-apps` | `ddd-distilled` | Complementary | 10% | 35% | 80% |
| `data-intensive-apps` | `ddd-implementing` | Complementary | 10% | 35% | 80% |
| `data-intensive-apps` | `enterprise-patterns` | Complementary | 10% | 35% | 80% |
| `data-intensive-apps` | `refactoring` | Complementary | 12% | 38% | 78% |
| `data-intensive-apps` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `data-intensive-apps` | `release-it` | Complementary | 28% | 46% | 80% |
| `data-intensive-apps` | `pragmatic-programmer` | Complementary | 10% | 35% | 80% |
| `data-intensive-apps` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `ddd` | `ddd-distilled` | **Overlap** | 15% | 88% | 34% |
| `ddd` | `ddd-implementing` | **Overlap** | 22% | 80% | 48% |
| `ddd` | `enterprise-patterns` | **Conflicting** | 62% | 68% | 44% |
| `ddd` | `refactoring` | Complementary | 12% | 38% | 78% |
| `ddd` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `ddd` | `release-it` | Complementary | 12% | 34% | 78% |
| `ddd` | `pragmatic-programmer` | Complementary | 14% | 38% | 74% |
| `ddd` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `ddd-distilled` | `ddd-implementing` | **Overlap** | 20% | 78% | 52% |
| `ddd-distilled` | `enterprise-patterns` | **Overlap** | 50% | 66% | 48% |
| `ddd-distilled` | `refactoring` | Complementary | 12% | 38% | 78% |
| `ddd-distilled` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `ddd-distilled` | `release-it` | Complementary | 12% | 34% | 78% |
| `ddd-distilled` | `pragmatic-programmer` | Complementary | 14% | 38% | 74% |
| `ddd-distilled` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `ddd-implementing` | `enterprise-patterns` | **Conflicting** | 66% | 72% | 40% |
| `ddd-implementing` | `refactoring` | Complementary | 12% | 38% | 78% |
| `ddd-implementing` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `ddd-implementing` | `release-it` | Complementary | 12% | 34% | 78% |
| `ddd-implementing` | `pragmatic-programmer` | Complementary | 14% | 38% | 74% |
| `ddd-implementing` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `enterprise-patterns` | `refactoring` | Complementary | 12% | 38% | 78% |
| `enterprise-patterns` | `refactoring-guru` | Complementary | 12% | 38% | 78% |
| `enterprise-patterns` | `release-it` | Complementary | 12% | 34% | 78% |
| `enterprise-patterns` | `pragmatic-programmer` | Complementary | 16% | 38% | 72% |
| `enterprise-patterns` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `refactoring` | `refactoring-guru` | **Overlap** | 8% | 90% | 30% |
| `refactoring` | `release-it` | Complementary | 12% | 38% | 78% |
| `refactoring` | `pragmatic-programmer` | Complementary | 12% | 38% | 78% |
| `refactoring` | `legacy-code` | Complementary | 10% | 58% | 76% |
| `refactoring-guru` | `release-it` | Complementary | 12% | 38% | 78% |
| `refactoring-guru` | `pragmatic-programmer` | Complementary | 12% | 38% | 78% |
| `refactoring-guru` | `legacy-code` | Complementary | 10% | 58% | 76% |
| `release-it` | `pragmatic-programmer` | Complementary | 12% | 34% | 78% |
| `release-it` | `legacy-code` | Complementary | 12% | 38% | 78% |
| `pragmatic-programmer` | `legacy-code` | Complementary | 12% | 38% | 78% |

## 4. Finding a pair

### Matrix

The matrix repeats the verdict of every pair in a grid, so a pair can be found from either plugin. `C` is complementary, `O` is overlap, `X` is conflicting, and `-` is the plugin against itself.

Column numbers: 1 `clean-code`; 2 `philosophy-of-design`; 3 `clean-architecture`; 4 `code-complete`; 5 `data-intensive-apps`; 6 `ddd`; 7 `ddd-distilled`; 8 `ddd-implementing`; 9 `enterprise-patterns`; 10 `refactoring`; 11 `refactoring-guru`; 12 `release-it`; 13 `pragmatic-programmer`; 14 `legacy-code`.

| Plugin | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 `clean-code` | - | O | C | O | C | C | C | C | C | C | C | C | O | C |
| 2 `philosophy-of-design` | O | - | C | C | C | C | C | C | C | C | C | C | C | C |
| 3 `clean-architecture` | C | C | - | C | C | C | C | O | O | C | C | C | C | C |
| 4 `code-complete` | O | C | C | - | C | C | C | C | C | C | C | C | O | C |
| 5 `data-intensive-apps` | C | C | C | C | - | C | C | C | C | C | C | C | C | C |
| 6 `ddd` | C | C | C | C | C | - | O | O | X | C | C | C | C | C |
| 7 `ddd-distilled` | C | C | C | C | C | O | - | O | O | C | C | C | C | C |
| 8 `ddd-implementing` | C | C | O | C | C | O | O | - | X | C | C | C | C | C |
| 9 `enterprise-patterns` | C | C | O | C | C | X | O | X | - | C | C | C | C | C |
| 10 `refactoring` | C | C | C | C | C | C | C | C | C | - | O | C | C | C |
| 11 `refactoring-guru` | C | C | C | C | C | C | C | C | C | O | - | C | C | C |
| 12 `release-it` | C | C | C | C | C | C | C | C | C | C | C | - | C | C |
| 13 `pragmatic-programmer` | O | C | C | O | C | C | C | C | C | C | C | C | - | C |
| 14 `legacy-code` | C | C | C | C | C | C | C | C | C | C | C | C | C | - |

### Per plugin

| Plugin | Complementary with | Overlap with | Conflicting with |
| --- | --- | --- | --- |
| `clean-code` | 10 of 13 | `philosophy-of-design`, `code-complete`, `pragmatic-programmer` | none |
| `philosophy-of-design` | 12 of 13 | `clean-code` | none |
| `clean-architecture` | 11 of 13 | `ddd-implementing`, `enterprise-patterns` | none |
| `code-complete` | 11 of 13 | `clean-code`, `pragmatic-programmer` | none |
| `data-intensive-apps` | 13 of 13 | none | none |
| `ddd` | 10 of 13 | `ddd-distilled`, `ddd-implementing` | `enterprise-patterns` |
| `ddd-distilled` | 10 of 13 | `ddd`, `ddd-implementing`, `enterprise-patterns` | none |
| `ddd-implementing` | 9 of 13 | `clean-architecture`, `ddd`, `ddd-distilled` | `enterprise-patterns` |
| `enterprise-patterns` | 9 of 13 | `clean-architecture`, `ddd-distilled` | `ddd`, `ddd-implementing` |
| `refactoring` | 12 of 13 | `refactoring-guru` | none |
| `refactoring-guru` | 12 of 13 | `refactoring` | none |
| `release-it` | 13 of 13 | none | none |
| `pragmatic-programmer` | 11 of 13 | `clean-code`, `code-complete` | none |
| `legacy-code` | 13 of 13 | none | none |

### Groups that compete for the same decisions

The overlap and conflicting pairs are not scattered. They form three clusters, and three plugins sit outside all of them.

| Group | Plugins | Non-complementary pairs inside | Question that picks the primary |
| --- | --- | --- | --- |
| Everyday coding guides | `clean-code`, `philosophy-of-design`, `code-complete`, `pragmatic-programmer` | 4 of 6 | Is the main risk local readability (`clean-code`), module and API shape (`philosophy-of-design`), construction defects (`code-complete`) or process and feedback (`pragmatic-programmer`)? |
| Architecture, domain model and patterns | `clean-architecture`, `ddd`, `ddd-distilled`, `ddd-implementing`, `enterprise-patterns` | 8 of 10 | Is the main force dependency direction (`clean-architecture`), a domain model (`ddd-distilled` for the least ceremony, `ddd` for strategy, `ddd-implementing` for implementation), or the choice among enterprise patterns (`enterprise-patterns`)? |
| Refactoring | `refactoring`, `refactoring-guru` | 1 of 1 | Do you need a change process (`refactoring`) or a smell-to-treatment catalog (`refactoring-guru`)? |

Within a group, pick one primary. Not every pair inside a group is rated non-complementary (the table shows how many are), so a group is a place to slow down, not a list of plugins that can never be installed together.

`data-intensive-apps`, `release-it`, and `legacy-code` sit outside all three groups. Each is rated complementary with every one of the other 13 plugins, so they are the least risky additions to any setup. Complementary does not mean free: upstream still names a tension for these pairs, listed in [5.6](#56-complementary-pairs-the-upstream-notes-still-qualify) and [5.7](#57-the-tension-named-for-every-other-complementary-pair).

## 5. Pairs to be careful with

This section covers all 13 pairs whose verdict is not complementary, then nine complementary pairs that the upstream notes still qualify, then the tension that upstream names for the remaining complementary pairs. Reasons are paraphrased from the pair documents; recommendations are this project's reading of them.

### 5.1 Domain-model plugins against `enterprise-patterns`

Both conflicting pairs in the set have `enterprise-patterns` on one side, against `ddd` and `ddd-implementing`. The cause is the same in each case. The pattern book treats a simple design (transaction script, table module, active record) as a correct answer whenever the forces are simple. The DDD books push toward a richer domain model once language, invariants and lifecycle matter. An agent holding both has no rule for deciding which answer is right, and it can add domain-model structure in one step and defend the simple structure in the next.

#### `ddd` + `enterprise-patterns`

**Conflicting.** Conflict 62%, overlap 68%, complementarity 44%.

**Why.** Both decide where business logic lives, what the service layer does, how repositories, transactions and persistence mapping work, and how tests are written. They disagree on the default: `ddd` leans toward a rich model whenever the business language and invariants warrant it, while `enterprise-patterns` accepts a simpler design for simple domains and says to revisit the domain model only when duplication, lifecycle or invariant complexity grows. Upstream notes that the pattern book is useful after a rich model has already been justified, for concrete persistence, transaction, service layer, DTO and remoting decisions.

**Do.**

- Make `ddd` primary and use `enterprise-patterns` for one infrastructure decision at a time, for example `/enterprise-patterns:choose-pattern` on a single persistence or transaction question.
- If the domain has no strong model pressure, reverse the roles: `enterprise-patterns` primary, and do not install `ddd`.
- Never turn `inject_rules` on in both.

#### `ddd-implementing` + `enterprise-patterns`

**Conflicting.** Conflict 66%, overlap 72%, complementarity 40%. This is the highest conflict in the set, and upstream calls it the strongest implementation conflict.

**Why.** `ddd-implementing` commits the agent to a DDD implementation stack: small aggregates driven by invariants, repositories for aggregate roots, meaningful domain events, and one aggregate per transaction by default. `enterprise-patterns` may deliberately choose transaction script, table module, active record or a gateway instead. Loaded as equals, they produce generic repositories, active records and service layers fighting aggregate-root repositories and domain events. Upstream stresses that the DDD book is more than the pattern book with DDD names: it commits the agent to a model that the pattern book may deliberately avoid.

**Do.**

- For committed DDD work, `ddd-implementing` is primary. Bring `enterprise-patterns` in for one infrastructure decision whose force fits your aggregate boundaries. Upstream names a unit of work, an identity map, a data mapper, DTOs, a remote facade, locks and session state as the useful ones.
- For a system with enterprise-pattern forces but no committed DDD model, use `enterprise-patterns` and leave `ddd-implementing` out.

#### `ddd-distilled` + `enterprise-patterns`

**Overlap, with tension.** Conflict 50%, overlap 66%, complementarity 48%. Upstream rated it overlap rather than conflicting because the anti-ceremony gate in `ddd-distilled` makes the two easier to sequence.

**Why.** `ddd-distilled` decides whether DDD is justified at all and how little ceremony to use. `enterprise-patterns` chooses among enterprise patterns. Side by side they compete over whether to build a DDD tactical model or keep a simpler enterprise pattern, although the conflict is milder than in the two pairs above.

**Do.** Run them in sequence, not side by side: let `ddd-distilled` decide first (`/ddd-distilled:classify-subdomains` classifies where modeling effort is justified), then use `enterprise-patterns` for a specific pattern sub-decision. Outside clear DDD pressure, prefer `enterprise-patterns` alone.

### 5.2 Architecture guides against the DDD implementation and pattern books

#### `clean-architecture` + `ddd-implementing`

**Overlap.** Conflict 46%, overlap 66%, complementarity 58%. Upstream changed this pair from complementary to overlap during review.

**Why.** Both govern the same implementation layer: application services or use cases, repositories, DTOs, adapters and the tests around them. Together they stack ceremony: ports, use cases, adapters, repositories, events, DTOs, projections and application services can all appear even when one boundary style would be enough.

**Do.**

- Choose a primary. `clean-architecture` when dependency direction, framework leakage and replaceable details are the risk; `ddd-implementing` when the system is deliberately DDD and contexts, aggregates and events dominate.
- Use both only if the project is intentionally DDD and also has a concrete need to swap infrastructure. Otherwise leave one out.
- `clean-architecture` with `ddd` or `ddd-distilled` is rated complementary; see [5.6](#56-complementary-pairs-the-upstream-notes-still-qualify).

#### `clean-architecture` + `enterprise-patterns`

**Overlap.** Conflict 44%, overlap 64%, complementarity 52%.

**Why.** Both are enterprise architecture guides that cover layering, business logic placement, the service layer and persistence isolation. Their defaults differ for simple flows: the pattern book accepts transaction script, table module and active record when the forces fit, while the architecture book pushes policy independence and inward dependencies. Loaded equally they invite too many layers, with contradictory defaults.

**Do.** Keep `clean-architecture` primary when policy independence is the risk and use `enterprise-patterns` narrowly for a concrete persistence, transaction, remoting or session-state decision. When the task is choosing a pattern family and policy independence is not at stake, use `enterprise-patterns` alone.

### 5.3 The three DDD plugins are substitutes, not a stack

`ddd`, `ddd-distilled` and `ddd-implementing` cover the same ground at different depths, so every pair among them is rated overlap. The risk is not contradiction; it is duplicate context and, in the case of the implementation book, extra pressure to add tactical mechanisms.

| Situation | Primary |
| --- | --- |
| You are unsure whether DDD is justified, or want the least ceremony that works | `ddd-distilled` |
| The work is model discovery, ubiquitous language, context maps, core domain distillation or deeper model refactoring | `ddd` |
| The design is already DDD and the work is aggregates, repositories, events, application services, projections or context translation | `ddd-implementing` |

#### `ddd` + `ddd-distilled`

**Overlap.** Conflict 15%, overlap 88%, complementarity 34%. This is the second-highest overlap in the set.

**Why.** Both steer the same decisions about bounded contexts, ubiquitous language, aggregates, infrastructure isolation and the core domain. `ddd-distilled` adds a gate that rejects full tactical DDD for simple CRUD and generic subsystems; with `ddd` loaded as an equal, the agent may over-apply the fuller set.

**Do.** Choose one. `ddd-distilled` is the better default for most practical work. Use both only when a person explicitly wants Evans' full vocabulary together with Vernon's selective gate, and then as reference rather than as two active rule sets.

#### `ddd` + `ddd-implementing`

**Overlap.** Conflict 22%, overlap 80%, complementarity 48%.

**Why.** Same vocabulary and the same triggers. `ddd` is the conceptual and strategic source; `ddd-implementing` is the implementation-heavy version. Loaded together they double the pressure to introduce tactical mechanisms, and the implementation stack can turn modeling intent into ceremony where the original guidance would have stopped at model discovery or context clarification.

**Do.** Switch the primary as the work changes, instead of running both: `ddd` while the model and contexts are being worked out, `ddd-implementing` once the design is DDD and the task is building it. Run both only when a person wants Evans as the strategic source and Vernon as the implementation playbook for an intentionally DDD system.

#### `ddd-distilled` + `ddd-implementing`

**Overlap.** Conflict 20%, overlap 78%, complementarity 52%.

**Why.** `ddd-distilled` is a gate; `ddd-implementing` is a playbook. They complement each other only after DDD has been chosen and implementation detail matters. Loaded as equals, the implementation book weakens the gate, and the agent adds repositories, events, CQRS, projections or application-service ceremony before the gate's condition is met.

**Do.** Run the gate first. When an area has earned full tactical modeling, make `ddd-implementing` the primary for that work. `/ddd-implementing:ceremony-check` helps decide, for named areas, what to keep, trim or extract so the modeling matches the complexity.

### 5.4 Everyday coding guides

`clean-code`, `philosophy-of-design`, `code-complete` and `pragmatic-programmer` all govern everyday code: naming, decomposition, comments, tests, error handling, feedback. Four of their six pairs are rated overlap. Choose by the main risk in the code:

| Main risk | Primary |
| --- | --- |
| Local readability, naming, side effects, small scoped cleanup, everyday review | `clean-code` |
| Module depth, API shape, decomposition, abstraction boundaries, comments as contracts | `philosophy-of-design` |
| Larger production construction, defensive programming, validation, debugging, performance work | `code-complete` |
| Uncertainty, DRY knowledge, orthogonality, automation, feedback loops, team-level engineering behavior | `pragmatic-programmer` |

The two pairs among these that are rated complementary (`philosophy-of-design` with `code-complete`, and with `pragmatic-programmer`) are covered in [5.6](#56-complementary-pairs-the-upstream-notes-still-qualify).

#### `clean-code` + `philosophy-of-design`

**Overlap, with real tension.** Conflict 55%, overlap 72%, complementarity 42%. This is the highest conflict of any overlap pair, and upstream calls it the clearest tension pair outside the DDD family.

**Why.** The disagreement is concrete. `clean-code` pushes small, focused functions and sparing comments; `philosophy-of-design` pushes deep modules, splits by total complexity rather than size, and treats comments as contracts and rationale. An agent holding both can split code until the first is satisfied while the second calls the result shallow. Upstream cites the second book's own author noting these differences from the first, especially on method length and comments.

**Do.**

- Choose one primary: `clean-code` for local hygiene, `philosophy-of-design` for module and API decisions.
- If you want both, name the arbiter: `philosophy-of-design` decides module and API boundaries and decomposition; `clean-code` decides local naming, side effects and readability in the code you touch.
- Do not turn `inject_rules` on in both.

#### `clean-code` + `code-complete`

**Overlap.** Conflict 30%, overlap 78%, complementarity 45%. This is the highest overlap among the everyday guides.

**Why.** Both push readable code, cohesive routines, explicit data and control flow, useful comments, tests and reviewability. `code-complete` is broader (requirements, architecture fit, data, errors, debugging, reviews, tuning). The remaining tension is granularity: `clean-code` lets design emerge from tests and small cleanups, which can underweight upfront construction checks when risk is high, while the `code-complete` checklist can slow a small local cleanup.

**Do.** Use `clean-code` for small implementation and review changes where local reasoning is the problem; use `code-complete` for larger production construction, defensive programming, debugging, validation or performance-sensitive work. If you need both, make `code-complete` primary for risk and construction planning and limit `clean-code` to local readability in the code you touch.

#### `clean-code` + `pragmatic-programmer`

**Overlap.** Conflict 24%, overlap 68%, complementarity 54%.

**Why.** `clean-code` is local code shape; `pragmatic-programmer` is a broader operating style. They overlap on leaving code better, duplication, boundaries, feedback, tests, comments and names. The tension is dogma against pragmatism: fixed local forms against choosing the practice and the stopping point by real outcomes.

**Do.** Choose one general rule set. If you use both, `pragmatic-programmer` is the frame and `clean-code` is limited to local readability checks.

#### `code-complete` + `pragmatic-programmer`

**Overlap.** Conflict 18%, overlap 64%, complementarity 58%. Upstream says this pair is closer to complementary than `clean-code` with `code-complete`, but still a context-efficiency overlap.

**Why.** Both are general engineering guides for readable, verified, low-defect work, with heavy overlap on clarity, debugging from evidence, automation, reviews and small verified increments. `code-complete` is stronger at routine-level construction and defensive programming; `pragmatic-programmer` is stronger at uncertainty, reversibility, automation and feedback loops.

**Do.** Choose one as the broad guide. Use both only for a high-risk implementation that needs construction detail and uncertainty management together, and then bring the second in through its commands rather than `inject_rules`.

### 5.5 `refactoring` + `refactoring-guru`

**Overlap.** Conflict 8%, overlap 90%, complementarity 30%. This is the highest overlap in the set.

**Why.** Both solve one problem: changing structure without changing behavior. They repeat behavior preservation, smell diagnosis, the smallest treatment, verification and stop conditions. There is little contradiction; the cost is duplicate context. `refactoring` is the stronger process (small, behavior-preserving steps); `refactoring-guru` is a smell and technique checklist.

**Do.** Use `refactoring` for most code-change tasks. Use `refactoring-guru` instead when the task is specifically smell identification or technique selection, for example `/refactoring-guru:smell-to-treatment`. Use both only for a review-heavy cleanup that needs the process and an explicit smell catalog. Do not make both primary.

### 5.6 Complementary pairs the upstream notes still qualify

The upstream verdict for these pairs is complementary, but the pair documents attach a condition, and the scores are higher than for most complementary pairs. The cutoff is this document's, not upstream's: a complementary pair with conflict of at least 20% or overlap of at least 50%. Nine pairs meet it.

| Pair | Conflict / overlap / complementarity | Condition upstream attaches | What to do |
| --- | --- | --- | --- |
| `clean-architecture` + `ddd` | 36% / 62% / 70% | Load together only for business software where both forces are visible. Both add architecture vocabulary and boundaries, and they differ on which boundary comes first. | Use for a domain-rich application that also needs business rules insulated from framework and persistence churn. Do not add both to every feature. |
| `clean-architecture` + `ddd-distilled` | 22% / 55% / 68% | Use when business policy must be independent of frameworks and model language, aggregates or contexts also shape the code. The tension is ceremony. | Add layers, contexts, adapters and services only when real pressure calls for them. |
| `philosophy-of-design` + `clean-architecture` | 28% / 44% / 68% | `clean-architecture` sets the policy and detail boundaries, then `philosophy-of-design` rejects any port, adapter, service or layer that is only pass-through complexity. | Use while boundaries are being introduced or repaired. Prefer `clean-architecture` as primary when policy independence is the actual risk. |
| `philosophy-of-design` + `refactoring` | 28% / 46% / 74% | `refactoring` governs the change process and behavior preservation; `philosophy-of-design` governs whether the target actually reduces complexity. | Use for behavior-preserving restructuring toward deeper modules. Let `refactoring` arbitrate sequencing so design exploration does not become a rewrite. |
| `data-intensive-apps` + `release-it` | 28% / 46% / 80% | `data-intensive-apps` owns data semantics, `release-it` owns production survival. Neither arbitrates the other. | Load both for production systems where data correctness and failure behavior matter. Do not let operational patterns (retries, breakers, queues) hide a data-contract problem. |
| `philosophy-of-design` + `code-complete` | 20% / 50% / 62% | The risk is duplicate general guidance on the same local code-shape decision. | Name one arbiter per task. `philosophy-of-design` judges whether the resulting routines and interfaces reduce complexity; `code-complete` supplies the defect-risk checks. |
| `philosophy-of-design` + `pragmatic-programmer` | 20% / 50% / 62% | Same: duplicate general guidance. | Name one arbiter per task. Use `pragmatic-programmer` for ownership, DRY knowledge, reversibility, feedback and automation constraints. |
| `refactoring` + `legacy-code` | 10% / 58% / 76% | The tension is sequencing: structural pressure must wait until characterization or a safe seam exists. | `legacy-code` first to observe and create seams, then `refactoring` inside the controlled area. |
| `refactoring-guru` + `legacy-code` | 10% / 58% / 76% | Same sequencing tension. | Same order: `legacy-code` first, then smell diagnosis and treatment. |

### 5.7 The tension named for every other complementary pair

For the other 69 complementary pairs, each pair document names exactly one tension. They fall into six kinds.

| Tension | Typical pairs | Count | What it asks of you |
| --- | --- | ---: | --- |
| Scope creep | `refactoring`, `refactoring-guru` or `legacy-code` with a plugin that sets a target design, construction, architecture, data or production quality | 32 | Design or architecture improvements must not override behavior preservation, characterization or the current-smell stop condition. Let the refactoring or legacy plugin arbitrate sequencing. |
| DDD ceremony | A DDD plugin with `clean-code`, `philosophy-of-design`, `code-complete` or `pragmatic-programmer` | 12 | Tactical patterns must protect model meaning. They should not displace the simpler construction, refactoring, data or operational constraints of the other plugin. |
| Over-modeling | `data-intensive-apps` with the code-level, architecture, DDD and pattern plugins | 9 | Make the source of truth, consistency, retry behavior and schemas explicit before an abstraction hides them. |
| Mechanism cost | `release-it` with the code-level, architecture and DDD plugins | 9 | Reliability patterns add complexity. Apply them to real production failure modes, not to simple local code. |
| Pattern pressure | `enterprise-patterns` with `clean-code`, `philosophy-of-design`, `code-complete` or `pragmatic-programmer` | 4 | A pattern must be justified by enterprise forces. Do not add one where a small local change would do. |
| Boundary cost | `clean-architecture` with `clean-code`, `code-complete` or `pragmatic-programmer` | 3 | Ports, adapters and use cases belong where policy independence is actually at risk, not in every small change. |

## 6. Recommended bundles

Seven bundles for common situations. Each one has a primary plugin and on-demand companions, and each is built only from pairs that upstream rates complementary. Every pair inside every bundle was checked against the table in section 3. Numbers in parentheses are conflict / overlap / complementarity, as in that table.

Two plugins appear in most bundles because they are the safest companions: `refactoring` has one non-complementary pair in the whole set (with `refactoring-guru`) and `legacy-code` has none. The count of self-loading skills in each bundle is the number of descriptions Claude keeps in context for it; it is taken from each plugin's generated `docs/COMPONENTS.md`.

A bundle is a starting point. The ratings do not cover three plugins at once, and nothing here says a bundle produces better code.

### Bundle 1: Everyday coding and review

**For.** Developers who write and review ordinary application code every day: features, bug fixes, pull requests and small cleanups, in a repository that has tests in most places.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `clean-code` | Primary | 19 |
| `refactoring` | On demand | 20 |
| `legacy-code` | On demand | 18 |
| **Total** | | **57** |

**Why these fit.** For changing existing code, the upstream loading decision is that one rule set controls the safe sequencing of the change and the other defines the target shape. `refactoring` sequences; `clean-code` is the target (12% / 38% / 78%). Where tests are weak or behavior is unclear, upstream's order is to characterize behavior and create the smallest seam first, then apply the other book inside the controlled area, which is what `legacy-code` is for (12% / 38% / 78%). Upstream prefers `refactoring` when observable behavior must stay unchanged and `legacy-code` until you have control of the change.

**Primary.** `clean-code`, with `inject_rules` on. Bring in the others per task:

```text
/refactoring:review
/legacy-code:characterize apply_discounts
```

**Avoid adding.**

- `philosophy-of-design`: Overlap (55% / 72% / 42%). They disagree on function size and comment defaults. Swap it in as primary for module and API work (bundle 3); do not run both.
- `code-complete`: Overlap (30% / 78% / 45%). It repeats the implementation hygiene `clean-code` already carries. Swap it in when the work is larger production construction.
- `pragmatic-programmer`: Overlap (24% / 68% / 54%). Choose one general operating style (bundle 7).
- `refactoring-guru` next to `refactoring`: Overlap (8% / 90% / 30%).

**Pair check.** All 3 pairs inside this bundle are rated complementary upstream. Highest conflict: 12% (`clean-code` + `refactoring` and `clean-code` + `legacy-code`). Highest overlap: 58% (`refactoring` + `legacy-code`).

### Bundle 2: Rescuing weakly tested code

**For.** Teams that inherited code with thin or no tests and have to change it without breaking it.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `legacy-code` | Primary | 18 |
| `refactoring` | On demand | 20 |
| `clean-architecture` | On demand | 20 |
| **Total** | | **58** |

**Why these fit.** The upstream decision for risky changes to existing code is to use `legacy-code` to create observation and seams, then use the refactoring discipline for the behavior-preserving structural move (10% / 58% / 76%). The tension upstream names is sequencing: structural pressure waits until characterization or a safe seam exists. `clean-architecture` is the destination when tangled dependencies on frameworks, databases or UI are what make the code hard to test: first characterize and find the smallest seam, then apply the architecture rules inside the controlled area (12% / 38% / 78%).

**Primary.** `legacy-code`, with `inject_rules` on, when most of your work touches unprotected code. In a mostly well-tested repository, keep another plugin primary and bring `legacy-code` in per task for the areas without protection.

```text
/legacy-code:find-seam apply_discounts "a test that calls it without the database"
/refactoring:plan "extract pricing from apply_discounts"
```

**Avoid adding.**

- `refactoring-guru` next to `refactoring` (8% / 90% / 30%). It also overlaps `legacy-code` (10% / 58% / 76%), so it adds little here.
- `ddd-implementing` or `enterprise-patterns` as equals to `clean-architecture` (46% / 66% / 58%; 44% / 64% / 52%). Wait for seams before any large architecture; the `legacy-code` README says not to introduce one before basic seams exist.

**Pair check.** All 3 pairs inside this bundle are rated complementary upstream. Highest conflict: 12% (`clean-architecture` + `refactoring` and `clean-architecture` + `legacy-code`). Highest overlap: 58% (`refactoring` + `legacy-code`).

### Bundle 3: Module, API and architecture design

**For.** People designing or reshaping modules, libraries, internal service structure and the boundaries between them.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `philosophy-of-design` | Primary or on demand | 19 |
| `clean-architecture` | Primary or on demand | 20 |
| `refactoring` | On demand | 20 |
| **Total** | | **59** |

**Why these fit.** Upstream's decision for the two design books is to let `clean-architecture` set the policy and detail boundaries, then let `philosophy-of-design` reject any port, adapter, service or layer that is only pass-through complexity (28% / 44% / 68%). When existing code is being reshaped, `refactoring` governs the change process and behavior preservation while `philosophy-of-design` judges whether the target actually reduces complexity (28% / 46% / 74%); `refactoring` arbitrates sequencing. The two highest conflict figures in the pair check are the tensions upstream names: `clean-architecture` can introduce boundaries sooner than `philosophy-of-design` would accept, and `philosophy-of-design` can justify broader design exploration than `refactoring` allows.

**Primary.** One of the two design plugins, not both. Use `philosophy-of-design` when the risk is module depth, API shape and information hiding; use `clean-architecture` when the risk is dependency direction, framework leakage and replaceable details. The other is the on-demand check:

```text
/philosophy-of-design:review
/clean-architecture:place-code
```

**Avoid adding.**

- `clean-code` next to `philosophy-of-design` (Overlap: 55% / 72% / 42%).
- `enterprise-patterns` or `ddd-implementing` as equals to `clean-architecture` (44% / 64% / 52%; 46% / 66% / 58%).
- If the system is deliberately DDD, `ddd` is rated complementary with `clean-architecture` (36% / 62% / 70%), but upstream says to load both only where both forces are visible. See [5.6](#56-complementary-pairs-the-upstream-notes-still-qualify).

**Pair check.** All 3 pairs inside this bundle are rated complementary upstream. Highest conflict: 28% (`philosophy-of-design` + `clean-architecture` and `philosophy-of-design` + `refactoring`). Highest overlap: 46% (`philosophy-of-design` + `refactoring`).

### Bundle 4: Selective domain modeling

**For.** Teams building business software in which part of the domain is complex enough to justify modeling effort and the rest is not.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `ddd-distilled` | Primary | 19 |
| `data-intensive-apps` | On demand | 20 |
| `refactoring` | On demand | 20 |
| `legacy-code` | On demand | 18 |
| **Total** | | **77** |

**Why these fit.** Upstream calls `ddd-distilled` the better default when the agent needs selective, low-ceremony DDD, and it acts as a gate: it decides whether DDD is justified and how little ceremony to use. `data-intensive-apps` supplies the source-of-truth, consistency, schema-evolution and replay semantics that events and eventual consistency depend on; upstream's decision is to use both when a task changes state, events, schemas or ownership (10% / 35% / 80%). `refactoring` and `legacy-code` handle changes to existing code toward the model (12% / 38% / 78%; 12% / 38% / 78%).

**Primary.** `ddd-distilled`, with `inject_rules` on.

**When the work changes.** Switch the primary rather than adding a second DDD plugin. When an area has earned full tactical modeling, make `ddd-implementing` primary for that work (20% / 78% / 52%). When the work is context maps, core domain distillation or deeper model refactoring, make `ddd` primary (15% / 88% / 34%).

```text
/ddd-distilled:classify-subdomains
/data-intensive-apps:consistency-check orders
```

**Avoid adding.**

- `ddd` or `ddd-implementing` alongside `ddd-distilled` as equals. The fuller rule sets re-open decisions the gate has closed.
- `enterprise-patterns` side by side with `ddd-distilled` (Overlap: 50% / 66% / 48%). Use it in sequence for one pattern decision, after the gate.

**Pair check.** All 6 pairs inside this bundle are rated complementary upstream. Highest conflict: 12% (4 pairs). Highest overlap: 58% (`refactoring` + `legacy-code`).

### Bundle 5: Production services and data pipelines

**For.** Teams running services, APIs, queues, streams and jobs in production, where an outage or a wrong write has a cost.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `release-it` | Primary | 20 |
| `data-intensive-apps` | On demand | 20 |
| `legacy-code` | On demand | 18 |
| **Total** | | **58** |

**Why these fit.** Upstream loads these two together for production systems where data correctness and operational failure behavior both matter. `data-intensive-apps` owns data ownership, consistency, durability, replication, schema evolution, event flow and replay. `release-it` owns production failure behavior: timeouts, retries, isolation, overload, deployment, observability and recovery (28% / 46% / 80%). Neither arbitrates the other. The tension is that operational patterns can mask a data-contract problem if applied without the data rules. `legacy-code` covers the untested areas you have to touch (12% / 38% / 78%; 12% / 38% / 78%).

**Primary.** `release-it` for operational work, with `inject_rules` on. If the hard questions are consistency, ordering, replay and schemas, make `data-intensive-apps` primary instead. Only one gets `inject_rules`.

```text
/release-it:failure-mode-scan checkout
/data-intensive-apps:consistency-check checkout
```

**Avoid adding.**

- `release-it` on purely local design or construction work. Upstream prefers the other book there.
- Structural plugins that add layers before the source of truth and failure behavior are written down. For `data-intensive-apps`, the tension upstream records with `clean-architecture`, `ddd` and `enterprise-patterns` is over-modeling: data semantics must be explicit before abstractions hide ownership or failure behavior.

**Pair check.** All 3 pairs inside this bundle are rated complementary upstream. Highest conflict: 28% (`data-intensive-apps` + `release-it`). Highest overlap: 46% (`data-intensive-apps` + `release-it`).

### Bundle 6: Pattern-driven enterprise applications

**For.** Teams building server-side business applications where the question is which enterprise pattern fits (transaction script, table module, domain model, active record, service layer, data mapper), not whether to adopt DDD.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `enterprise-patterns` | Primary | 20 |
| `data-intensive-apps` | On demand | 20 |
| `refactoring` | On demand | 20 |
| **Total** | | **60** |

**Why these fit.** `enterprise-patterns` chooses patterns by force across workflow, domain logic, persistence, transactions, concurrency, session state and remoting. `data-intensive-apps` supplies source-of-truth, consistency and schema semantics under those application-level patterns, and upstream's decision is to load it when a task changes state, events, schemas or ownership (10% / 35% / 80%). `refactoring` reshapes existing code toward the chosen pattern, with the usual scope-creep tension (12% / 38% / 78%).

**Primary.** `enterprise-patterns`, with `inject_rules` on.

```text
/enterprise-patterns:choose-pattern "refund workflow with a payment gateway call"
/refactoring:plan "move refund rules out of the controller"
```

**Avoid adding.**

- `ddd` and `ddd-implementing`: the only two conflicting pairs in the set (62% / 68% / 44%; 66% / 72% / 40%).
- `ddd-distilled` as an equal (50% / 66% / 48%) and `clean-architecture` as an equal (44% / 64% / 52%).
- If the domain model starts to carry the design, change the primary to `ddd-distilled` or `ddd` and keep `enterprise-patterns` for narrow persistence, transaction or remoting decisions, as upstream describes.

**Pair check.** All 3 pairs inside this bundle are rated complementary upstream. Highest conflict: 12% (`data-intensive-apps` + `refactoring` and `enterprise-patterns` + `refactoring`). Highest overlap: 38% (`data-intensive-apps` + `refactoring` and `enterprise-patterns` + `refactoring`).

### Bundle 7: General engineering habits

**For.** Individuals and small teams that want one general operating style (automation, feedback, one owner per piece of knowledge, tracer bullets, reversible decisions) rather than a code-shape rulebook.

| Plugin | Role | Skills Claude can load on its own |
| --- | --- | ---: |
| `pragmatic-programmer` | Primary | 20 |
| `refactoring` | On demand | 20 |
| `legacy-code` | On demand | 18 |
| `release-it` | Optional, on demand | 20 |
| **Total** | | **78** |

**Why these fit.** Upstream describes `pragmatic-programmer` as a broad engineering operating style, not a guide to the local shape of code. `refactoring` and `legacy-code` supply the safe change sequence and the characterize-first order for existing code (12% / 38% / 78%; 12% / 38% / 78%). `release-it` is the optional addition when a change crosses a production boundary: keep the code and model shape, and add time limits, isolation and observability only where a real failure mode calls for them (12% / 34% / 78%).

**Primary.** `pragmatic-programmer`, with `inject_rules` on.

```text
/pragmatic-programmer:tracer-plan "import legacy invoices"
/legacy-code:characterize invoice_total
```

**Avoid adding.**

- `clean-code` as an always-on rule set alongside it (Overlap: 24% / 68% / 54%). Upstream calls the active guidance redundant unless roles are explicitly separated; the allowed split is `pragmatic-programmer` as the frame and `clean-code` limited to local readability checks.
- `code-complete` (Overlap: 18% / 64% / 58%). Use both only for a high-risk implementation that needs both kinds of pressure.

**Pair check.** All 6 pairs inside this bundle are rated complementary upstream. Highest conflict: 12% (5 pairs). Highest overlap: 58% (`refactoring` + `legacy-code`).

### Swap, do not add

Four plugins appear in no bundle because each is an alternative to a plugin that does.

| Plugin | Replaces | When |
| --- | --- | --- |
| `code-complete` | `clean-code` as primary in bundle 1 | Larger production construction, defensive programming, validation, debugging, performance work. |
| `ddd` | `ddd-distilled` as primary in bundle 4 | The work is strategic modeling: context maps, core domain distillation, deeper model refactoring. |
| `ddd-implementing` | `ddd-distilled` as primary in bundle 4 | The design is committed DDD and the work is aggregates, repositories, events and application services. |
| `refactoring-guru` | `refactoring` in any bundle | The task is smell identification or technique selection rather than a change process. |

## 7. What the plugin READMEs say about pairings

Every plugin README has a "Works with other plugins" section. It holds a table of the pairs that matter most for that book, with the upstream verdict and usually the percentages, followed by a recommended pairing that also says what not to combine. Every verdict and every labeled percentage in those tables was compared with the upstream pair files (275 comparisons) and none differs from the data in section 3.

Three things to know when reading them:

- Twelve of the 14 READMEs make their own plugin the always-on choice for the situation they describe (the `refactoring` README calls it a good candidate). The `data-intensive-apps` and `refactoring-guru` READMEs position their plugin as the on-demand one beside another primary. That is consistent with the one-primary rule, but the READMEs are not a joint recommendation. Section 6 chooses a primary per situation.
- Coverage differs. The `refactoring` README lists all 13 of its pairs; `legacy-code` and `release-it` state that every one of their pairs is complementary; the `ddd` README gives verdicts without percentages.
- Only the `refactoring` and `release-it` READMEs mark advice that goes beyond the upstream ratings as their own judgment. In the others, read the recommended pairing as that plugin's advice, not as an upstream rating.

| Plugin | Pairs it discusses | Pairing it recommends |
| --- | --- | --- |
| [`clean-code`](../plugins/clean-code/README.md) | `philosophy-of-design`, `clean-architecture`, `refactoring`, `legacy-code`, `code-complete`; the rest in a paragraph | `clean-code` always on; `refactoring` or `legacy-code` on demand; avoid `philosophy-of-design`, `code-complete` and `pragmatic-programmer` at equal weight |
| [`philosophy-of-design`](../plugins/philosophy-of-design/README.md) | `clean-code`, `refactoring`, `clean-architecture`, `ddd` (and the other two DDD plugins), `legacy-code` | `philosophy-of-design` always on for module and API work; `refactoring` or `legacy-code` on demand; avoid `clean-code` or `code-complete` at equal weight |
| [`clean-architecture`](../plugins/clean-architecture/README.md) | `ddd`, `ddd-implementing`, `enterprise-patterns`, `philosophy-of-design`, `legacy-code` and `refactoring` | `clean-architecture` always on; `clean-code`, `legacy-code`, `refactoring` or `philosophy-of-design` on demand; avoid `ddd-implementing` or `enterprise-patterns` at equal weight |
| [`code-complete`](../plugins/code-complete/README.md) | `clean-code`, `pragmatic-programmer`, `philosophy-of-design`, `refactoring` and `legacy-code`, `release-it` | `code-complete` always on; `refactoring`, `legacy-code` or `release-it` on demand; avoid `clean-code` and `pragmatic-programmer` at equal weight |
| [`data-intensive-apps`](../plugins/data-intensive-apps/README.md) | `release-it`, `ddd-implementing`, `clean-architecture`, `refactoring`, `legacy-code` (all five complementary) | `release-it` beside it, with this plugin as the on-demand data layer; at most one plugin always on; no structural plugin adds layers before the source of truth is written down |
| [`ddd`](../plugins/ddd/README.md) | `ddd-distilled`, `ddd-implementing`, `enterprise-patterns` (conflicting), `clean-architecture`, `legacy-code` and `refactoring` | `ddd` always on for domain-heavy work; `refactoring` or `legacy-code` on demand; do not stack `ddd-distilled`, `ddd-implementing` or `enterprise-patterns` as equals |
| [`ddd-distilled`](../plugins/ddd-distilled/README.md) | `ddd`, `ddd-implementing`, `enterprise-patterns`, `clean-architecture`, `data-intensive-apps` | `ddd-distilled` always on as the gate; `ddd-implementing` on demand once an area is modeled; `clean-code` or `legacy-code` per task; avoid `ddd` or `ddd-implementing` at equal weight |
| [`ddd-implementing`](../plugins/ddd-implementing/README.md) | `ddd`, `ddd-distilled`, `clean-architecture`, `enterprise-patterns` (conflicting), `data-intensive-apps` | For committed DDD: `ddd-implementing` always on, `data-intensive-apps` and `legacy-code` on demand. For teams still deciding: start with `ddd-distilled`. Avoid `ddd`, `ddd-distilled` or `enterprise-patterns` at equal weight |
| [`enterprise-patterns`](../plugins/enterprise-patterns/README.md) | `ddd-implementing` and `ddd` (both conflicting), `clean-architecture`, `refactoring`, `legacy-code`, `data-intensive-apps`; `ddd-distilled` in a paragraph | `enterprise-patterns` always on for server-side business applications; `refactoring` or `legacy-code` on demand; avoid `ddd`, `ddd-implementing` and `clean-architecture` at equal weight |
| [`refactoring`](../plugins/refactoring/README.md) | All 13 pairs, with scores | A candidate for primary when most work changes existing code; one target-design plugin per task, on demand; `legacy-code` first when tests are weak; not `refactoring-guru` by default |
| [`refactoring-guru`](../plugins/refactoring-guru/README.md) | `refactoring`, `legacy-code`, `clean-code`, `philosophy-of-design`, `clean-architecture`; the rest in a paragraph | A design or readability plugin always on and this plugin per refactoring task; `legacy-code` first for code without tests; avoid `refactoring` and `refactoring-guru` as co-primary |
| [`release-it`](../plugins/release-it/README.md) | Every pair is complementary; discusses `data-intensive-apps`, `clean-architecture`, `refactoring`, `legacy-code`, `philosophy-of-design` | `release-it` always on for services with real traffic; `data-intensive-apps` on demand; not for purely local design or construction work |
| [`pragmatic-programmer`](../plugins/pragmatic-programmer/README.md) | `clean-code`, `code-complete`, `refactoring`, `legacy-code`, `release-it` | `pragmatic-programmer` always on for general work; `refactoring` on demand, `legacy-code` first if there are no tests; avoid `clean-code` or `code-complete` always on beside it |
| [`legacy-code`](../plugins/legacy-code/README.md) | Every pair is complementary; discusses `refactoring`, `refactoring-guru`, `clean-code`, `clean-architecture`, `release-it` | `legacy-code` always on when most work is on weakly tested code, with `refactoring` on demand; in a well-tested repository keep another plugin primary and add this one per task; avoid `refactoring` and `refactoring-guru` at equal weight |

## Updating this document

The tables in sections 3 and 4, every score quoted in the text, and the pair checks in section 6 were generated from the 91 upstream pair files by a script that is not part of this repository. It reads, from each file, the verdict line, the Conflict, Overlap and Complementarity lines, the research basis and the loading decision, maps the upstream folder names to plugin slugs with `scripts/books.json`, and orders pairs by the README catalog. The prose was written from reading the pair documents and the plugin READMEs. When upstream changes, regenerate the tables from the new pair files and re-read the non-complementary pairs before editing section 5.
