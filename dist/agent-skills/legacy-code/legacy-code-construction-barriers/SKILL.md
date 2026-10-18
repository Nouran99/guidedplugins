---
name: "legacy-code-construction-barriers"
description: "Use when a class cannot be instantiated cheaply in a test: constructors that do real work, collaborators created inside methods, factory calls buried in behavior, graphs built mid-logic. Static access is `legacy-code-static-and-global`; parameters and interfaces are `legacy-code-substitution-seams`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Construction barriers

The first thing a test does is build the object. When building it connects to something, reads configuration or allocates half a system, the test never gets to the behavior. This skill splits construction from use. How methods receive types and parameters is `legacy-code-substitution-seams`; static and global access paths are `legacy-code-static-and-global`; the caution that applies to every subclass-based seam is in `legacy-code-last-resort-seams`.

## When to use

- `new Thing()` in a test connects, reads a file or needs an environment variable.
- A method creates its own collaborator with `new` and you cannot replace it.
- A factory call is hidden several levels down in behavior.
- An object graph is assembled in the middle of business logic.
- Useful logic sits in an instance method that never touches instance state but cannot be reached without the constructor.

## Rules

1. **When legacy code is hard to test, look for construction problems: constructors that do real work, complex collaborators allocated inside methods, factory calls hidden deep in behavior, and object graphs built in the middle of logic.** [MUST] Check: you listed each construction site in the code under test and what it needs.
2. **Split construction from use.** [MUST] Check: the class that decides things receives its collaborators; some other code builds them.
3. **Stop doing I/O, network or configuration lookup in constructors.** [MUST] Check: constructing the class in a test touches no file, socket, environment variable or database.
4. **Move setup into factories, builders or composition roots.** [MUST] Check: there is a single place where production wiring happens, and the class does not know about it.
5. **Keep constructed objects easy to instantiate under test.** [MUST] Check: a test builds the object in one or two lines.
6. **Reduce constructor side effects and static initialization side effects.** [MUST] Check: loading and constructing the class has no observable effect beyond holding state.
7. **Make dependencies explicit and remove hard-coded collaborators.** [MUST] Check: each collaborator the class uses appears as a parameter, a field set from a parameter, or a created value you can name.
8. **Use Parameterize Constructor when hidden collaborators should become explicit inputs.** [SHOULD] Add a constructor that takes the collaborator. Check: tests use the new constructor, and the old constructor, if kept, delegates with the same collaborator it built before.
9. **Use Extract and Override Factory Method when construction of a hard dependency must vary under test.** [SHOULD] This creates a subclass seam; apply the cautions in `legacy-code-last-resort-seams`. Added judgment: the constructor calling the factory method is the intended use in Java and C#, where the test override must return a fresh object and read no subclass fields; in C++ the base version runs from a constructor, so use another seam there. Check: the factory method exists only where a parameter is not possible.
10. **Use Supersede Instance Variable when a test needs to replace a hard dependency held in a field.** [SHOULD] Added judgment: the replacing setter is a test-only door, so give it a cleanup obligation and prefer Parameterize Constructor when you can edit the constructor. Check: the setter has a comment naming its exit.
11. **Use Expose Static Method when useful logic does not need instance state but is trapped behind instance setup.** [SHOULD] Check: the logic can be called with plain arguments and no instance; the instance method now delegates to it.
12. **Do not embed new hard dependencies in the same style as the legacy code.** [MUST NOT] Check: new code receives its collaborators; it does not create them in the legacy style.
13. **Keep the old constructor as a delegating overload while callers migrate.** [Added judgment] Existing call sites keep compiling and behaving the same. Check: no legacy call site changed in the same step.
14. **Prefer the option that puts the dependency in a signature.** [Added judgment] Among rules 8 to 11, a constructor parameter shows the dependency to every reader; a factory method hides it in a subclass; a setter hides it in a test. Check: if you did not pick a parameter, the plan says why.

## Procedure

1. Try to build the object in a test. Write down what fails or what it connects to.
2. For each hidden collaborator, choose the technique from rules 8 to 11.
3. Define the narrowest type the code uses for the collaborator (`legacy-code-substitution-seams` if it is concrete and large).
4. Add the new constructor (or factory method), keep the old entry point delegating, and run the tests. If the constructor is what stops every pin, this is the enabling step: keep it mechanical, rely on the compiler or type checker, and pin straight after.
5. Move the real construction toward the composition root in a separate step, once a test depends on the new shape.
6. Report which construction sites you left alone.

## Example

```java
// Before: the constructor connects to a mail server
public class ReceiptMailer {
    private final SmtpClient smtp;

    public ReceiptMailer() {
        this.smtp = new SmtpClient(System.getenv("SMTP_HOST"), 25);
        this.smtp.connect();
    }

    public void sendReceipt(Order order) {
        smtp.send(order.customerEmail(), "Receipt " + order.id(), render(order));
    }
}
```

```java
// After: Parameterize Constructor; the no-argument constructor behaves as before
public interface MailTransport {
    void send(String to, String subject, String body);
}

public class ReceiptMailer {
    private final MailTransport transport;

    public ReceiptMailer() {
        this(connectedSmtp());
    }

    public ReceiptMailer(MailTransport transport) {
        this.transport = transport;
    }

    private static MailTransport connectedSmtp() {
        SmtpClient smtp = new SmtpClient(System.getenv("SMTP_HOST"), 25);
        smtp.connect();
        return smtp::send; // SmtpClient.send(String, String, String)
    }

    public void sendReceipt(Order order) {
        transport.send(order.customerEmail(), "Receipt " + order.id(), render(order));
    }
}
```

```java
class RecordingTransport implements MailTransport {
    final List<String> sent = new ArrayList<>();
    public void send(String to, String subject, String body) { sent.add(to + "|" + subject); }
}

@Test
void receiptGoesToTheCustomer() {
    RecordingTransport transport = new RecordingTransport();
    new ReceiptMailer(transport).sendReceipt(orderFor("ana@example.com", "A-17"));
    assertEquals(List.of("ana@example.com|Receipt A-17"), transport.sent);
}
```

Step two, as its own change: move the `connectedSmtp()` call to the composition root and delete the no-argument constructor once no caller uses it.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Working constructor | Sockets, files, environment reads in a constructor | Parameterize; move setup out |
| Buried allocation | `new` of a service inside a method body | Parameterize Method or constructor |
| Factory deep in behavior | A static factory call several frames down | Pass the product in, or extract a factory method |
| Graph in logic | Objects wired in the middle of a rule | Build at the composition root |
| Setter forever | A `setX` used only by tests, no exit noted | Prefer the constructor; add the cleanup note |
| Edited legacy callers | Existing call sites changed in the same step | Keep the delegating overload |

## Trade-offs and exceptions

- The source asks for the smallest seam: when a method needs the collaborator only once, Parameterize Method (`legacy-code-substitution-seams`) can be smaller than a new constructor.
- Where the language or framework forces construction through a container, keep the container's entry point and parameterize behind it.
- Added judgment: if the class is built in hundreds of places, keep the old constructor for a long time and migrate callers by area.

## Verification

- [ ] A test builds the object without touching I/O, the network or the environment.
- [ ] Each collaborator is visible in a signature or wiring module.
- [ ] Old constructors still behave as before.
- [ ] Test-only doors (setters, factory overrides) have cleanup notes.
- [ ] No new hard-coded collaborator was added.
- [ ] Tests ran before and after.

## Related

`legacy-code-construction-reviewer` to review a diff; `legacy-code-collaborator-injector` to make the change; `legacy-code-substitution-seams` for interfaces and parameters; `legacy-code-static-and-global` for static access; `legacy-code-last-resort-seams` for subclass seams.

## Source

- `Construction Problems`
- `Constructors Doing Too Much`
- `Testability Improvements`
- `Dependency-Breaking Technique Index`: only Expose Static Method, Extract and Override Factory Method, Parameterize Constructor and Supersede Instance Variable.
- `Required Moves`: only the rule to split construction from use.
- `Hidden Dependency Expansion`: only the rule not to embed new hard dependencies in the legacy style.
- `Code Generation Rules`: only the preferred first moves of injecting a collaborator and splitting construction from behavior.
- `Default Workflow for Legacy Changes`: only the steps on characterizing where possible and then breaking the blocking dependency.
- `Handling Risky Areas`: only the subsection on constructors doing too much.
- `Dependency Breaking Rules`: only the construction problems and the move of splitting construction from use.
- `Seam Rules`: only the rule on the smallest seam.
