---
name: system-construction
description: "Use when business code creates its own collaborators, reads global configuration, wires dependencies mid-flow, or is cluttered by logging, transactions or retries. Separates building a system from using it and keeps wiring in one place."
---

# System construction

Decides where objects are created and wired, and how cross-cutting concerns are kept out of ordinary flow. Which vendor types the core may see is `/clean-code:boundaries`; how big a class is is `/clean-code:class-design`.

## When to use

- A method calls `new` on a service, opens a connection or reads an environment variable in the middle of business logic.
- Lazy initialization (`if (x == null) x = new X()`) appears inside methods.
- A class cannot be used in a test without a database, a framework container or global state.
- Logging, authorization, transactions or caching are interleaved with the steps of a business operation.
- A startup file is also where business decisions are made.

## Rules

1. **Separate constructing a system from using it.** Building objects and running them are different concerns with different reasons to change. Check: the code that decides what to build is not the code that runs the business rule.
2. **Keep object graph assembly, dependency injection, factories and framework bootstrapping out of ordinary business behavior.** Check: business classes receive collaborators; they do not look them up or create them.
3. **Put startup wiring in an explicit main or composition area.** One place shows how the pieces fit. Check: you can open one file and see the whole object graph for the application, or for a module.
4. **Use factories when construction policy is meaningful or complex.** When what to build depends on a rule, name the factory for the rule. Check: the rule appears in exactly one place, not in each caller.
5. **Do not let cross-cutting concerns obscure ordinary code flow.** Logging, authorization, transactions and retry policy should not bury the steps of the business operation. Check: the business function reads without them, or they are applied in one visible place around it.
6. **Use standards, frameworks, proxies or AOP-style mechanisms only when they add demonstrable value.** Check: you can name the lines of code or the bugs the mechanism removes; if you cannot, plain code is cheaper.
7. **Test-drive architectural decisions with executable slices, not only diagrams or configuration.** Added judgment: a thin end-to-end path that runs and is tested teaches more than a diagram. Check: the decision is exercised by a running test, not only documented.
8. **Use domain-specific languages only when they make system intent clearer than general-purpose code.** Check: a domain expert can read the DSL, and its parser does not become a project of its own.
9. **Avoid hidden construction.** Lazy initialization and static access in business methods make dependencies invisible. Added judgment: where lazy creation is needed for cost, put it behind the factory or provider, not in the business method. Check: no business method contains a construction expression for a service-like object.

## Procedure

1. Search the touched business code for construction of collaborators (`new`, factory calls, `getInstance`, container lookups, environment reads).
2. For each, decide whether it is a value (fine to create inline) or a collaborator (should be passed in).
3. Change the constructor or function parameters to receive the collaborator. Keep the previous behavior at the single call site that wires it.
4. Move the wiring to the composition area. If no such area exists, create the smallest one; do not introduce a container library unless it clearly removes more than it adds.
5. For cross-cutting concerns, move them to the boundary of the operation (a wrapper, decorator or middleware the project already uses).
6. Run the tests, then add a test that builds the class with a simple fake.

## Example

```ts
// Before: the service builds and configures its own mailer inside the business method
class ReminderService {
  sendOverdueNotice(loan: Loan): void {
    const mailer = new SmtpMailer(process.env.SMTP_HOST!, Number(process.env.SMTP_PORT));
    console.info(`sending notice for ${loan.id}`);
    mailer.send(loan.member.email, "Overdue", renderNotice(loan));
    console.info(`sent notice for ${loan.id}`);
  }
}

// After: construction at the edge, behavior only in the service
class ReminderService {
  constructor(private readonly mailer: Mailer) {}

  sendOverdueNotice(loan: Loan): void {
    this.mailer.send(loan.member.email, "Overdue", renderNotice(loan));
  }
}

// composition area (main.ts)
export function buildApp(env: NodeJS.ProcessEnv): Application {
  const mailer = new LoggingMailer(new SmtpMailer(env.SMTP_HOST!, Number(env.SMTP_PORT)));
  return new Application({ reminders: new ReminderService(mailer) });
}
```

`LoggingMailer` wraps the real mailer so the log lines live in one place, and `ReminderService` can be tested with a list-backed fake.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Construction inside use | `new Service(...)` or factory call in a business method | Constructor or parameter injection |
| Hidden lazy init | `if (instance == null)` in methods that do real work | Provider or factory at the wiring layer |
| Global lookup | Singletons or static registries called from business code | Pass dependencies explicitly |
| Configuration in logic | Environment or config reads mid-function | Read once at startup; pass values in |
| Bootstrapping with rules | Startup code deciding business behavior | Move the rule to a factory with a name |
| Cross-cutting clutter | More log, auth or transaction lines than business lines | Decorator, wrapper or middleware at one place |
| Container-for-its-own-sake | A wiring framework used for three objects | Plain constructors in `main` |

## Trade-offs and exceptions

- Creating small values and local helper objects inline is fine; the rule concerns collaborators and services.
- A framework may impose its own wiring style; follow it, but keep business classes free of framework lookups where you can.
- AOP, proxies and annotations can hide control flow; the rule is to justify them, not to ban them.
- A small program can have a short `main` with direct construction; formal composition structures are for programs that need them.
- Do not introduce a dependency injection library to satisfy this skill unless it removes more code than it adds.

## Verification

- [ ] No touched business method constructs a service-like collaborator.
- [ ] The wiring is visible in one place and the touched class is built there.
- [ ] The class can be constructed in a test with fakes, without environment or container.
- [ ] Cross-cutting concerns do not interleave with the business steps.
- [ ] Any framework or DSL used has a stated benefit.

## Related

`/clean-code:boundaries` for vendor types; `/clean-code:class-design` for constructors; `/clean-code:emergent-design` for avoiding needless infrastructure; `clean-code:construction-reviewer` to review a diff.

## Source

- `System construction rules`
