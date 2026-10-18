---
name: "enterprise-patterns-presentation-layer"
description: "Use when writing or reviewing what sits inside handlers, controllers, views, templates or presentation models: business rules, SQL or transactions in them, display formatting in domain code, one type as form, entity and response. Imports are layering; pattern choice is web-presentation-patterns."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Presentation layer

Decides what presentation code may own and what it must hand to other layers. Which controller or view pattern to use is `enterprise-patterns-web-presentation-patterns`; the full set of cross-layer rules is `enterprise-patterns-layering`; where per-user state is kept is `enterprise-patterns-session-state`.

## When to use

- A handler, controller action, view or template contains a conditional about business state (eligibility, pricing, status transitions).
- A handler loads data, opens transactions, calls other systems and builds the response.
- A domain or service method receives a request object, a page number or a locale and returns display strings.
- One class is used as database row, domain entity, request body and response body.
- A template computes totals, discounts or permissions.

## Rules

1. **Let presentation code handle input, rendering and transport concerns.** Everything else belongs to a layer that can be reused and tested without the web stack. Check: a handler's body is input handling, calls into the application layer and output shaping, with no rules, SQL or transaction control. Added judgment: one application operation per handler is the usual shape, and a handler that sequences several collaborators is the cue to extract an operation (rule 6).
2. **Do not put business rules in controllers or views.** Templates, handlers and presentation models carry no eligibility, pricing or state-transition logic. A rule in a handler is invisible to every other entry point. Check: search handlers and templates for conditionals on business concepts.
3. **Allow presentation models to differ from domain models.** The source phrases this as a permission ("may differ"), so it frees you to shape pages and responses independently; it does not require a separate type for every screen. It matters when leakage is the problem: UI changes forcing domain changes, or the reverse. Check: rename or retype a domain field and see whether any page or wire format changes silently; if one does, give that response or form its own type with explicit mapping (Added judgment on the fix). Where the shapes genuinely coincide and the coupling is accepted, leave them shared.
4. **Keep formatting, pagination and UI interaction state outside domain logic.** Domain code must be able to serve more than one UI. Check: domain classes know nothing about locales, currency symbols, page numbers, selected tabs or wizard steps.
5. **Keep routing concerns out of business logic.** Routes change for reasons unrelated to business rules. Check: URLs, HTTP verbs and route parameters are not visible below the presentation layer.
6. **Do not make the handler the coordinator of the enterprise workflow.** The source lists request handlers coordinating transactions, SQL, domain rules and external calls as a forbidden pattern (controller-centric design). A handler that coordinates everything cannot be reused and is hard to test. Check: no connection handle, `begin` or `commit`, SQL, outbound call or rule inside a handler.
7. **Do not let controllers reach into SQL and transaction details.** SQL and transaction code in controllers couples delivery to storage. Check: no data-access import in the presentation layer, other than the application services it calls.
8. **Treat input shape validation as presentation, business validation as domain.** Added judgment: "is this a number, is it present" belongs with input handling; "may this customer order this" belongs with the model. Shape errors and business errors are handled in different places.
9. **Translate domain failures into transport outcomes in one place.** Added judgment: map named domain errors to status codes or messages in the presentation layer, so the domain never mentions transport. The domain stays free of transport vocabulary.

## Procedure

1. Read the handler or template and mark each line: input, call, rule, formatting, output.
2. Move every rule line to the owner (`enterprise-patterns-business-logic-patterns`); move coordination to an application operation (`enterprise-patterns-service-layer`).
3. Leave behind only input handling, the call into the application layer and output shaping.
4. Where the response shape differs from the application result, or a domain change would alter it silently, give the response its own type and map to it from the application result.
5. Move formatting helpers to presentation; pass raw values (cents, dates) upward from the application layer.
6. Run the tests after each move; add a test of the moved rule at its new home.

## Example

```ts
// Before: the handler decides a business rule and formats money
app.get("/cart", async (req, res) => {
  const cart = await carts.get(req.session.cartId);
  const orderCount = await orders.countFor(req.session.userId);
  const freeShipping = orderCount > 10 && cart.totalCents > 10_000;     // business rule in the handler
  res.render("cart", { items: cart.items, total: `$${(cart.totalCents / 100).toFixed(2)}`, freeShipping });
});

// After: the rule is a domain function, the application operation returns raw values,
// and the handler only shapes the page
export function qualifiesForFreeShipping(previousOrders: number, cartTotalCents: number): boolean {
  return previousOrders > 10 && cartTotalCents > 10_000;
}

class ViewCart {
  constructor(private carts: CartRepository, private orders: OrderHistory) {}
  async execute(userId: string, cartId: string) {
    const cart = await this.carts.get(cartId);
    const previous = await this.orders.countFor(userId);
    return { items: cart.items, totalCents: cart.totalCents,
             freeShipping: qualifiesForFreeShipping(previous, cart.totalCents) };
  }
}

app.get("/cart", async (req, res) => {
  const cart = await viewCart.execute(req.session.userId, req.session.cartId);
  res.render("cart", { items: cart.items, total: formatMoney(cart.totalCents), freeShipping: cart.freeShipping });
});
```

The thresholds (10 orders, 100 dollars) are the example's invented business numbers; the point is where the rule lives. A job that emails the same offer now calls `qualifiesForFreeShipping` instead of copying the condition.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Rule in the template | Conditionals on roles, amounts or status in view code | Compute in the domain; pass a flag or value |
| Fat handler | SQL, `commit`, rule checks and outbound calls in one function | Application operation plus domain methods |
| One type for every layer | Same class bound to the form, the table and the JSON, so a column or domain change alters a page or wire format | Separate types and explicit mapping where the leak occurs |
| Display in the domain | Domain methods returning formatted strings | Return raw values; format in presentation |
| Transport in the domain | Domain throws HTTP errors or reads cookies | Domain errors; translate in presentation |

## Trade-offs and exceptions

- Trivial CRUD screens may have a handler that parses a form and calls a one-line service; that is the shape the rules describe, not a violation.
- Presentation-only conditionals (show the error box when there are errors, hide a section) are presentation logic and stay.
- Some frameworks bind request data to entity classes; where you accept that, keep rules out of the bound class and map before domain logic runs.
- Because presentation models only "may" differ, a form or response type that mirrors a domain type is not a finding on its own. It becomes one when a change on one side silently changes the other, or when the shared type is the persistence model doubling as aggregate and service (the forbidden pattern named in `enterprise-patterns-data-mapper`).
- Authorization is placed where the project already puts it; the source does not prescribe a layer for it.

## Verification

- [ ] Handlers contain input handling, calls into the application layer (one operation is the usual shape) and output shaping.
- [ ] No template or view contains a business rule.
- [ ] No domain or schema change silently alters a page or response shape; where one could, the response has its own type and an explicit mapping.
- [ ] Domain and application code mention no locale, page number, route or HTTP type.
- [ ] No SQL or transaction control appears in presentation code.
- [ ] The moved rules have tests at their new home.

## Related

`enterprise-patterns-web-presentation-patterns` for pattern choice; `enterprise-patterns-service-layer` for the application call; `enterprise-patterns-layering` for the import rules; `enterprise-patterns-presentation-reviewer` to review a diff; `enterprise-patterns-logic-mover` to move rules out.

## Source

- `Presentation Layer Rules`
- `Controller-Centric Enterprise App`
- `ORM-Driven Everything`: only the collapse of several roles into one persistence model, cited for the one-type-for-every-layer anti-pattern and its trade-off line.
- `Layering`: only the rules against SQL and transaction details in controllers and domain logic in views or handlers.
- `Review Rules`: only the findings about domain logic in controllers or views.
