---
name: "clean-architecture-solid-design"
description: "Use when judging class and interface design: fat interfaces, substitutable implementations, extension without editing stable policy, or inverting a dependency with polymorphism. A catch-all Service class is service-sprawl, interface ownership is ports-and-gateways."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# SOLID design for policy

Applies the source's paradigm rules and the five design principles to one question: does this code let volatile details change without touching stable policy. Who owns an interface and where it lives is `clean-architecture-ports-and-gateways`; a catch-all class is `clean-architecture-service-sprawl`; arrows between components are `clean-architecture-component-coupling`.

## When to use

- A new variant (another payment provider, channel, export format) forces an edit to existing policy code.
- An implementation of an interface throws "not supported" for some methods.
- A client depends on an interface and uses only a small part of it.
- A reviewer asks whether to introduce an interface or a subclass, or whether one is justified.
- Policy code branches on a type tag or on the concrete class of a collaborator.

## Rules

1. **Use structured programming to make behavior decomposable and testable.** `[MUST]` Check: a policy function is built from sequence, selection and iteration, and can be called with ordinary inputs in a test and its result observed without reaching through global state.
2. **Reach for polymorphism to invert a dependency whenever high-level policy must stay ignorant of a low-level detail.** `[MUST]` Check: the call from policy to detail goes through an interface that the policy declared, and the policy never names the implementing class.
3. **Use immutability, or mutation under control, where it shields policy from accidental coupling through shared state.** `[MUST]` The qualifier matters: use it where shared state would couple things, not everywhere. Check: state is changed only through the owning entity's methods, and collections handed out are copies or read-only views.
4. **Apply SRP: split code that changes for different actors or reasons.** `[MUST]` Check: for each class, name who would request a change; one answer per class.
5. **Apply the Open-Closed Principle: shield stable policy from the volatile parts that extend it.** `[MUST]` Check: adding a variant adds a class and a registration, and the policy's flow is not edited.
6. **Apply LSP: an implementation that stands in for another must keep what callers expect.** `[MUST]` Check: every implementation passes the same contract test; none throws "not supported" for a declared method; no caller checks the concrete type.
7. **Apply ISP: shape each interface to what its clients really use.** `[MUST]` Check: each client uses every method of the interface it depends on; if not, split by client role.
8. **Apply DIP: aim source dependencies at stable policy and abstractions.** `[MUST]` Check: constructor parameters of policy classes are interfaces declared in the policy's layer or plain data.
9. **Create an extension point only where something volatile exists.** Added judgment: OCP and polymorphism pay off against real change. With one variant and no sign of another, a plain class is cheaper, and the cost rule applies (a boundary must not cost more than the option value it keeps). Check: you can name the second variant, or the change that would bring it.
10. **Keep closed sets as plain branching.** Added judgment: a `switch` over a small set that the domain itself owns and that rarely changes (the states of a permit) is fine; polymorphism earns its place for variation that arrives from outside the domain. Check: ask who adds the next case, and how often.

## Procedure

1. List the classes and interfaces in the diff. For each class, write who would ask for a change (rule 4).
2. For each interface, list the clients and the methods each client calls (rule 7). Split an interface when clients use disjoint parts.
3. For each implementation, check the interface's contract against its behavior (rule 6). Replace "not supported" overrides by a narrower interface.
4. For each place where policy names a concrete class or switches on a type tag, decide with rule 9 or 10 whether a variation point exists; if so, introduce an interface owned by the policy.
5. Register the implementations in the composition root (`clean-architecture-composition-root`).
6. Run the tests, and add a contract test shared by all implementations of the interface.

## Example

```ts
// Before: a fat interface, an implementation that cannot honor it, and policy that knows channels
interface Notifier {
  sendEmail(to: string, body: string): Promise<void>;
  sendSms(to: string, body: string): Promise<void>;
  sendPush(deviceId: string, body: string): Promise<void>;
}

class EmailOnlyNotifier implements Notifier {
  async sendEmail(to: string, body: string): Promise<void> { /* smtp */ }
  async sendSms(): Promise<void> { throw new Error("not supported"); }   // breaks LSP
  async sendPush(): Promise<void> { throw new Error("not supported"); }  // breaks LSP
}

async function remind(n: Notifier, r: Reminder) {
  if (r.channel === "email") await n.sendEmail(r.address, r.text);
  else if (r.channel === "sms") await n.sendSms(r.address, r.text);   // edited for every new channel
  else await n.sendPush(r.address, r.text);
}
```

```ts
// After: the policy declares the small interface it needs; channels plug in.
// Reminder.channel is a plain string, so the policy holds no closed list of channels.
interface ReminderChannel {
  send(address: string, text: string): Promise<void>;
}

class SendReminders {
  constructor(private readonly channels: ReadonlyMap<string, ReminderChannel>) {}

  async execute(reminder: Reminder): Promise<void> {
    const channel = this.channels.get(reminder.channel);
    if (!channel) throw new Error(`no channel configured for ${reminder.channel}`);
    await channel.send(reminder.address, reminder.text);
  }
}

// composition root: adding WhatsApp is one new class and one entry here; neither SendReminders nor a type is edited
const channels = new Map<string, ReminderChannel>([
  ["email", new SmtpChannel(smtp)],
  ["sms", new SmsChannel(gateway)],
  ["push", new PushChannel(fcm)],
]);
const sendReminders = new SendReminders(channels);
```

Each channel implements one method and can be substituted for any other; no implementation refuses a call it advertises. The set of channels is volatile and comes from outside the domain, which is why polymorphism fits here (rule 10) and why the key is an open string rather than a closed union: a union would put a new member in the domain for every channel.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Fat interface | Clients that call a small fraction of an interface's methods | Split by client role |
| Refused bequest | An implementation that throws or returns a dummy for declared methods | Narrow the interface; do not inherit what you cannot honor |
| Policy edited per variant | A new payment type, channel or format means editing a long conditional | Introduce an interface owned by the policy |
| Type-tag branching | `instanceof`, `kind ===` or a string tag controlling policy flow for open-ended variation | Polymorphism, with the variants registered outside |
| Interface for its own sake | An interface with one implementation and no variation in sight | Remove it until a second variant is real |
| Shared mutable state | Two use cases mutating the same object graph | Make it read-only, or give it one owner |

## Trade-offs and exceptions

- The source qualifies polymorphism ("when high-level policy must not know low-level details") and immutability ("when it protects policy from accidental state coupling"). Do not apply either as a blanket rule.
- The source's cost rule beats the urge to generalize: choose abstractions by volatility, policy importance, substitution value, testability and cost (`clean-architecture-boundary-economics`).
- A language's idioms can replace a class hierarchy: function values, closures and modules fill the same role as interfaces. The principle is about the dependency direction, not the keyword.
- LSP is checked against the callers' expectations, not against the type system alone; a type-correct override can still break it.

## Verification

- [ ] Each changed class has one answer to "who asks for a change".
- [ ] Adding a variant adds code and edits no existing policy flow.
- [ ] Every implementation of an interface passes the same contract test.
- [ ] No client depends on methods it does not call.
- [ ] Policy classes depend on interfaces they own, never on a concrete detail.
- [ ] Extension points exist only where a real second variant exists.

## Related

`clean-architecture-ports-and-gateways` for ownership and naming; `clean-architecture-service-sprawl` for SRP at the class that accumulates; `clean-architecture-component-coupling` for the same ideas between components; `clean-architecture-interface-contract-reviewer` to review a diff.

## Source

- `Paradigm and Component Rules`: rules 1 to 8, the paradigm rules and SRP, OCP, LSP, ISP and DIP.
- `Architecture Economics and Priority`: only the rule against overbuilding boundaries beyond their option value.
- `Direction Violations`: only use cases depending on concrete implementations.
