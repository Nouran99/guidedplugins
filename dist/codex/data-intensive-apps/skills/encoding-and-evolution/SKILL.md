---
name: "encoding-and-evolution"
description: "Use when changing a schema, column, API field, message, enum or status value, choosing JSON, Protocol Buffers, Avro or Thrift, or planning a rolling upgrade across old and new readers and writers. Event meaning and ids are event-design."
---

# Encoding, schema evolution and rolling upgrades

Treats every schema, encoding, API and message as a contract that outlives one deployment: old and new code run side by side, old data stays on disk, and old messages are still in flight. The identity and meaning of events is `$data-intensive-apps:event-design`; where service lines are drawn is `$data-intensive-apps:service-boundaries`; building the compatibility matrix for one change is `$data-intensive-apps:compat-matrix`.

## When to use

- A migration renames, retypes, splits or drops a column, or changes what a column means.
- A field is added to, removed from or repurposed in an API response, a message or a stored document.
- An enum or status gains a value, or an existing value changes meaning.
- A team picks a wire or storage format, or uses native language serialization for data that is stored or crosses services.
- A deploy will run two versions of a service at once, or a consumer may read messages written by an older producer.
- An RPC client hides the network behind a local-looking method call.

## Rules

1. **Plan for schemas to change.** They will; the question is whether the change is survivable. Check: the design says how the next field will be added.
2. **Give every contract a deliberate versioning approach.** Check: each contract has an explicit version or a stated compatibility policy, not an accidental one.
3. **Prefer changes that stay both backward and forward compatible, as far as is feasible.** Backward compatible means new code reads old data; forward compatible means old code reads new data. Check: both directions are tested for each change.
4. **During a rollout, account for readers and writers that are still on the old version.** During a rolling upgrade both versions run; stored rows and in-flight messages come from older ones. Check: the rollout plan names who still runs the old version at each step.
5. **Separate changes that are purely internal from changes to a contract.** Renaming a private class is not a contract change; renaming a serialized field is. Check: each diff hunk is classified.
6. **Select an encoding format on its compatibility, the schema guarantees it gives, its readability, its size and its independence from any one language.** Check: the reason names at least compatibility and one other property.
7. **Do not store or send long-lived or cross-service data in a language-specific serialization.** It couples stored data to class layouts and one runtime. Check: no native serialization (Java serialization, pickle) on storage, queues or cross-service wires.
8. **Regard JSON, XML, binary encodings, Thrift, Protocol Buffers and Avro as contract choices, each evolving differently and with its own costs.** For example, formats with numbered fields and formats that resolve writer and reader schemas handle added and removed fields differently. Check: the evolution rules of the chosen format are listed for the team.
9. **Decide which reader and writer version pairs must keep working while an upgrade rolls out.** Check: which direction must hold (new reads old, old reads new, or both) is written for the rollout.
10. **During a migration, list who reads the old and the new format on each of three paths: database writes, service calls and asynchronous messages.** Check: for each of the three paths, the readers are listed.
11. **Avoid RPC styles whose local-looking calls conceal network failure, version skew, latency or partial failure.** Check: remote calls are visibly remote, with timeouts, failure results and version negotiation in the contract.
12. **Do not break payloads or database semantics without a migration strategy, do not reuse fields with new meaning, and do not silently change enum or status semantics across services.** Check: removed or repurposed fields have a staged plan; a changed meaning gets a new field or value.
13. Added judgment: **Change in stages: expand, migrate, contract.** Add the new form while still writing and reading the old; move readers; backfill; stop writing the old form; remove it in a later release once no old reader, row or message remains. Check: renames and retypes are never a single-release edit.
14. Added judgment: **Make unknown values a decision.** Readers ignore unknown fields, and map an unknown enum value to a defined safe behavior. Check: a test feeds a payload with an extra field and an unknown enum value to the reader.

## Procedure

1. Classify the change: additive, removal, rename, retype, change of meaning, enum change, format change.
2. Name the writers and readers on every path (database, service call, message) and their versions now and during rollout.
3. Choose the staged sequence (expand, migrate, contract) or find a compatible shape that needs no stages (a new optional field with a default).
4. Decide the order of deploys so no reader sees a form it cannot handle.
5. Write the migration for stored data and the cleanup release; record the condition for running it (no old readers, no old messages).
6. Add compatibility tests in both directions and for unknown values (`$data-intensive-apps:data-path-tests`).
7. Update the schema documentation and, where it exists, the schema registry or contract test.

## Example

```ts
// Before: one release renames phone to phoneNumber. Old instances still writing `phone`, old rows,
// and messages already in the queue now produce contacts with no number.
type Contact = { name: string; phoneNumber: string };
const toContact = (raw: any): Contact => ({ name: raw.name, phoneNumber: raw.phoneNumber });

// After, release N (expand): write both fields, read either.
type ContactWire = { name: string; phone?: string; phoneNumber?: string };
const writeContact = (c: Contact): ContactWire => ({ name: c.name, phone: c.phoneNumber, phoneNumber: c.phoneNumber });
const readContact = (w: ContactWire): Contact => ({ name: w.name, phoneNumber: w.phoneNumber ?? w.phone ?? "" });

// Release N+1 (migrate): backfill rows that have only `phone`; move every reader to `phoneNumber`.
// Release N+2 (contract): stop writing `phone`, then drop it, after confirming no old reader,
// stored row or in-flight message still depends on it.
```

An unknown enum value follows the same discipline: the reader maps a status it does not know to a defined fallback (for example "treat as pending and log") rather than throwing.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| One-release rename (Added judgment) | A rename or retype of a serialized field in a single diff | Expand, migrate, contract |
| Field reuse | An old field or tag number given a new meaning | New field; retire the old one |
| Enum renumbering | Reordered or reused enum values | Append only; never change meaning |
| Required-field addition (Added judgment) | New mandatory field with no default for old data | Optional with default, then tighten later |
| Native serialization on the wire | `ObjectOutputStream`, `pickle`, language-specific formats | A schema-based or text format with evolution rules |
| RPC as local call | A generated client with no timeout, retry or error contract | Make failure and version part of the call |

## Trade-offs and exceptions

- Added judgment: data that never outlives one atomic deploy and never leaves the process (an in-memory cache with the same build on both sides) can use a simpler policy. The rules apply as soon as a second version, a stored copy or another team is involved.
- Text formats are readable and easy to inspect; schema-based binary formats are compact and enforce structure. Neither is free of evolution hazards. The source asks only that each format be treated as a contract choice with its own evolution trade-offs.
- Added judgment: a schema registry or contract test adds process; adopt it when several teams share a contract.
- The source says to prefer compatibility in both directions "where possible". Added judgment: backward compatibility alone can be a conscious, written choice for internal batch data if old readers are retired first.

## Verification

- [ ] The change is classified as internal or contract.
- [ ] New code reads old data and old code reads new data, or the one-directional policy is written down.
- [ ] Renames, retypes and removals are staged across releases.
- [ ] No field or enum value changed meaning in place.
- [ ] Unknown fields and values have defined reader behavior and a test.
- [ ] Every remote call states its failure and version behavior.

## Related

`$data-intensive-apps:compat-matrix` for the old-by-new matrix and rollout order; `$data-intensive-apps:event-design` for event identity; `$data-intensive-apps:service-boundaries` for contracts between services; `data-intensive-apps-evolution-reviewer` to review a diff; `data-intensive-apps-schema-migrator` to carry out a staged change.

## Source

- `Schema Evolution Rules`
- `Encoding and Data Flow Rules`
- `Schema Drift by Accident`
