---
name: trust-boundaries
description: "Use when code takes input from users, files, networks, other services or callers you do not control: decide what is validated, rejected, recovered, logged. Internal assumptions: /code-complete:assertions-and-contracts. How a failure travels: /code-complete:error-handling."
---

# Trust boundaries

Decides, for every place where data enters code you do not fully control, what is checked, what is refused, what is repaired and what is recorded. The assumptions your own routines make about each other are `/code-complete:assertions-and-contracts`; how a failure travels afterwards is `/code-complete:error-handling`.

## When to use

- A handler, command, consumer, importer or public library function takes data from outside the process or the team.
- Code reads a file, environment variable, configuration, queue message or another service's response.
- A function trusts a caller to pass valid input and nothing checks it.
- A change adds a field, parameter or endpoint, or loosens an existing check.

## Rules

1. **Validate inputs at trust boundaries.** Why: this is where invalid data can be stopped cheaply. Check: every input that crosses a user, file, network, external-system or untrusted-caller boundary is checked at the point of entry, not deep inside.
2. **Compact rule: for each input, decide what is validated, rejected, recovered from, asserted and kept diagnosable.** Check: you can fill all five for the input in one line each (see the Procedure).
3. **Do not assume all callers are correct.** Source anti-pattern. Check: a public routine or API does not rely on a comment that says "callers must pass a valid id"; it checks, or its parameter type makes invalid values unrepresentable (`/code-complete:data-types`).
4. **Do not bury invalid state until it causes a distant failure.** Source anti-pattern. Check: a bad value is refused where it arrives, not three layers later as a null dereference.
5. **Fail in a way that preserves diagnosability.** Check: a rejection names the field, the rule and the offending value class (without secrets or full payloads), so the sender can fix it.
6. **Distinguish recoverable conditions from programming errors.** Check: bad external input is an expected condition to reject or repair; a violated internal assumption is a defect (`/code-complete:assertions-and-contracts`).
7. **Recover only when there is a defined, safe default and the caller learns what was substituted.** Added judgment. Check: no input is silently coerced to something plausible.
8. **Check more than the type.** Added judgment: presence, type, range, length, format, encoding, units and cross-field consistency are separate checks; a value of the right type can still be invalid.
9. **Accept what is known good rather than reject what is known bad.** Added judgment: an allow-list (enum members, character classes, ranges) fails closed; a deny-list misses what you did not think of.
10. **Convert once at the boundary.** Added judgment: parse the raw input into a validated, typed value at entry and pass that inward, so interior code does not re-validate raw strings.
11. **Test the defensive checks.** Check: each validation rule has a test with an input that violates it (`/code-complete:routine-testing`).
12. Added judgment: validation is not authorization, escaping or sanitization for a particular output context; those are separate controls that this skill does not cover.

## Procedure

1. Find the entry points in the change: handlers, parsers, readers, consumers, public functions.
2. For each input, fill the five-part decision.

```text
input:        qty (query parameter)
validated:    integer, 1..MAX_QUANTITY_PER_LINE
rejected:     non-integer, out of range -> 400 with field and rule
recovered:    none (no safe default)
asserted:     inside CartLine: quantity > 0 (programmer assumption after parsing)
diagnosable:  response names the rule; log has request id, no payload
```

3. Put the checks in one parsing step that returns a typed value or a rejection.
4. Replace deep checks of raw values with the typed value.
5. Write a rejecting test per rule.

## Example

```go
// Before: errors ignored, the quantity can be 0, negative or huge by the time the cart sees it
func handleSetQty(w http.ResponseWriter, r *http.Request) {
    qty, _ := strconv.Atoi(r.FormValue("qty"))
    cart.SetQuantity(r.FormValue("sku"), qty)
}

// After: one parsing step at the boundary returns a typed value or a diagnosable rejection
const maxQuantityPerLine = 99

type quantityRequest struct {
    SKU string
    Qty int
}

func parseQuantityRequest(r *http.Request) (quantityRequest, error) {
    sku := strings.TrimSpace(r.FormValue("sku"))
    if sku == "" {
        return quantityRequest{}, errors.New("sku is required")
    }
    qty, err := strconv.Atoi(r.FormValue("qty"))
    if err != nil {
        return quantityRequest{}, fmt.Errorf("qty must be an integer: %w", err)
    }
    if qty < 1 || qty > maxQuantityPerLine {
        return quantityRequest{}, fmt.Errorf("qty must be between 1 and %d, got %d", maxQuantityPerLine, qty)
    }
    return quantityRequest{SKU: sku, Qty: qty}, nil
}

func handleSetQty(w http.ResponseWriter, r *http.Request) {
    req, err := parseQuantityRequest(r)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    cart.SetQuantity(req.SKU, req.Qty)
}
```

## Anti-patterns

- **Trusting caller.** "Callers guarantee the id exists." Detect: a public routine with no check and a comment where the check should be.
- **Late failure.** Invalid data travels inward and fails far from the source. Detect: a stack trace whose top frame is unrelated to the input.
- **Swallowed parse error.** `qty, _ := Atoi(...)`. Detect: a discarded error or exception from parsing or I/O.
- **Silent coercion.** Unknown values become a default. Detect: `getOrDefault` on external data with no log or signal.
- **Check in the wrong place.** Validation repeated in every consumer, or only in the user interface. Detect: the same input is checked in several layers but not in the one the data enters.
- **Opaque rejection.** `400 invalid request` with no field. Detect: an error message that cannot be acted on.

## Trade-offs and exceptions

- Not every boundary needs every response. A trusted, internal, strongly typed call may only need an assertion; the five-part decision exists to make that choice explicit, not to add checks everywhere.
- Validating twice at two boundaries (a public API and the service behind it) is correct when each is reachable by a different caller; it is waste when one calls the other with already-typed values.
- The source asks to validate at boundaries and to keep error handling out of the normal path; a thin parsing function satisfies both.
- Error messages must not leak secrets, credentials or personal data. Trim context accordingly.

## Verification

- [ ] Every input crossing a boundary in the change has a validation, or a stated reason it needs none.
- [ ] Rejections name the rule and the field and contain no secrets.
- [ ] No parse or I/O error is discarded.
- [ ] Interior code receives a validated, typed value, not the raw input.
- [ ] Each validation rule has a test with a violating input.

## Related

`/code-complete:assertions-and-contracts` for assumptions inside the code; `/code-complete:error-handling` for how a rejection travels; `/code-complete:data-types` for making invalid values unrepresentable; `/code-complete:trust-boundary-scan` to inventory a tree; `code-complete:trust-boundary-reviewer` to review a diff; `code-complete:boundary-hardener` to add the missing checks.

## Source

- `Defensive Programming Rules`
- `Error Handling Rules`: only the rule not to let error handling dominate the normal path.
- `Defensive Vacuum`
- `Testing Rules`: only the rule to test defensive checks where boundary validation matters.
