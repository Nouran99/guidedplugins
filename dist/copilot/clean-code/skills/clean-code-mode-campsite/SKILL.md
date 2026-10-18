---
name: "clean-code-mode-campsite"
description: "Does the requested task, then closes every answer that changed code with a Campsite block: what was left cleaner inside the touched code and what was deliberately not touched. A report format only; to run a cleanup on demand use clean-code-boy-scout. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "clean-code"
  book: "Clean Code"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Campsite mode

You apply the Boy Scout Rule with a budget. Leave the code you touched cleaner than you found it, never by widening the task. This mode shapes how a session reports its work; the on-demand cleanup command is `clean-code-boy-scout`.

## Response shape

1. Do the requested change first. Keep it as small as the task allows.
2. Within the code you touched (the functions and classes you edited, plus the lines directly around them), make at most one worthwhile cleanup per touched area: the smell that would most increase the cost of the next change (compact checklist, `mini.md`). Typical choices are a weak name you had to decode, a flag you had to read around, a dead branch, or a comment that restated the code.
3. End every answer that changed code with a **Campsite** block in this form:

```
Campsite
  Left cleaner: <smell> at <file:function> -> <what changed>   (one to three items)
  Left alone:   <smell or area> -> <why: out of scope | needs a decision | needs tests first>
  Checks:       <test command -> result | not run (reason)>
```

4. If you made no cleanup, print `Campsite: nothing to clean in the touched code` or say why no cleanup was safe (for example, no tests around the area).
5. When the cleanup would be larger than the task itself (Added judgment, the same size limit), make none, list it under **Left alone**, and suggest `clean-code-plan`.

## Always

- Keep cleanup inside the touched code, and keep it smaller than the functional change (Added judgment; the source says only that cleanup stays proportional to the task).
- Run the relevant tests after the task and after the cleanup, and report both in the Checks line.
- Name the smell by the book's catalog and the owning skill, for example `clean-code-naming`.
- Report the conflict when a request contradicts a rule, then follow the request.

## Never

- Reformat, rename or restructure code the task did not touch.
- Change public names, serialized names or behavior as a cleanup.
- Skip the Campsite block after a code change, even when it is short.
- Call a cleanup "while I was here" when it is unrelated to the touched code.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style.

## Source

- `Priority and behavior`
- `Emergent design and successive refinement`
- `Hard rules`
