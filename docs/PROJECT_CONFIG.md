# Project settings: `.guided-plugins.json`

One optional file at the root of **your** repository tells the book plugins how to behave in that project. The skills and subagents read it
when they review, plan or check code; the CI runner ([CI.md](CI.md)) reads it too. Without the file everything works as before.

```bash
node /path/to/guidedplugins/scripts/guided-config.mjs init --preset everyday-code     # writes ./.guided-plugins.json
node /path/to/guidedplugins/scripts/guided-config.mjs explain                          # the effective settings in words
node /path/to/guidedplugins/scripts/guided-config.mjs validate                         # exit 1 on a mistake
```

Or ask the assistant: `/guided:config` walks through the choices and writes the file. [guided-plugins.schema.json](guided-plugins.schema.json) is the
JSON Schema (editors that read `$schema` complete and check the keys).

```json
{
  "$schema": "https://raw.githubusercontent.com/Nouran99/guidedplugins/main/docs/guided-plugins.schema.json",
  "version": 1,
  "primary": "clean-code",
  "secondary": ["refactoring"],
  "strictness": "normal",
  "ignore": ["vendor/", "**/*.generated.*", "src/legacy/"],
  "maxFindings": 15,
  "failOn": "major"
}
```

## The settings

| Key | Values | Meaning |
| --- | --- | --- |
| `primary` | a book slug, for example `clean-code` | The book that decides when books disagree. Reviews lead with its rules. |
| `secondary` | up to 3 book slugs | Books applied for the decisions they cover. Where one disagrees with the primary book, the review says so as a note instead of a finding. |
| `strictness` | `relaxed`, `normal` (default), `strict` | `relaxed` reports blockers and majors. `normal` adds minors. `strict` adds nits. |
| `ignore` | globs | Files not reviewed and not edited. Like `.gitignore` for the syntax that is supported: a pattern without a slash matches at any depth (`*.min.js`), a leading slash anchors it at the root (`/vendor/`), a trailing slash means a folder (`vendor/`), `*` and `?` stay inside one folder, `**` crosses folders. Negation (`!`), comments (`#`), character classes (`[ ]`) and backslash escapes are not supported, and `validate` rejects them instead of silently never matching. |
| `maxFindings` | 1 to 100 (default 15) | A report lists at most this many findings, most serious first, and says how many it left out. |
| `failOn` | `blocker`, `major` (default), `minor`, `nit`, `never` | For CI (`guided-review-ci.mjs` and the GitHub Action): fail when a finding at this level or above remains. The pre-push hook does not read it: it uses `GUIDED_FAIL_ON` (default `blocker`). Reviews inside the assistant ignore it. |

## Choosing books

Books overlap and some pull in opposite directions (Clean Code asks for small functions, A Philosophy of Software Design for deep modules).
`validate` and `init` print a note for every pair you choose that [COMPATIBILITY.md](COMPATIBILITY.md) rates *Overlap* or *Conflicting*. A good setting is
one primary book and one or two **complementary** secondary books. The five presets are chosen that way:

| Preset | Primary | Secondary | For |
| --- | --- | --- | --- |
| `everyday-code` | clean-code | refactoring | Ordinary application code, reviewed and improved a little at a time. |
| `legacy-rescue` | legacy-code | refactoring, clean-code | Changing code that has no tests. |
| `backend-service` | clean-architecture | release-it, data-intensive-apps | Services that must survive production. |
| `domain-model` | ddd-distilled | clean-architecture, refactoring | Business-rule-heavy code. |
| `system-design` | philosophy-of-design | clean-architecture, code-complete | Designing modules, APIs and boundaries. |

`/plugin install guided-<preset>@guided-plugins` installs a preset's plugins in one step (Claude Code); [AGENTS_SUPPORT.md](AGENTS_SUPPORT.md) has the other agents.

## How the plugins use it

Every book plugin has a *Project settings* section in its `principles` skill, and its `review`, `audit`, `checklist`, `fix` and `plan` workflows and its
`lead` and `final-gate` agents apply it:

1. Look for `.guided-plugins.json` at the repository root. If it is missing or unreadable, carry on with the defaults.
2. Leave out files that match `ignore` (say how many were left out).
3. Report at the level `strictness` sets, and cap the report at `maxFindings`.
4. If the plugin is not the `primary` book, report a conflict with the primary book as a *disagreement*, not as a finding. If it is the
   primary book, its rule wins.

The settings are instructions to a model, like the rest of a skill: `ignore` and `strictness` are followed reliably in practice, but not
guaranteed. The CI runner applies them a second time in code, so a check cannot be tricked by a missed instruction.
