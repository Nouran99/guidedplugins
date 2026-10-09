---
name: consistency-contract
description: "Use when reads may be stale, a user must see their own write, caches or replicas serve reads, or two clients may edit one record. Makes freshness, visibility and conflict handling a contract. Races inside one transaction are transactions-and-isolation; replica mechanics are replication-topology."
---

# Consistency as a contract

Makes the promise to readers explicit: when a write becomes visible, how stale a read may be, and what happens when two writers collide. The mechanism that delivers the promise (leaders, followers, quorums) is `/data-intensive-apps:replication-topology`; anomalies between concurrent transactions are `/data-intensive-apps:transactions-and-isolation`; durability of the write is `/data-intensive-apps:write-acknowledgment`.

## When to use

- A user saves something and the next page shows the old value.
- A read path goes to a replica, a cache, a search index or a read model.
- Two clients can edit the same record (two tabs, two devices, two regions).
- A design document says "eventually consistent" and nothing else.
- A bug is closed as "replication lag" with no decision about whether the product can tolerate it.

## Rules

1. **Spell out what readers are promised about seeing a write that has just completed (read-after-write).** Check: for each flow that writes and then reads, the design says whether the reader must see the write and how that is guaranteed.
2. **Spell out how stale a read is allowed to be (staleness tolerance).** Check: each read path states the largest acceptable delay (a dashboard may lag a minute; a checkout total may not).
3. **Spell out how concurrent updates to one record are detected and settled (conflict handling).** Check: for each entity with concurrent writers there is a named detection method (version, compare-and-set) and a named resolution (reject, merge, last writer wins with the loss stated).
4. **Pay for strong consistency only on the paths where the product itself demands it.** It costs latency and availability. Check: each place that pays for it has the product reason written down.
5. **Adopt eventual consistency as a decision, never as a side effect of how the system happened to be built.** Check: each eventually consistent path states how it converges, how long that takes in practice, and what the user sees meanwhile.
6. **Put the moment a write becomes visible, and whether a stale read can still happen after it, into the documentation or the code's types.** Check: the visibility point is in the docs or in the types (for example a `consistency` parameter on the read function).
7. **Do not offer the phrase "eventual consistency" where a contract is needed.** Check: wherever the phrase appears it comes with a bound, an example of the anomaly a user could see, and an owner for the decision.
8. **Do not blame infrastructure for a stale read that nobody ever decided to allow.** Check: for a stale-read report, find the decision: was fresher data required? If nobody decided, decide, then pick the mechanism.
9. **Do not allow concurrent edits to one record while the conflict outcome is left undefined.** Check: a test with two concurrent writers has a defined outcome.
10. **Make readers and writers agree on freshness.** A reader that needs its own write cannot sit behind a path that only promises "eventually". Check: each reader's stated need is no stronger than the guarantee of the path it uses.
11. Added judgment: **Name the level in code with a small vocabulary.** For example `own-writes`, `bounded-stale(30s)`, `any`. A read function that takes the level as an argument makes the contract reviewable. Check: grep the read paths; each shows its level.

## Procedure

1. List the read paths for the entity: primary, replica, cache, projection, search.
2. For each, write who reads it and what they need (own writes, bounded staleness, any).
3. For each write path, write when the write becomes visible on each read path.
4. Compare need to guarantee. Every gap is either closed with a mechanism or accepted in writing.
5. For entities with concurrent writers, choose detection and resolution; implement with a version column, compare-and-set or a merge rule.
6. Encode the level in the read API where feasible and add a test per level (`/data-intensive-apps:data-path-tests`).
7. Record the decisions where product and engineering will see them.

## Example

```ts
// Before: the profile page reads from a replica, so the user can save a name and still see the old one
async function updateName(userId: string, name: string) {
  await primary.query("UPDATE profiles SET display_name = $1 WHERE user_id = $2", [name, userId]);
}
async function readProfile(userId: string) {
  return replica.query("SELECT display_name FROM profiles WHERE user_id = $1", [userId]);
}

// After: the writer's session remembers a log position; reads use a replica only once it has applied that position
async function updateName(userId: string, name: string, session: Session) {
  await primary.query("UPDATE profiles SET display_name = $1 WHERE user_id = $2", [name, userId]);
  session.minPosition = await primary.position();    // a position at or after our commit
}
async function readProfile(userId: string, session: Session) {
  const caughtUp = (await replica.position()) >= (session.minPosition ?? 0n);
  const db = caughtUp ? replica : primary;           // contract: this reader sees its own writes
  return db.query("SELECT display_name FROM profiles WHERE user_id = $1", [userId]);
}
```

Tracking a log position is one way to provide read-your-writes; it is Added judgment, not a rule of the source. Others are routing the writer's reads to the leader for a short period, or reading from the leader for that entity. Other users reading the profile still get bounded staleness, which is the stated contract.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Slogan | "Eventually consistent" with no bound or example | State bound, visible anomaly and owner |
| Accidental staleness | A reader behind a replica or cache that needs its own write | Route or position-check; or relax the need on purpose |
| Undefined cache TTL | A TTL chosen without a staleness requirement | Derive the TTL from the read path's tolerance |
| Silent last-writer-wins | Two edits to one record, the later one overwrites with no version check | Version check, merge rule, or accepted loss in writing |
| Infrastructure blame | A stale-read ticket closed as "replication" | Decide the freshness requirement, then pick the mechanism |

## Trade-offs and exceptions

- Strong consistency is the right answer where the product needs a single up-to-date value (inventory that must not oversell, unique usernames). The rule is to pay for it deliberately.
- Read-your-writes is a promise to the writer; other readers may legitimately see older data. Monotonic reads and consistent-prefix reads are further guarantees; they live in `/data-intensive-apps:replication-topology`.
- Analytics and search can usually be minutes stale; say so.
- A conflict model of "last writer wins" is acceptable when losing the earlier edit is a stated product decision.

## Verification

- [ ] Each read path has a stated freshness need and the guarantee it actually provides.
- [ ] Flows that write then read state how the reader sees the write.
- [ ] Each entity with concurrent writers has a conflict detection and resolution rule.
- [ ] The phrase "eventual consistency" is never the whole contract.
- [ ] There is a test per consistency level in use.

## Related

`/data-intensive-apps:replication-topology` for the mechanism; `/data-intensive-apps:transactions-and-isolation` for anomalies within transactions; `/data-intensive-apps:derived-data` for cached and projected reads; `/data-intensive-apps:consistency-check` to map every read path in a scope; `data-intensive-apps:consistency-reviewer` to review a diff.

## Source

- `Consistency Rules`
- `Write Semantics`: the visibility, staleness and conflict bullets.
- `Hidden Consistency Contract`
