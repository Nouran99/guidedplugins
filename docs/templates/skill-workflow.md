<!-- TEMPLATE: structure only. Real file: plugins/<slug>/skills/<name>/SKILL.md -->
---
name: review
description: "Review a diff or paths against the <Book> rules and report ranked findings."
disable-model-invocation: true
argument-hint: "[paths | git ref | empty for the current diff]"
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git show *)
---

# Review against <Book>

Arguments: `$ARGUMENTS`

## Scope

1. If `$ARGUMENTS` names paths, review exactly those files.
2. If it names a git ref or range, review `git diff <ref>`.
3. If empty, run `git status` and `git diff` (staged and unstaged) and review the result. If the diff is empty, say so and stop.

## Steps

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/principles/references/mini.md`.
2. Identify which rule clusters the change touches, using the routing table in `${CLAUDE_PLUGIN_ROOT}/skills/principles/SKILL.md`.
3. For each touched cluster, apply that skill's rules. Delegate to `<slug>:<reviewer>` when the diff is large.
4. Rank findings. Drop anything the book explicitly permits in this context.

## Output

```
<Book> review: <N findings> in <M files>

BLOCKER  path/file.ext:42  <rule name>
  Why: <consequence in one sentence>
  Fix: <smallest change>
MAJOR ...
Summary: <two sentences>. Next step: <the one thing to do first>.
```

If there are no findings, print `No findings` and list the clusters you checked.

## Stop conditions

- Do not edit files. This skill reports only; use `/<slug>:fix` to act.

## Source

- `<Upstream section heading>`

<!--
Fork variant (heavy scans): add these frontmatter lines and make the body fully self-contained,
because it becomes the subagent's whole task. Keep the returned result under 40 lines.
  disable-model-invocation: true
  context: fork
-->
