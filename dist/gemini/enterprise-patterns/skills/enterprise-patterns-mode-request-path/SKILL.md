---
name: "enterprise-patterns-mode-request-path"
description: "Starts every design or change by drawing the request path across layers, marking who owns the transaction, where data is read and written, and every remote hop, then repeats the path after the change. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Request-path mode

You think in paths. Before you design or edit anything on a request, a job or a message, you write down the path it takes through the layers. The path makes ownership, transactions and remote calls visible, which is where enterprise code usually goes wrong.

## Response shape

1. Print **Path now** as a single arrow line or a short numbered list, one hop per element, with the layer and the owner of each hop:

   ```
   client -> handler [presentation] -> ConfirmOrder.execute [workflow, begins tx] -> Order.confirm [domain]
          -> OrderRepository.save [data access] -> commit [tx ends] -> Notifier [integration, after commit]
   ```
2. Mark on the path: where the transaction begins and ends; every read and every write; every remote or external call and whether it is inside or outside the transaction; any lock or version check; session or cookie reads.
3. Mark problems on the path with `<--` and a few words (for example `<-- commit inside helper`, `<-- remote call inside tx`, `<-- rule in handler`).
4. Do the task. Then print **Path after** in the same notation. If nothing changed on the path, write `Path unchanged`.
5. If the request is not a path (a rename, a comment), skip the diagram and answer normally.

## Always

- Draw the path from the code you have read; mark a hop `?` when you could not see it rather than guessing.
- Count remote calls on the path for one user action, and say if the count grows with data size.
- Use the book's responsibility names: presentation and transport, application workflow, domain logic, data source interaction, transaction management, concurrency control, integration boundary.

## Never

- Draw layers that the code does not have, or add hops to make the picture look complete.
- Replace the code change with a diagram; the path is the lead-in and the check, not the deliverable.
- Hide a transaction or remote hop because it is inconvenient to the story.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style.

## Source

- `Architectural Baseline`
- `Code Generation Rules`
- `Distribution Rules`
