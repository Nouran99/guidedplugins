---
name: "clean-architecture-framework-independence"
description: "Use when framework annotations, decorators, base classes, middleware, serializers or context objects appear in domain or use case code. Covers keeping the framework at the edge. Database and ORM markers belong to persistence-independence, imports between your own layers to dependency-rule."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Framework independence

Owns the rule that frameworks are tools at the edge, not the foundation of the design. Database and ORM markers are `clean-architecture-persistence-independence`; imports between your own layers are `clean-architecture-dependency-rule`; the types of the values crossing a signature are `clean-architecture-boundary-models`.

## When to use

- A domain class or use case carries a framework annotation, decorator, attribute or base class.
- A use case takes a session, request, context, middleware object or framework response.
- A service is registered with the framework by annotating its class.
- You are choosing where web, dependency-injection, serialization, job-runner or UI code may live.
- A framework upgrade or replacement is being estimated and nobody knows what it touches.

## Rules

1. **Treat frameworks as tools, not as the foundation of the design.** `[MUST]` Check: you can name the directories that would change if the framework were replaced, and they are all outer layers.
2. **Confine framework annotations, decorators, controllers, routes, middleware, serializers and database artifacts to the edges.** `[MUST]` Check: a search for the framework's annotation or import in domain and application code returns nothing.
3. **Do not let framework types leak into core policies.** `[MUST NOT]` Check: no signature, field or exception type in the core comes from the framework.
4. **Do not annotate domain entities with database or web framework metadata when avoidable.** `[SHOULD NOT]` Check: entity classes are plain; mapping and serialization markers live on separate adapter types.
5. **Do not let use cases depend on request, response, controller base classes, framework sessions or middleware objects.** `[MUST NOT]` Check: a use case compiles and runs in a test with no framework on the classpath.
6. **Do not let the application layer import serializer or database base classes.** `[MUST NOT]` Check: no base class from the framework appears in an `extends` or `implements` clause in the core.
7. **Prefer designs where the web framework, persistence technology, message broker, job runner, cloud vendor, serializer and UI can be replaced without rewriting business rules.** `[SHOULD]` Check: write the one-sentence answer to "what would we edit to replace X?" for each; none names a business rule.
8. **Keep framework bootstrap and wiring in the infrastructure layer.** `[MUST]` Check: the files that start the framework and configure its container are the outermost, and nothing imports them.
9. **Register core classes without annotating them.** Added judgment: in a container-driven framework, declare the use case in a configuration class or module in infrastructure (a factory method) instead of marking the class itself. Check: the use case file has no container import.
10. **Eliminate framework coupling from tests.** `[SHOULD]` Rewrite tests of business rules so they target use cases and entities directly where possible; the source's "where possible" keeps this a strong default (see `clean-architecture-testing-seams`). Check: no core test starts the framework's application context, or the exception is stated.
11. **Judge a framework by its replacement cost, not by its name.** Added judgment: the language's standard library and small pure helpers are not frameworks in this sense. Check: ask whether replacing the library would force edits in business rules.

## Procedure

1. Search the core directories for framework imports, annotations, decorators and base classes; list each hit with its file.
2. For each hit, decide whether it is structural (a marker on a core class), a type in a signature, or a call inside a body.
3. Move markers onto adapter types: a persistence record, a JSON view, a controller class. Keep the core class plain and map between them (`clean-architecture-boundary-models`).
4. Replace framework types in signatures with request and response models or plain values.
5. Move registration into the configuration of the outer layer, and remove container annotations from core classes.
6. Run the tests; then run a core test with the framework excluded from the build, if the build allows it, to prove the point.

## Example

```java
// Before: the use case is a Spring bean that takes the web session and returns a web response
@Service
public class ApplyCoupon {
    @Autowired private CouponRepository coupons;

    public ResponseEntity<String> apply(HttpSession session, String code) {
        Cart cart = (Cart) session.getAttribute("cart");
        Coupon coupon = coupons.findByCode(code);
        if (coupon == null || coupon.getExpiresOn().isBefore(LocalDate.now())) {
            return ResponseEntity.badRequest().body("expired");
        }
        cart.setDiscount(coupon.getDiscount());
        return ResponseEntity.ok("applied");
    }
}
```

```java
// After: application/ApplyCoupon.java imports no framework
public final class ApplyCoupon {
    private final CouponCatalog coupons;   // port declared in this layer

    public ApplyCoupon(CouponCatalog coupons) {
        this.coupons = coupons;
    }

    public CouponOutcome execute(Cart cart, String code, LocalDate today) {
        Optional<Coupon> coupon = coupons.find(code);
        if (coupon.isEmpty() || coupon.get().isExpiredOn(today)) {
            return CouponOutcome.rejected("expired"); // same message as before; rewording it is a separate change
        }
        return CouponOutcome.applied(cart.withDiscount(coupon.get().discount()));
    }
}

// adapters/web/CouponController.java: owns the session, the annotation and the HTTP vocabulary
@RestController
class CouponController {
    private final ApplyCoupon applyCoupon;

    CouponController(ApplyCoupon applyCoupon) {
        this.applyCoupon = applyCoupon;
    }

    @PostMapping("/cart/coupon")
    ResponseEntity<String> apply(HttpSession session, @RequestParam String code) {
        Cart cart = (Cart) session.getAttribute("cart");
        CouponOutcome outcome = applyCoupon.execute(cart, code, LocalDate.now());
        if (!outcome.isApplied()) {
            return ResponseEntity.badRequest().body(outcome.rejection());
        }
        session.setAttribute("cart", outcome.cart());
        return ResponseEntity.ok("applied");
    }
}

// infrastructure/AppConfig.java: registration happens here, not on the use case
@Configuration
class AppConfig {
    @Bean
    ApplyCoupon applyCoupon(CouponCatalog coupons) {
        return new ApplyCoupon(coupons);
    }
}
```

`CouponOutcome` is a small result type with `applied(cart)`, `rejected(reason)`, `isApplied()`, `cart()` and `rejection()`. `Cart.withDiscount` returns a new cart, so the session holds whichever cart the caller chooses to store; the old code mutated the cart in place, and the controller's `setAttribute` keeps the visible result the same. Replacing the web framework leaves `ApplyCoupon` and its tests untouched.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Annotated core | `@Service`, `@Entity`, `@Component` or decorators on domain and application classes | Move the marker to a config class or an adapter type |
| Framework in the signature | `HttpSession`, `Request`, `Context`, `ResponseEntity` in a core method | Use plain values or a model owned by the core |
| Framework base class | `extends` a framework or ORM base in the core | Composition with a port, or an adapter that extends it |
| Context test | A rule test that boots the application context | Test the use case with fakes |
| Framework exception | A core method that throws or catches a framework exception | Define a core outcome; translate in the adapter |
| Global context | Static access to a framework holder inside the core | Pass a value or port in |

## Trade-offs and exceptions

- The source says "when avoidable" for entity metadata and "where possible" for annotations in the domain. If a tool truly cannot work without a marker on a class, keep it at the outermost point you can, document the violation and keep a path to separation (`clean-architecture-boundary-economics`).
- Frameworks that dictate directory conventions (a routes folder, a controllers folder) are details. Keep those folders as the outermost adapter layer and put use cases beside them rather than inside them.
- Added judgment: when the framework is the product (building a framework plugin), framework behavior is part of the policy. Say so and limit the leak to that module.
- Do not hide the standard library behind an abstraction just to look framework-free.

## Verification

- [ ] No framework import, annotation, decorator or base class appears in domain or application files.
- [ ] No core signature or exception type belongs to the framework.
- [ ] Use cases and entities run in a test without starting the framework.
- [ ] Registration of core classes lives in the outermost configuration.
- [ ] For each replaceable framework you can name the outer files that would change, and none holds a business rule.

## Related

`clean-architecture-persistence-independence` for ORM and table markers; `clean-architecture-interface-adapters` for the controller side; `clean-architecture-composition-root` for registration; `clean-architecture-import-direction-reviewer` to review a diff.

## Source

- `Non-Negotiable Rules`: rule 3, treating frameworks as details.
- `Framework Leakage`
- `Stable Core, Replaceable Edge`
- `Infrastructure Layer`: only framework bootstrap and wiring at the outermost edge.
- `Refactoring Rules`: only the rule on eliminating framework coupling from tests.
- `Boundary Cost, Deployment, and Operations`: only the rule that boundaries must be enforceable.
- `When Tradeoffs Are Necessary`: only the handling of a compromise forced by a framework.
