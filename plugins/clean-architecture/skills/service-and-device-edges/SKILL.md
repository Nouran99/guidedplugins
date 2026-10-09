---
name: service-and-device-edges
description: "Use when code crosses a process or network boundary, consumes messages, wraps a remote service, or talks to hardware. Covers humble listeners, remote calls as I/O and device interfaces. In-process controllers belong to interface-adapters; whether to split a service is boundary-economics."
---

# Service and device edges

Owns the places where the application meets another process, a network or a device. In-process controllers, presenters and gateway implementations are `/clean-architecture:interface-adapters`; deciding whether a service split is worth its cost is `/clean-architecture:boundary-economics`; timeouts, retries and overload handling belong to the `release-it` plugin.

## When to use

- A message consumer, webhook receiver, scheduled trigger or queue handler contains business branching.
- A use case calls another service through a client and the call is written like a local method.
- Someone proposes a service split and claims it gives modularity.
- Code reads device registers, talks to firmware or depends on an interrupt context, and the logic cannot be tested without the target.

## Rules

1. **Do not assume a service is an architectural boundary.** `[MUST]` Source dependencies and data ownership still decide coupling. Check: two services that share domain classes or write the same tables are coupled however many network hops separate them.
2. **Treat remote calls as I/O boundaries, not as local method calls.** `[MUST]` Check: a remote client sits behind a port named for the capability, and the use case does not branch on how the call travels.
3. **Keep service listeners humble.** `[MUST]` A listener translates an external message into a use-case call and returns the result through an output boundary. Check: the listener decodes, calls one use case and acknowledges; it holds no business conditional.
4. **Put embedded and hardware details behind interfaces, so policy tests run without the target device.** `[MUST]` Check: a unit test of the policy runs on a developer machine with a fake device.
5. **Do not let timing, firmware, storage, web or framework concerns drag policy outward.** `[MUST NOT]` Check: no decision of the business is expressed in terms of registers, interrupts, queue offsets or framework callbacks.
6. **Keep verifying the usual things when a boundary appears.** `[MUST]` When service boundaries, process boundaries, remote calls, deployment boundaries or embedded hardware appear, still check source dependencies, data ownership, I/O cost and policy independence (compact rules). Check: the import-direction and ownership checks you run elsewhere also pass here.
7. **Wrap service clients and message publishers behind ports named by role.** `[MUST]` Check: `ShippingRates` and `OrderEvents`, not `FedExClient` and `KafkaProducer`, appear in use-case constructors (`/clean-architecture:ports-and-gateways`).
8. **Do not put business branching or validation in a listener or a hardware adapter.** `[MUST NOT]` Move the rule inward. Check: a `switch` over message content that drives workflow belongs in a use case or entity.
9. **Test policy through use cases with fakes, without the network or the target hardware.** `[MUST]` Check: a recorded message or a fake device exercises the use case; the real transport is exercised only by adapter tests (`/clean-architecture:testing-seams`).
10. **Do not combine unrelated use cases in one listener for operational convenience.** `[MUST NOT]` Check: each message type maps to one use case.
11. **Translate the external schema at the listener.** Added judgment: a wire message is an external format; decode it into a request model there and do not pass the raw message type inward (`/clean-architecture:boundary-models`). Check: the use case signature has no message-library type.
12. **Name a remote port's failure outcomes in domain words.** Added judgment: `Unavailable` or `RateUnknown` lets the use case decide what to do; the mechanics (timeouts, retries, breakers) stay in the adapter and are the subject of `release-it`. Check: the port documents what the caller can see go wrong.
13. **Keep device vocabulary in the device adapter.** Added judgment: register layouts, vendor headers, units of the sensor and interrupt context stay in the adapter; the policy sees domain values (a temperature in degrees, a command to open a valve to a percentage). Check: no hardware constant appears in application code.

## Procedure

1. Find the edge: the consumer, client, trigger or driver. Read what it does between receiving and answering.
2. Classify each statement as translation, orchestration, business policy or device mechanics (`/clean-architecture:place-code`).
3. Move policy into a use case or entity; leave decoding, acknowledging and mapping in the listener.
4. For remote calls and devices, declare a port in the application layer, named by role, with outcomes in domain words.
5. Implement the port in an adapter that owns the client, the schema or the registers; build it in the composition root.
6. Test the use case with a recorded message or a fake device, and keep one adapter test against the real protocol or a simulator the project already has.

## Example

```go
// adapters/queue/overdue_consumer.go: a humble listener
type OverdueConsumer struct {
	UseCase application.SendOverdueNotice
}

func (c OverdueConsumer) Handle(body []byte) error {
	var msg struct {
		LoanID string `json:"loan_id"`
	}
	if err := json.Unmarshal(body, &msg); err != nil {
		return fmt.Errorf("decode overdue message: %w", err)
	}
	return c.UseCase.Execute(application.SendOverdueNoticeRequest{LoanID: msg.LoanID})
}
```

```go
// application/valve.go: a device port named by role, in domain words
type ValveActuator interface {
	Open(percent int) error
	Close() error
}

// adapters/gpio/valve.go knows register addresses and timing; the policy never does.

// application test: a fake that records what the policy asked for
type fakeValve struct{ calls []string }

func (v *fakeValve) Open(p int) error {
	v.calls = append(v.calls, fmt.Sprintf("open %d", p))
	return nil
}

func (v *fakeValve) Close() error {
	v.calls = append(v.calls, "close")
	return nil
}
```

The consumer decodes and calls one use case; every decision about whether to notify lives in the use case. The irrigation policy can be tested on a laptop by asserting on `fakeValve.calls`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Service as boundary | Services share a schema or a domain library and are called "decoupled" | Check source dependencies and data ownership; fix the sharing |
| Local-looking remote call | A remote client used as if it were a plain method with no stated failure outcome | Port named for the capability, outcomes in domain words |
| Fat listener | A consumer with a `switch` over message kinds implementing workflow | One use case per message; the listener only routes |
| Raw message inward | A message-library type in a use-case signature | Decode at the listener into a request model |
| Register in policy | Hardware constants or driver types in application code | Move behind a device port |
| One listener for everything | A single handler consuming unrelated message types | Separate listeners, one use case each |

## Trade-offs and exceptions

- A service boundary can be the right choice for team ownership, scaling or release independence. The rule is that the split alone does not give architectural independence; the dependencies and data do.
- Added judgment (not stated in the source): a hard real-time path may not afford an extra indirection. Rule 4's goal still holds: the policy must be testable without the target device. Keep any bypass at the outermost layer and record it as a documented compromise (`/clean-architecture:boundary-economics`).
- A thin listener without a presenter is fine when the use case returns a plain result; the output boundary may be a return value.
- Added judgment (the source states rule 4 without this exception): do not invent a device abstraction for hardware that is permanent and the only target, if policy tests can already run without it on a developer machine. Weigh it with the cost rule (`/clean-architecture:boundary-economics`); if policy tests still need the device, rule 4 applies in full.

## Verification

- [ ] Each listener decodes, calls one use case and acknowledges, with no business conditional.
- [ ] Remote clients and device drivers sit behind ports named by role.
- [ ] No wire or hardware type appears in a use-case signature.
- [ ] Policy tests run without network or target hardware.
- [ ] Data ownership between services is explicit and no schema is shared silently.
- [ ] Each message type maps to one use case.

## Related

`/clean-architecture:interface-adapters` for in-process adapters; `/clean-architecture:ports-and-gateways` for the ports; `/clean-architecture:boundary-models` for the decoded models; `clean-architecture:service-edge-reviewer` to review a diff.

## Source

- `Services, Distribution, and Embedded Boundaries`
- `Boundary Cost, Deployment, and Operations`: only the boundary kinds and the rule against combining unrelated use cases for operational convenience.
- `Interface Adapters Layer`: only the rule that adapters translate and do not own business policy.
- `Create Ports for Volatile Dependencies`: only message publishers behind ports.
- `Non-Negotiable Rules`: only rule 6, external systems and service clients behind boundaries.
- `Testing Rules`: only the rule that core tests run without the network.
