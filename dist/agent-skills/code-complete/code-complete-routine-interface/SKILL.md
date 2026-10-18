---
name: "code-complete-routine-interface"
description: "Use when a routine's signature is the problem: long parameter lists, boolean mode flags, unrelated parameters, or return values that are easy to misuse. Body and naming: code-complete-routine-design. Flag fields and sentinels in data: code-complete-data-types."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Routine interface

Judges what crosses a routine's boundary: parameters in, value out. The inside of the routine is `code-complete-routine-design`; flag fields and sentinel values stored in data are `code-complete-data-types`.

## When to use

- A signature has many parameters, or callers pass several arguments that always travel together.
- A boolean (or a magic string or number) parameter switches the routine between two behaviors.
- A caller can misuse the result: forgetting to check a status, mixing up two same-typed arguments, reading a value that is only valid in some cases.
- You are about to add one more parameter to an existing signature.

## Rules

1. **Keep the interface as small as practical.** Why: every parameter is something each caller must understand and each test must vary. Check: each parameter is used by the routine, and no parameter could be derived from another one.
2. **Avoid long parameter lists.** The source gives no count. Added judgment: five or more parameters is a signal to look for a group that belongs together, not a violation by itself. Check: parameters that are always passed together are a missing type.
3. **Avoid flag arguments; a boolean parameter that switches the routine's mode is forbidden.** Why: the call site `render(page, true)` says nothing and the routine is really two routines. Check: no parameter selects between two different behaviors; split into two named routines, or pass a named alternative if the set is closed.
4. **Do not pass unrelated parameters.** Source anti-pattern wording is "long signatures with many unrelated parameters". Check: every parameter belongs to this routine's purpose; a parameter present only to be forwarded to a callee is a smell.
5. **Make return values meaningful and hard to misuse.** Why: a return that must be interpreted with outside knowledge is a defect waiting for a caller. Check: the return type says what it is; there is no value that means "failed" and also looks like data.
6. **Separate the question from the change.** Added judgment: a routine that returns information and also modifies state surprises callers; split it, or name it for both (`removeAndGetFirst`).
7. **Keep same-typed parameters distinguishable.** Added judgment: two adjacent `string` or `int` parameters are the usual swap bug. Check: a wrapper type, a record parameter or a named-argument call style makes the swap impossible or visible.
8. **Return the result instead of filling an out-parameter** where the language allows it. Added judgment. Check: callers do not pre-allocate objects for the routine to fill.
9. **Document what the signature cannot say:** units, valid ranges, ownership and whether null or empty is accepted. Link: `code-complete-assertions-and-contracts`.
10. **Separate setup, validation, computation and side effects when they are conceptually different.** Why: one wide signature that serves all of them hides which inputs each phase needs. Added judgment on how to tell: if the parameters fall into groups that only some branches use, the routine is two routines (`code-complete-routine-design`).

## Procedure

1. List the signature of each changed routine and, for each parameter, one sentence on why this routine needs it.
2. Mark boolean, magic-number and magic-string parameters, and any pair of adjacent same-typed parameters.
3. Group parameters that always travel together and decide whether they form a named type.
4. Replace each mode flag with two routines or a named alternative. Update callers in small steps, tests after each.
5. Re-read every call site: it should be understandable without opening the routine.
6. Check the return value against rule 5 and update callers that checked the old convention.

## Example

```go
// Before: the bool changes behavior, the three ints are easy to swap, -1 means "not found"
func FindRoom(building int, floor int, capacity int, includeBooked bool) int { /* ... */ }

room := FindRoom(2, 3, 12, false)
if room == -1 { /* none found */ }

// After: two named queries, a request type for the parameters, and a result the caller cannot misread
type RoomQuery struct {
    Building int
    Floor    int
    MinSeats int
}

// only unbooked rooms
func FindAvailableRoom(q RoomQuery) (RoomID, bool) { /* ... */ }

// booked or not
func FindAnyRoom(q RoomQuery) (RoomID, bool) { /* ... */ }

if room, ok := FindAvailableRoom(RoomQuery{Building: 2, Floor: 3, MinSeats: 12}); ok {
    reserve(room)
}
```

## Anti-patterns

- **Mode flag.** `save(doc, true)`. Detect: a boolean parameter whose true and false branches share almost no code.
- **Parameter train.** Five parameters that every caller builds from one object. Detect: callers pass `a.x, a.y, a.z` field by field.
- **Pass-through parameter.** A parameter used only to hand to another routine. Detect: the name appears once in the body, as an argument.
- **Status-and-data return.** A value that is data when valid and a code otherwise (`-1`, empty string). Detect: callers compare the result with a literal before using it.
- **Swap trap.** Two adjacent same-typed arguments. Detect: a call where swapping the last two arguments compiles.

## Trade-offs and exceptions

- The source says to avoid flags and long lists; it does not forbid every boolean. A boolean that names a genuine on/off setting (`setEnabled(true)`) is a true binary meaning (`code-complete-data-types`) and is not a mode flag.
- Adding a request type adds a name to learn. Do it when the parameters recur across routines or when swapping them has caused or could cause a defect; not for a signature used once.
- Language conventions win: named arguments (Python, Kotlin) already solve part of the swap problem; builder patterns are not required.
- Public signatures are contracts. Changing one is a behavior change for callers: do it deliberately, not as a side effect of a cleanup.

## Verification

- [ ] No changed signature has a parameter that switches between two behaviors.
- [ ] Every parameter is used by the routine for its stated purpose.
- [ ] Parameters that always travel together are named as a group, or the reason they are not is clear.
- [ ] No return value needs a magic literal comparison before use.
- [ ] Each call site reads correctly without opening the routine.

## Related

`code-complete-routine-design` for the body; `code-complete-data-types` for sentinels and flag fields; `code-complete-assertions-and-contracts` for documenting preconditions; `code-complete-interface-reviewer` to review a diff.

## Source

- `Routine Design Rules`
- `Routine Bloat`
- `Review Rules`: only the item on long parameter lists.
