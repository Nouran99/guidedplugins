---
name: web-presentation-patterns
description: "Use when choosing how requests are handled and responses rendered: Page Controller or Front Controller, Template View, Transform View or Two Step View, MVC roles, or a multi-step flow whose navigation is scattered. What handlers may contain is presentation-layer."
---

# Web presentation patterns

Chooses the request-handling and rendering patterns: Model View Controller, Page Controller, Front Controller, Template View, Transform View, Two Step View and Application Controller. What the resulting handlers and views may contain is `/enterprise-patterns:presentation-layer`.

## When to use

- A new web application, section or API needs a structure for request handling and responses.
- Authentication, logging, locale or error handling is copied into every handler.
- Every page repeats the same header, footer and navigation, or a theme must change them in one place.
- The same data must be rendered as HTML, CSV and XML.
- A wizard or multi-step flow decides the next page in many handlers and templates.

## Rules

1. **Use Model View Controller to separate domain model, view and controller responsibilities.** Mixed roles make every change touch every role. Check: the view does not change the model, the controller does not produce markup, the model does not know the view.
2. **Choose Page Controller or Front Controller pragmatically, and keep routing concerns out of business logic.** The decision is about cost in your setting, not purity, and routing inside business logic couples rules to URLs. Check: the reason is one line in the design (for example "the framework router already centralizes dispatch").
3. **Use Page Controller when each page or action can be handled independently.** Independent pages do not need a shared dispatcher. Check: handlers need little shared preprocessing, and each one maps to one page or action.
4. **Use Front Controller when centralized request handling, authentication, routing or dispatch is valuable.** Copying shared steps into each handler guarantees one will be forgotten. Check: cross-cutting request steps exist once in the entry point or middleware chain, not in each handler.
5. **Use Template View when server-side templates clearly express the response.** Templates are the clearest expression of mostly fixed output. Check: templates are mostly the output's markup with display-only logic.
6. **Use Transform View when transforming data into output is clearer than embedding logic in templates.** A function over data is easier to test than logic scattered through markup. Check: the output is produced by a function over data (one per output format), and nobody patches the result with string edits.
7. **Use Two Step View when shared presentation structure should be separated from page-specific content.** Changing layout or theme should not mean editing every page. Check: pages produce logical content once, and layout, navigation and theme are rendered by a single second step.
8. **Use Application Controller when flow and navigation decisions need a dedicated coordinator.** Navigation rules spread over handlers and templates cannot be seen or changed in one place. Check: the next-step rules for a flow live in one place, not in every handler and template.
9. **Keep business rules out of whichever pattern you choose.** The presentation rules apply to controllers, templates and transforms alike (see `/enterprise-patterns:presentation-layer`). Moving a rule into a template does not change who should own it.
10. **Do not stack a second pattern on one the framework already provides.** Added judgment: a framework router with middleware is already a Front Controller, and its component or template system already is a Template View; add your own only for a gap you can name.

## Procedure

1. List what must be shared across requests (authentication, locale, error shape) and what is per page.
2. Pick Front Controller for the shared part when it exists; keep page logic in Page Controllers behind it.
3. Pick the view pattern from the output needs: Template View for one HTML output, Transform View for several data-driven formats, Two Step View when a shared layout must be controlled centrally.
4. If a flow has branching next steps, define the Application Controller as a small object that maps (current step, state) to next step.
5. Make sure no pattern holds business rules; run `/enterprise-patterns:presentation-layer` over the result.
6. Test the flow object and the transformations directly, without a web server.

## Example

```ts
// Before: every handler and template decides what comes next
app.post("/checkout/address", (req, res) => {
  if (req.session.cart.requiresShipping) res.redirect("/checkout/shipping");
  else res.redirect("/checkout/payment");
});
app.post("/checkout/shipping", (req, res) => res.redirect("/checkout/payment"));
app.post("/checkout/payment", (req, res) => res.redirect("/checkout/review"));

// After: an Application Controller owns the navigation rules; handlers only ask it
type Step = "address" | "shipping" | "payment" | "review";

class CheckoutFlow {
  next(current: Step, cart: { requiresShipping: boolean }): Step {
    switch (current) {
      case "address":  return cart.requiresShipping ? "shipping" : "payment";
      case "shipping": return "payment";
      case "payment":  return "review";
      case "review":   return "review";
    }
  }
}

const flow = new CheckoutFlow();
app.post("/checkout/:step", (req, res) => {
  const next = flow.next(req.params.step as Step, req.session.cart);
  res.redirect(`/checkout/${next}`);
});
```

Whether the cart `requiresShipping` is decided by the domain; the flow object only decides navigation. Adding a "gift options" step now changes one `switch`, and the flow can be tested with plain function calls.

### Selection table

| Situation | Pattern |
| --- | --- |
| Pages handled independently, little shared preprocessing | Page Controller |
| Authentication, routing, dispatch must be uniform | Front Controller |
| HTML pages whose markup is the response | Template View |
| Same data to HTML, CSV or XML; output is a function of data | Transform View |
| Shared layout and navigation changed in one place | Two Step View |
| Wizard or branching flow | Application Controller |
| Splitting responsibilities of UI interaction as a whole | Model View Controller |

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Copied preprocessing | Auth and logging repeated at the top of handlers | Front Controller or middleware |
| Logic-heavy templates | Loops and conditionals about business state in markup | Move to the domain; pass results |
| Scattered flow | `redirect` decisions in many handlers | Application Controller |
| Duplicate layout | Header and footer pasted into each page | Two Step View |
| Pattern on pattern | Custom dispatcher beside the framework's router | Use the framework's |

## Trade-offs and exceptions

- The source says to choose Page Controller or Front Controller pragmatically; neither is wrong in itself.
- Small applications often need only Page Controller and Template View. Adding Two Step View or Application Controller without the force that calls for them is the fashionable complexity the book rejects.
- API-only services have no Template View; the equivalent decision is how responses are produced from data, which Transform View describes.
- Front-end single-page application architecture is outside this rule set; apply the principle (no business rules in the presentation tier) rather than the patterns.

## Verification

- [ ] The controller pattern and view pattern are named with the force that chose each.
- [ ] Cross-cutting request steps exist once.
- [ ] Navigation rules for flows live in one place.
- [ ] No business rule appears in any controller, template or transform.
- [ ] The flow object and transformations have direct tests.
- [ ] No duplicate of a framework-provided pattern was added.

## Related

`/enterprise-patterns:presentation-layer` for allowed content; `/enterprise-patterns:session-state` for flow state storage; `/enterprise-patterns:service-layer` for what handlers call; `enterprise-patterns:presentation-reviewer` to review a diff.

## Source

- `Presentation Pattern Index`
- `Presentation Layer Rules`: only the instruction to choose Page Controller or Front Controller pragmatically and keep routing out of business logic.
- `Final Instruction`: only the instruction to choose the smallest set of patterns.
