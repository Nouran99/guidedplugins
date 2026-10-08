---
name: formatting
description: "Use when arranging a file, ordering functions, grouping related code, or reacting to formatting noise in a diff. Covers vertical ordering, proximity of related concepts, file size, line length, indentation, brittle alignment and formatter-first practice."
---

# Formatting and structure

Governs how code is laid out so a reader can scan it: ordering of functions and declarations, closeness of related concepts, file size and visual noise. Statement order inside one function is `/clean-code:function-shape`; whether a class should exist at all is `/clean-code:class-design`.

## When to use

- You add a function or field and must decide where it goes in the file.
- A file reads bottom-up, or related functions are far apart.
- A diff is mostly whitespace, import reordering or column alignment.
- A file has grown so large that finding things needs search.

## Rules

1. **Use consistent formatting across the repository.** The formatter and linter configuration is the authority, not personal taste. Check: running the project formatter on the touched files produces no further changes.
2. **Format code to reveal structure and intent.** Blank lines separate ideas; lines that belong together stay together. Check: a quick scroll shows distinct paragraphs, not a wall.
3. **Keep related concepts close together.** A variable is declared near its first use; a helper sits near its only caller; functions that call each other are neighbors. Check: you do not need to jump more than a screen to follow one idea.
4. **Keep files, classes and functions reasonably small.** Check: a file that holds several unrelated concepts is split by concept, not by line count; see `/clean-code:class-design`.
5. **Use vertical ordering to tell the story from higher level to lower level.** Public and high-level functions first, details below, with each caller above its callees where the language allows it. Check: reading from the top, no name is used before you have seen why it matters.
6. **Use indentation to clarify scope, not to hide complexity.** Deep indentation is a symptom to fix in the structure, not something to flatten with formatting tricks. Check: you did not collapse nested blocks onto one line to make a long function look short.
7. **Avoid excessive line length when it hurts readability.** Check: no horizontal scrolling in review; a long expression is broken at a meaningful boundary or given a name.
8. **Avoid decorative alignment that is brittle during edits.** Aligned columns of assignments or comments make every later edit touch neighboring lines. Check: the diff of a one-line change is one line.
9. **Preserve a layout that supports fast scanning.** Group declarations, then logic, then return; keep similar things in similar positions across files. Check: a reader new to the file can find the entry point in seconds.
10. **Do not reformat code you were not asked to touch.** Formatting churn hides the real change. Added judgment: if the file is badly formatted and the formatter is not enforced, propose a formatting-only change separately from the behavior change.

## Procedure

1. Run the repository's formatter on the files you changed, if one exists. Do not argue with it.
2. Check the top-of-file view: does the first screen tell the reader what the file is for and where its entry points are?
3. For each new function, place it directly below its first caller (or, in languages that require definition before use, directly above, and make the entry point easy to find).
4. Move declarations closer to their use if you are already editing those lines.
5. Remove alignment padding only in lines you are editing anyway.
6. If a file is long because it mixes concepts, note the split as a follow-up; do it only if the task is about that file's structure.

## Example

```go
// Before: details first, story last, helper far from its caller
func formatMoney(cents int64) string { return fmt.Sprintf("%d.%02d", cents/100, cents%100) }
func lineTotal(l Line) int64            { return int64(l.Qty) * l.UnitCents }
var taxRate = 0.2
func (r Receipt) Render() string {
	var b strings.Builder
	for _, l := range r.Lines { b.WriteString(describe(l)) }
	b.WriteString(footer(r))
	return b.String()
}
func describe(l Line) string { return fmt.Sprintf("%-20s %s\n", l.Name, formatMoney(lineTotal(l))) }
func footer(r Receipt) string { return "Total " + formatMoney(total(r)) }

// After: entry point first, each helper below the code that needs it
func (r Receipt) Render() string {
	var b strings.Builder
	for _, l := range r.Lines {
		b.WriteString(describe(l))
	}
	b.WriteString(footer(r))
	return b.String()
}

func describe(l Line) string  { return fmt.Sprintf("%s %s\n", l.Name, formatMoney(lineTotal(l))) }
func footer(r Receipt) string { return "Total " + formatMoney(total(r)) }
func lineTotal(l Line) int64  { return int64(l.Qty) * l.UnitCents }
func formatMoney(cents int64) string { return fmt.Sprintf("%d.%02d", cents/100, cents%100) }
```

The unused `taxRate` variable in the first version was a distraction; moving things also exposed it as dead code (`/clean-code:smells-redundancy`).

## Anti-patterns

- **Bottom-up file.** Helpers at the top, entry point at the bottom. Detect: the first public function appears after a screen of private helpers.
- **Declaration at a distance.** A variable declared at the top of a function and first used forty lines later. Detect: distance between declaration and first use.
- **Column-aligned assignments.** Detect: runs of `=` or `:` padded with spaces; a rename forces many-line diffs.
- **Formatting-only noise in a behavior diff.** Detect: hunks with only whitespace, import order or brace style changes.
- **Collapsed nesting.** Detect: multiple statements on one line to hide depth.
- **Concept sprawl.** A file where unrelated concepts are interleaved. Detect: two groups of functions that never call each other.

## Trade-offs and exceptions

- Languages with required definition order (some C-family, scripting) cannot always put the caller first. Keep the entry point easy to find instead.
- Generated code and vendored files follow their generator, not this skill.
- A team's existing layout wins over personal preference; match it unless the layout itself hides structure.
- Aligned tables in tests or lookup data can be easier to scan than unaligned ones when they rarely change; judge by edit frequency.

## Verification

- [ ] The project formatter reports no changes on the touched files.
- [ ] The entry point of each touched file is findable on the first screen.
- [ ] Each new function sits next to its caller or its related concepts.
- [ ] The diff contains no hunk that is formatting only, unless that was the task.
- [ ] No touched line relies on decorative alignment.

## Related

`/clean-code:function-shape` for ordering within a function; `/clean-code:class-design` for splitting a file by concept; `clean-code:layout-reviewer` to review layout in a diff.

## Source

- `Formatting and structure`
