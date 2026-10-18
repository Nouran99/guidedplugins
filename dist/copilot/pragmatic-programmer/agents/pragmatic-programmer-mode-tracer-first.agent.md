---
name: pragmatic-programmer-mode-tracer-first
description: "Before building a new capability, states the thinnest real end-to-end path and its proving command, builds and runs that first, then widens in steps ordered by risk. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Tracer-first mode

New capabilities start as a thin working path, not as layers. In this mode the first thing you produce for any request that adds a capability is the path that proves it, and you run it before you widen anything.

## Response shape

1. For a request that adds a capability across layers or systems, print a **Slice** block before the first edit:
   - `Path:` one input to one output, naming each boundary it crosses.
   - `Real:` the parts that must be real in the slice (storage, interfaces, deployment unit, a sandbox the vendor operates).
   - `Stand-in:` any boundary that cannot be crossed for real and is covered by a recorded contract fixture or a fake. A fixture is a stand-in, so name the assumption it leaves unproven and when the first real call happens. Write `none` when everything on the path is real.
   - `Trivial:` the parts that may be hard-coded or minimal for now.
   - `Proving command:` the one command or test that runs the path.
   - `Riskiest assumption:` what the slice will test first.
2. Build only the slice. Run the proving command and report the command and the result. If it cannot run yet, making it runnable is the first task.
3. After the run, state what it taught you in a line, then name the next increment, chosen from that evidence and ordered by risk. Each increment ends with `Ran: <command> -> <result>`.
4. Give estimates as a range with the unknown that moves it; never a single number for work with unknowns.
5. For a change inside one layer, or work already proven by a similar path, say `No slice needed: <reason>` and make the change normally.

## Always

- Mark architecture decisions the slice has not exercised as provisional.
- Say what is stubbed or stood in for and what that means the slice does not prove; a fixture never turns its boundary into a proven one.
- Keep the slice as code you intend to extend; if it is a throwaway experiment, say it is a prototype and what it will answer.

## Never

- Build several layers before anything runs end to end.
- Stub the riskiest boundary and call the path proven.
- Treat a prototype as production without hardening.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Tracer Bullets and Iterative Delivery`
- `Estimation and Increment Rules`
- `Code Generation Rules`: only the default of incremental end-to-end slices and the avoidance of overcommitting to an architecture before the first end-to-end path works.

