# Contributing

Thanks for helping. The goal is plugins whose advice is specific, faithful to the source and cheap on context.

## Ground rules

1. **Faithful to the source.** Components apply the upstream rule sets in `skills/principles/references/full.md`. Preserve modal strength (MUST / SHOULD / avoid). Do not invent rules.
2. **No book text.** Paraphrase and use original examples. Do not paste passages from the books or from Refactoring.Guru.
3. **One job per component.** If a new component overlaps a sibling, improve the sibling instead.
4. **Cite sources.** Every component ends with a `## Source` section naming the upstream headings it applies, in backticks, exactly as spelled upstream.
5. **Keep context cheap.** Only workflow-style skills may use `disable-model-invocation: true` to stay out of context; at most 20 skills per plugin may be model-invocable.

## Workflow

```bash
git checkout -b improve-<plugin>-<topic>
# edit plugins/<slug>/...
node scripts/gen-catalog.mjs
node scripts/validate-all.mjs
```

Both commands must succeed before you open a pull request. CI repeats them and fails if generated files are not committed.

## Changing a component

- Edit the component, then regenerate: `node scripts/gen-catalog.mjs plugins/<slug>`.
- Bump the plugin `version` in `.claude-plugin/plugin.json` (patch for wording, minor for new components, major for renamed or removed ones) and add a line to the plugin `CHANGELOG.md`.
- Keep `docs/DESIGN.md` in step if you add, remove or merge components.

## Adding a book

1. Add an entry to `scripts/books.json`.
2. `node scripts/new-plugin.mjs <slug> --upstream <clone of ciembor/agent-rules-books>`
3. Follow [docs/PLUGIN_SPEC.md](docs/PLUGIN_SPEC.md) section by section; the templates are in [docs/templates](docs/templates).
4. `node scripts/gen-catalog.mjs && node scripts/validate-all.mjs`

## Reporting inaccuracies

Use the "Rule accuracy" issue template and cite the upstream section and what the component says versus what the source says.

By contributing you agree that your contributions are licensed under the MIT License.
