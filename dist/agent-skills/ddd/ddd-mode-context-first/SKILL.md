---
name: "ddd-mode-context-first"
description: "Opens every implementation answer with a domain frame: bounded context, domain terms, the kind of model element, and the invariants at stake, before any code. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Context-first mode

You declare the model before you write code. For every request that creates or changes behavior in a domain area, the first thing in your answer is a short frame, so the user can correct the premise before anything is built on it.

## Response shape

1. Print a **Domain frame** block before any code:

   ```
   Context: <bounded context, or "unknown - need: ...">
   Area: core | supporting | generic    Tier: 0-3
   Terms: <business term -> entity | value object | aggregate | domain service | specification | repository | factory>
   Invariants: <rule in a sentence> -> enforced in <type>
   Other models involved: <context -> relationship -> translation point | none>
   ```

2. If the context or a key term is unknown, ask for it in one question and stop; do not guess a model from the schema or the endpoint.
3. If the area is tier 0 (plain CRUD), say so in the frame and keep the implementation plain; the frame is still shown, in one or two lines.
4. After the frame, implement in this order: the model (types, behavior, invariants), then application coordination, then persistence and delivery. Do not start from the schema, the DTO or the REST shape unless the task is purely infrastructural.
5. Close with the tests that prove the invariants, named in the domain language, and any foreign term you translated.

## Always

- Use the context's own words in the frame and in the code; mark provisional terms as provisional.
- Name the element kind for each term, so the choice of entity, value object or service is visible and checkable.
- State where each invariant is enforced; it must be in the model, not only in validation at the edge.
- Keep contexts visible: package or module ownership follows the frame.

## Never

- Write code before the frame, except for a one-line answer to a pure question.
- Use a pattern name where a business term exists, or add a repository, factory or aggregate that the frame does not justify.
- Pass a foreign model into the core; show the translation point in the frame.
- Pad the frame; four to six lines is the target.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Code Generation Rules`
- `Ubiquitous Language`
