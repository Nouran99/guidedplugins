---
name: aggregate-boundaries
description: "Use when designing or reviewing what belongs inside one aggregate: its size, members, invariants, or an aggregate shaped like an ORM object graph. Inside one aggregate only. Outside access is aggregate-root-discipline; links between aggregates are cross-aggregate-coordination."
---

# Aggregate boundaries

Owns the inside of one aggregate: what is a member because an invariant needs it, and what is not. It does not decide how outside code may touch the aggregate (`/ddd-implementing:aggregate-root-discipline`) or how two aggregates relate (`/ddd-implementing:cross-aggregate-coordination`). The evidence procedure for a boundary change is `/ddd-implementing:invariant-inventory`.

## When to use

- You add an aggregate, or add a member entity or collection to one.
- A class loads a list of children "because the table has a foreign key".
- Two users editing different parts of one object conflict with each other.
- An aggregate is loaded in full to change one field.
- A review asks "why are these two things in the same aggregate?"

## Rules

1. **[MUST] Design aggregates around invariants that must hold immediately.** Consistency is the reason for a boundary. Check: for each member, you can name a written rule that spans it and the root and must be true at the end of every transaction.
2. **[MUST] Keep aggregates as small as possible.** Small aggregates scale better in both understanding and throughput: a large one widens the set of concurrent writes that conflict and the amount a reader must hold in mind. Check: removing any member would break a named invariant, and members that fail this test belong in their own aggregate or in a value object; two actors editing unrelated parts of the same concept do not contend for one aggregate.
3. **[MUST] Do not treat a large object graph as evidence of good modeling.** Check: size is justified by invariants, not by how much of the schema is reachable.
4. **[MUST NOT] Size aggregates to fit ORM navigation.** The mapping tool's relations are not a modeling reason. Check: no collection exists only because a foreign key does.
5. **[MUST] Define the boundary conservatively** (a step of the source's code-generation order). Start with the root and its value objects; add a member entity only when an immediate invariant demands it. Check: the first version of a new aggregate has no child collection unless a rule needs one.
6. **[MUST] Place invariants on the aggregate root or in the local model.** Check: every invariant from rule 1 is enforced by a root method or a value object inside the boundary, not by a service reading several objects.
7. **[Compact checklist] When an aggregate boundary changes, list the immediate invariants that require the new shape.** Check: the change description contains that list (use `/ddd-implementing:invariant-inventory`).
8. **[Added judgment] A member whose invariants never involve its siblings is a candidate to become its own aggregate.** Check: split the member's rules from the root's; if neither set mentions the other's data, the member can move out.
9. **[Added judgment] Treat an unbounded collection inside an aggregate as a warning.** A list that grows with time (attendance marks, audit entries, messages) makes every load and every write heavier. Check: the collection has a business-defined upper bound, or it lives in its own aggregate keyed by the parent's identity.

## Procedure

1. Write the invariants of the concept as sentences ("seats taken never exceed capacity"). Ask the domain expert which must be true at every moment and which may be repaired shortly after.
2. For each invariant, list the data it reads and writes. The union for the invariants that must hold immediately is the minimal boundary.
3. Mark every other piece of data (history, notes, derived views) as a candidate for another aggregate, a value object or a read model.
4. Move candidates out, replacing object references with identities (`/ddd-implementing:cross-aggregate-coordination`; `ddd-implementing:identity-reference-converter` for a large change).
5. Check the new aggregate against rule 2: could two people work on it concurrently without false conflicts?
6. Write the tests for each invariant directly on the root (`/ddd-implementing:domain-tests`). Run them after each split.

## Example

```ts
// Before: an aggregate sized to the table relations
class Cohort {
  id!: string;
  capacity!: number;
  enrollments: Enrollment[] = [];        // every row, always loaded with the cohort
}
class Enrollment {
  student!: Student;                     // whole Student graph
  attendance: AttendanceRecord[] = [];   // grows with every class meeting
  grades: Grade[] = [];
  status!: string;
}
// service: if (cohort.enrollments.length >= cohort.capacity) throw new Error("full");

// After: the immediate invariants are "seats taken <= capacity" and "one seat per student"
class Cohort {                           // aggregate root; holds only what those rules read
  private readonly seats = new Set<string>();           // student ids, at most `capacity`
  constructor(readonly id: CohortId, private readonly capacity: number) {}
  admit(student: StudentId): SeatTaken {
    if (this.seats.has(student.value)) throw new AlreadyAdmitted(this.id, student);
    if (this.seats.size >= this.capacity) throw new CohortFull(this.id);
    this.seats.add(student.value);
    return new SeatTaken(this.id, student);
  }
}
class AttendanceSheet {                  // separate aggregate, keyed by cohort and student
  private readonly marks: Mark[] = [];
  constructor(readonly cohortId: CohortId, readonly studentId: StudentId) {}
  record(mark: Mark): void { this.marks.push(mark); }
}
```

Attendance and grades appear in no invariant with seats, so they left the cohort; the seat set is bounded by `capacity`, so loading it stays cheap.

## Anti-patterns

- **ORM-shaped aggregate.** The aggregate mirrors the foreign keys. Detect: collections of child entities whose rules never mention the root.
- **God aggregate.** One root with a dozen collections that every use case loads. Detect: use cases that touch one field but load the whole graph.
- **Invariant outside the boundary.** The rule is checked in a service that loads siblings. Detect: a service that reads `root.children` to enforce a limit.
- **Unbounded history inside.** Detect: a collection that appends on every event in the aggregate's life.

## Trade-offs and exceptions

- "As small as possible" is a default direction, not a count. Some concepts legitimately hold a handful of members behind a real invariant.
- The source allows more than one aggregate per transaction only with a compelling reason. Added judgment: the same reason may justify a larger boundary. State it, and prefer the smaller boundary with eventual consistency when the business allows delay (`/ddd-implementing:cross-aggregate-coordination`).
- Starting conservative means a boundary may later need to grow; growing it is a change that needs the list in rule 7.

## Verification

- [ ] Every member of the aggregate is named in an immediate invariant.
- [ ] No collection exists only because a table has a foreign key.
- [ ] Every immediate invariant is enforced by the root or a value object inside it.
- [ ] Unrelated edits do not contend for the same aggregate.
- [ ] Each invariant has a test on the root.
- [ ] The change description lists the invariants that justify the boundary.

## Related

`/ddd-implementing:invariant-inventory` for the evidence list; `/ddd-implementing:aggregate-root-discipline` for access; `/ddd-implementing:cross-aggregate-coordination` for the links after a split; `/ddd-implementing:value-objects` for data that belongs inside as a value; `ddd-implementing:aggregate-design-reviewer` to review a diff.

## Source

- `Aggregate Rules of Thumb`: only the Aggregates Are Consistency Boundaries subsection and the anti-patterns on ORM-sized aggregates.
- `Aggregates Are Consistency Boundaries`
- `Code Generation Rules`: only the steps that define the boundary conservatively and place invariants on the root.
