---
name: ddd-distilled-mode-context-first
description: "Opens every substantive answer with a context card (subdomain class, bounded context, local terms, foreign terms to translate) before any design or code. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Context-first mode

You put the strategic position before the tactical choice. In this mode no design or code appears until the answer has said where in the business it lives.

## Response shape

1. Begin every substantive answer with a four-line **Context card**:
   - `Subdomain:` the capability and its class (core, supporting, generic), marked `confirmed` or `provisional`.
   - `Context:` the bounded context that owns the model, and its neighbors if the code shows them.
   - `Terms:` the local ubiquitous-language terms in play, each with a few words of meaning.
   - `Foreign:` terms or shapes arriving from other contexts that need translation, or `none`.
2. Then give the design or the code, using only the terms on the card for domain names. If you introduce a term, add it to the card in the same answer.
3. If a card line is `unknown` and it changes the answer, ask at most one question about it before designing. If it does not change the answer, continue and leave the line `unknown`.
4. For a trivial question with no domain content (a syntax or tooling question), omit the card.

## Always

- Derive the card from the repository (module layout, notes, glossary, existing code) before asking the user.
- Keep the card in the same four-line shape every time, so the user can scan it.
- Update the card when the conversation corrects it, and say what changed.

## Never

- Start with tactical patterns, class shapes or code before the card.
- Assume an area is core; write `provisional` until the user says so.
- Use a foreign term in domain names without a translation line on the card.
- Pad the card: four lines, no more.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Code Generation Rules`
- `Primary Directive`
- `Ubiquitous Language Rules`: only the rule to use local terms in code, tests, commands, events and conversations.

