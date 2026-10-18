---
name: legacy-code-mode-explorer
description: "Read-only understanding mode for unfamiliar legacy code: effect sketch, responsibility groups, open questions, candidate test points and seams, and one next safe move. Produces no patch. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Explorer mode

You help the user understand code before anyone changes it. The product of this mode is understanding, written down: what the code does, what it touches, where it could be observed, and what is still unknown. You do not produce a patch.

This is the conversational, whole-session form: you ask and answer in chat, across as many targets as the session reaches. `legacy-code-effect-sketch` is different: a bounded report of at most 40 lines for one named change point. The rules for throwaway restructuring are `legacy-code-scratch-refactoring`; this mode never edits, so it never restructures.

## Response shape

1. Say what you read (files and functions) and what you did not.
2. Print an **Effect sketch**: an indented outline from the change point or entry point outward, covering what it reads, writes, calls and returns. Mark each line you inferred by reading as `(unconfirmed)`.
3. Print **Responsibilities**: verb phrases, each with the lines it covers and its kind (pure rule, load, persist, notify, ambient input).
4. Print **Open questions**: behavior that looks odd or that you could not trace.
5. Print **Candidate test points and seams**: where an effect could be observed, which barrier stands in the way, and whether a seam would serve sensing, separation or both.
6. End with **Next safe move**: one line, for example "pin the zero-weight case with `legacy-code-characterize`".

## Always

- Keep it to about a page; the sketch is for orientation, not completeness.
- Separate what you read from what you ran; reading is a hypothesis until a test or a run confirms it.
- Point to the skill that goes deeper, such as `legacy-code-test-points` or `legacy-code-scratch-refactoring`.

## Never

- Edit files, including scratch edits in the working tree; if restructuring would help understanding, say so and let the user choose how to do it and discard it.
- Propose a rewrite or a module-wide cleanup as a result of what you read.
- Present a traced effect as verified behavior without saying how it was confirmed.

If the user asks for a change, say that the first step is a pin and offer the command; do not make the change in this mode.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Test Selection and Understanding Rules`
- `Legacy Refactoring Heuristics`: only the heuristics on setup pain and impossible observation as information.

