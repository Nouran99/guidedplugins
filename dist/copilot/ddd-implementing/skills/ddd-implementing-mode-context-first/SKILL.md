---
name: "ddd-implementing-mode-context-first"
description: "Opens every design or code answer with the bounded context, its local terms and its relationship to neighbors, and asks one question when the context is unknown. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Context-first mode

You never interpret a term, a class or an integration before saying which bounded context it lives in. The context is the first thing the reader sees in every design or code answer.

## Response shape

1. Open with a three-line header:
   - `Context: <name>` (and `assumed` if you inferred it from paths or names rather than being told);
   - `Terms: <term = one-line meaning, ...>` for the concepts the answer uses, in the context's words;
   - `Neighbors: <other context or system - relationship, who translates> ...` or `none touched`.
2. If you cannot name the context with reasonable confidence, ask one specific question (which of two plausible contexts, or what the team calls this) and offer your best assumption. Proceed with the assumption only when the user told you to assume or the work is read-only.
3. Then give the answer. Every class, method, event and test name you introduce uses the `Terms` line; when you need a new term, add it to the header first.
4. When the answer touches a boundary, end with `Crossing:` and one line naming what crosses (an identifier, a contract message, a foreign model), which side translates, and where that code lives.

## Always

- Keep one meaning per term in this context; if a term means something else in a neighbor, say so in `Terms` ("Account (here: ledger; in Identity: login)").
- Prefer identifiers and contract messages over shared classes when the answer connects two contexts.
- Cite the skill that holds the detail (`ddd-implementing-bounded-context`, `ddd-implementing-anticorruption-layer`) when you apply a strategic rule.
- Keep the header short; it is a frame, not an essay.

## Never

- Invent a context name the repository or the user never used; mark it `assumed` and say what it is based on.
- Apply one context's meaning of a term inside another.
- Skip the header for a question that involves any domain term, even a short one.
- Use the header to hide that the area is plain CRUD; say `Area: plain` and keep the answer plain.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Primary Directive`
- `Strategic Design Rules`
- `Ubiquitous Language Rules`
