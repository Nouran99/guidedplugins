---
name: "clean-architecture-boundary-models"
description: "Use when a use case, entity or core service signature takes or returns a web request, ORM row, framework context or response object, or when request and response models are designed. Controller and mapper bodies are interface-adapters; the action itself is use-cases."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Boundary models

Owns the shape of the data that crosses into and out of the core. The code that translates is `clean-architecture-interface-adapters`; the workflow inside is `clean-architecture-use-cases`; import direction is `clean-architecture-dependency-rule`.

## When to use

- A use case signature mentions `Request`, `Response`, `Context`, `Session`, `Row`, `Model` or an ORM base class.
- One class is used as the HTTP body, the use-case input and the database row.
- You are naming the fields of a new request or response model.
- A reviewer asks why a mapper exists, or whether one is needed.

## Rules

1. **Use request and response models owned by the application layer.** `[MUST]` The inner layer defines what it needs, so the outer layer cannot dictate the core's shape. Check: the model's file lives in the application or domain directory.
2. **Do not hand core logic a database-bound entity, a web request or any structure bound to a framework.** `[MUST NOT]` Check: no parameter of a use case, entity method or domain service has a type from the web, ORM or message framework.
3. **Do not return framework objects or framework response types from use cases or anywhere in the application layer.** `[MUST NOT]` Check: return types are response models, domain values or calls to an output boundary, and no response class is imported in the application directory.
4. **Pass plain data into use cases through request models or arguments.** `[MUST]` Check: the input is constructible in a unit test with no framework object.
5. **Do not return table rows or database-bound entities from a use case.** `[MUST NOT]` unless explicitly required and justified. Check: nothing returned carries a connection, lazy loader or column naming of the storage.
6. **Give a rule the value it needs as a field of the request model.** `[MUST]` A rule that needs the region, the current user or a setting gets it in the request instead of looking it up; what business rules may not read at all is `clean-architecture-entities-and-invariants`. Check: every value a rule needs appears in a request model, and the rule's parameters are plain.
7. **Translate at the edge.** `[MUST]` Controllers turn delivery input into input models; presenters or response mappers turn use-case output into the delivery format. Check: the mapping code is in the adapters layer and has no business branching.
8. **Name each model for its use case.** Added judgment: `RenewSubscriptionRequest` and `RenewSubscriptionResponse` say where they belong; `Dto`, `Payload` and `Data` do not. Check: the model name starts with the use case's verb.
9. **Carry only what the use case needs.** Added judgment, in the spirit of focused interfaces: a response with every field of the entity forces every client to know them all. Check: each field is read by at least one caller.
10. **Do not reuse one class for three jobs.** Added judgment: the same class serving as HTTP body, request model and table row couples the wire format, the core and the schema, so a column rename becomes an API break. Check: the three types can change independently.

## Procedure

1. Read the signatures of the use cases, entity methods and domain services you touch; list every parameter and return type.
2. Mark each type as plain (language types, domain types, models owned by the core) or bound (from a web, ORM, serialization or messaging library).
3. For each bound type, define the plain model with only the fields the core uses, in the core's vocabulary.
4. Write the mapper in the adapter: delivery format to request model, response model to delivery format. Keep it free of decisions.
5. Update the use case to take and return the plain models, and adjust the callers one at a time.
6. Run the tests; add a unit test that builds the request model directly.

## Example

```go
// Before: the core takes a web request and returns database rows
func QuoteShipping(r *http.Request, db *sql.DB) (*sql.Rows, error) {
	return db.Query("select zone, rate_per_kg from rates where zone = $1", r.URL.Query().Get("zone"))
}
```

```go
// After: application/quote.go owns plain models and a port
package application

import (
	"errors"
	"math"
)

var ErrUnknownZone = errors.New("unknown shipping zone")

type QuoteRequest struct {
	Zone     string
	WeightKg float64
}

type QuoteResponse struct {
	Zone  string
	Cents int64
}

type RateTable interface {
	CentsPerKg(zone string) (int64, error) // returns ErrUnknownZone when absent
}

type QuoteShipping struct{ Rates RateTable }

func (q QuoteShipping) Execute(req QuoteRequest) (QuoteResponse, error) {
	perKg, err := q.Rates.CentsPerKg(req.Zone)
	if err != nil {
		return QuoteResponse{}, err
	}
	cents := int64(math.Round(float64(perKg) * req.WeightKg))
	return QuoteResponse{Zone: req.Zone, Cents: cents}, nil
}
```

```go
// adapters/web/quote_handler.go: the only place that knows *http.Request
func (h QuoteHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	kg, err := strconv.ParseFloat(r.URL.Query().Get("kg"), 64)
	if err != nil {
		http.Error(w, "kg must be a number", http.StatusBadRequest)
		return
	}
	res, err := h.UseCase.Execute(application.QuoteRequest{Zone: r.URL.Query().Get("zone"), WeightKg: kg})
	if errors.Is(err, application.ErrUnknownZone) {
		http.Error(w, "unknown zone", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"zone": res.Zone, "cents": res.Cents})
}
```

The core can now be tested by calling `Execute` with a struct and a fake `RateTable`. A database adapter implements `RateTable` and is the only code that sees rows.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Request pass-through | A framework request type in a service signature | Define a request model; map in the controller |
| Row leakage | A use case that returns result sets, record objects or ORM entities | Return a response model built from domain values |
| One class, three jobs | The same class annotated for JSON, ORM and used as input | Split into wire, core and storage types |
| Untyped bag | `Map<String, Object>` or a loose dictionary crossing the seam | Name the fields in a model |
| Mapper with rules | A mapper that branches on business meaning | Move the branch into an entity or use case |
| Response bloat | A response containing every entity field | Reduce to what callers read |

## Trade-offs and exceptions

- The source asks for input and output models "if needed". For a one-value input, an argument is fine; do not create a class for a single string.
- Returning a pure domain value (a small immutable value type) is not framework leakage; the rule targets framework-bound and storage-bound objects.
- Mapping costs code. When a model and an external format are identical today, the mapping may be thin, but keep the types distinct so that the format can change without touching the core. Weigh the cost with `clean-architecture-boundary-economics` in hot paths.
- Streaming or very large results may need a dedicated output boundary instead of one response object; keep that interface owned by the inner layer.

## Verification

- [ ] No core signature mentions a web, ORM, serialization or messaging type.
- [ ] Request and response models live in the application or domain directory.
- [ ] Mapping code sits in an adapter and contains no business decisions.
- [ ] The use case can be called in a test by constructing the request model directly.
- [ ] No use case returns rows, database-bound entities or framework responses.
- [ ] The wire format, the model and the table can change independently.

## Related

`clean-architecture-interface-adapters` for the translating code; `clean-architecture-use-cases` for the action; `clean-architecture-framework-independence` for framework markers; `clean-architecture-boundary-model-reviewer` to review a diff.

## Source

- `Use Plain Models at Boundaries`
- `Database Leakage`: only use cases returning table rows or database-bound entities.
- `Framework Leakage`: only use cases depending on request, response, session or middleware objects.
- `Application Layer`: only the rule against returning framework response types.
- `Non-Negotiable Rules`: rules 2 and 5, plain data into use cases and translation by controllers and presenters.
- `Preferred use case shape`
- `Output Expectations`: only the point that input and output models are produced if needed.
