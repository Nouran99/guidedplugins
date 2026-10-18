---
name: "use-cases"
description: "Use when writing or reshaping one application action: a use case class or function, its orchestration and the order to build a feature. Types crossing its boundary are boundary-models, rules that hold for every action are entities-and-invariants, tests are testing-seams."
---

# Use cases

Owns the application layer: one application action, coordinating entities and ports, with explicit input and output. The types that cross its boundary are `$clean-architecture:boundary-models`; the rules that hold regardless of the action are `$clean-architecture:entities-and-invariants`; splitting a class that holds many actions is `$clean-architecture:service-sprawl`.

## When to use

- You are adding a feature and must decide where its workflow lives.
- A function loads data, applies rules, saves, publishes and formats a reply in one body.
- You are reviewing a class named after an entity whose methods are unrelated actions.
- You are asked for a feature and need the order in which to produce its parts.

## Rules

1. **Let a use case coordinate entities and gateways.** `[MUST]` The workflow is visible in one place. Check: the body reads as load, call domain behavior, save or publish through ports.
2. **Make a use case represent one application action.** `[SHOULD]` Check: one entry point, named with an action verb from the application's own vocabulary (`RenewSubscription`, not `SubscriptionManager.handle`).
3. **Keep delivery, database and presentation-formatting concerns out of a use case.** `[SHOULD NOT]` Check: no status codes, headers, SQL, row types or display strings in the body.
4. **Never let a use case know web transport, status codes, cookies, headers or routing.** `[MUST NOT]` Check: the application directory imports nothing from the web layer, and no outcome is expressed as an HTTP concept.
5. **Depend on domain abstractions and models, define interfaces for the external behavior you need, and coordinate the workflow explicitly.** `[MUST]` Check: constructor parameters are ports and plain collaborators; the sequence of steps is written out, not hidden in callbacks or framework hooks.
6. **Do not return framework response types, hold controller logic, contain database access details, or format UI strings** unless the formatting is explicitly part of a presenter boundary. `[MUST NOT]` Check: the return type is a response model, an output boundary call or a domain value.
7. **Before building a non-trivial feature, name its use case, its input, its output and the ports it needs, and keep the orchestration in one place.** `[MUST]` Check: you can state all four before writing code.
8. **Prefer this build order:** domain rule or entity behavior, the use case, boundary interfaces, presenter contract, gateway contract, adapters, framework wiring. `[SHOULD]` Starting from the use case keeps the inner layers from being shaped by what is easy to build at the edge. Check: the first file you wrote is not a controller or a migration. Added judgment: skip the steps a feature does not need; a use case with nothing to present needs no presenter contract.
9. **Use the default shape:** a request model, the use case, an output boundary or response model, the ports, and adapter implementations kept outside. `[SHOULD]` Check: the use case's directory holds the first four and no adapter code.
10. **Leave out a use case that adds nothing.** Added judgment: a pass-through function that only forwards one call from a controller to a gateway adds a hop, not a boundary. If the action has no rule and no coordination, say so and decide with `$clean-architecture:boundary-economics` whether a use case earns its place.

## Procedure

1. Name the action with a verb from the business language, and write the input and output as fields.
2. List what the action must read, write, publish or ask the clock; each becomes a port (`$clean-architecture:ports-and-gateways`).
3. Decide which rules are enterprise rules (entity) and which exist only for this action (use case).
4. Write the use case against fake ports first; keep it free of transport and storage vocabulary.
5. Write the adapters last: a controller that builds the request and maps the response, and a gateway that implements each port.
6. Wire everything in the composition root (`$clean-architecture:composition-root`) and run the tests.

## Example

```java
// Before: one controller method is the whole application
@PostMapping("/appointments")
public ResponseEntity<?> book(@RequestBody Map<String, String> body) {
    Map<String, Object> slot = jdbc.queryForMap("select * from slots where id = ?", body.get("slotId"));
    if (slot.get("taken_by") != null) {
        return ResponseEntity.status(409).body("slot taken");
    }
    jdbc.update("update slots set taken_by = ? where id = ?", body.get("patientId"), body.get("slotId"));
    return ResponseEntity.ok(Map.of("startsAt", slot.get("starts_at").toString()));
}
```

```java
// After. Each type below is its own file in the application layer; there is no HTTP and no SQL.

// application/BookAppointmentRequest.java
public record BookAppointmentRequest(String slotId, String patientId) {}

// application/BookAppointmentResponse.java
public record BookAppointmentResponse(Instant startsAt) {}

// application/SlotCalendar.java: the port, declared in this layer
public interface SlotCalendar {
    Optional<Slot> find(String slotId);
    void save(Slot slot);              // stores the slot's taken state
}

// application/BookAppointment.java
public final class BookAppointment {
    private final SlotCalendar calendar;

    public BookAppointment(SlotCalendar calendar) {
        this.calendar = calendar;
    }

    public BookAppointmentResponse execute(BookAppointmentRequest request) {
        Slot slot = calendar.find(request.slotId())
            .orElseThrow(() -> new SlotNotFound(request.slotId()));
        slot.reserveFor(request.patientId()); // rule lives in the entity; throws when the slot is taken
        calendar.save(slot);           // the Before updated slots.taken_by; this write replaces it
        return new BookAppointmentResponse(slot.startsAt());
    }
}
```

The controller now builds a `BookAppointmentRequest`, calls `execute`, and maps `SlotNotFound` to 404 and the entity's "already taken" exception to 409. `SlotCalendar.find` returns `Optional<Slot>`; `Slot.reserveFor` throws when the slot is taken and otherwise marks itself taken; the adapter behind `save` writes the same `taken_by` column the old handler updated. The old handler had no explicit answer for an unknown slot (the query would throw), so the 404 is a deliberate addition rather than preserved behavior.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Transport in the use case | Status codes, headers or request types in the application directory | Return an outcome; map it in the adapter |
| God use case | One class with a `mode` or `type` parameter that switches between actions | Split into one use case per action |
| Formatting in the use case | Localized strings, date patterns or HTML built in the body | Return values; format in a presenter |
| Pass-through | A method that forwards its arguments to one gateway call | Question whether it earns a boundary |
| Hidden workflow | Steps spread across event listeners and framework hooks | Write the sequence in one place |
| Controller-first build | The first file of the feature is a route | Start from the rule and the use case |

## Trade-offs and exceptions

- Input and output models are produced "if needed" in the source's output expectations. A use case with a single argument can take it directly.
- A use case may return a response model or call an output boundary; both fit the default shape. Pick the one the delivery mechanism needs (a synchronous reply versus a streamed or pushed one).
- The build order is a `SHOULD`. When the domain rule already exists, start at the use case.
- Simple create-read-update-delete screens with no rules may not justify several layers; decide by cost with `$clean-architecture:boundary-economics` and say what you skipped.

## Verification

- [ ] The use case does exactly one application action, named with a verb.
- [ ] Nothing in it knows transport, storage or presentation.
- [ ] Every external effect goes through a port declared in this layer.
- [ ] Business rules sit in entities, and only action-specific logic remains here.
- [ ] A test runs the use case with fake ports, with no framework and no database.
- [ ] The adapters and wiring were written after the use case.

## Related

`$clean-architecture:boundary-models` for the request and response types; `$clean-architecture:ports-and-gateways` for the ports; `$clean-architecture:new-feature` to build a feature end to end; `$clean-architecture:extract-use-case` to pull an action out of existing code; `clean-architecture-use-case-reviewer` to review a diff.

## Source

- `Application Layer`
- `Non-Negotiable Rules`: rules 5 and 8, use cases that do not know the web and use cases that orchestrate one action.
- `Define the Use Case First`
- `Preferred use case shape`
- `Output Expectations`: only the default of producing a focused use case, with input and output models if needed.
