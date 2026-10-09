---
name: service-boundaries
description: "Use when splitting or merging services, designing an API between services or teams, or adding a cross-service call on a hot path. Aligns boundaries with data ownership. One dataset's owner is source-of-truth; wire formats are encoding-and-evolution."
---

# Service boundaries and cross-service contracts

Draws service lines where data ownership and update semantics put them, keeps tightly consistent concepts together, and keeps hot paths from becoming chains of remote calls. How the messages across a line change over time is `/data-intensive-apps:encoding-and-evolution`; the owner of one dataset is `/data-intensive-apps:source-of-truth`; the cut of a store across nodes is `/data-intensive-apps:partitioning-locality`.

## When to use

- A monolith is being split, or services are being merged.
- A new endpoint or message is added between two services or teams.
- A request handler calls another service once per item in a loop.
- Two services write the same dataset, or a business rule needs both to change atomically.
- A "simple" feature requires coordinated deploys of several services.

## Rules

1. **Draw service boundaries along data ownership and along how the data is updated.** The service that must enforce an invariant should own the data it constrains. Check: each dataset is written by one service, and the invariants over it are enforced there.
2. **Do not casually spread a single, tightly consistent business concept over several services.** An order and its lines that must change together belong together. Check: if an operation must be atomic across services, the split has a written justification and a coordination story (`/data-intensive-apps:transactions-and-isolation`).
3. **Avoid hot paths that assemble a result by making many calls between services.** Each hop adds latency, a failure mode and a version dependency. Check: count remote calls for the busiest request; none sits inside a per-item loop.
4. **Have each contract state clearly the identifiers it uses, its version and how failure behaves.** Check: each endpoint or message documents the ids it carries, its version, what a retry does, and what partial failure looks like.
5. **Do not hide remote failure behind local-looking calls.** From the encoding rules: avoid RPC designs that hide network failure, version skew, latency or partial failure. Check: remote calls have timeouts, a result type that can express failure, and an explicit version.
6. Added judgment: **Draw the update path for each user action.** List which services write for one action; more than one writer means a coordination mechanism is required. Check: the diagram exists for the main write flows.
7. Added judgment: **Offer batch operations where callers need many items.** Accept a list of ids and return per-id results so callers do not loop. Check: no caller issues N requests for N items on a hot path.
8. Added judgment: **Cache read-only reference data on the caller with an explicit staleness bound and version.** The cache is derived data (`/data-intensive-apps:derived-data`). Check: the cache states its source, its bound and how it is refreshed.
9. Added judgment: **If two services always change together and need a transaction, treat merging them as an option.** The boundary is a hypothesis about independence; evidence can falsify it. Check: change history shows how often the two change in the same release.

## Procedure

1. List the datasets and, for each, the service that enforces its invariants and writes it.
2. Draw the update path for the main user actions and count the writers.
3. Mark the invariants that span datasets and where they are enforced; if they span services, choose merge, single-owner API, or an explicit reconciliation design.
4. List the remote calls on each hot request; replace per-item loops with batch calls; move reference data closer with a stated staleness.
5. Write each contract: ids, version, idempotency and retry behavior, partial results, timeouts.
6. Record the evidence that would make you revisit the boundary.

## Example

```ts
// Before: checkout asks the pricing service for each cart line in turn.
// N sequential round trips; any failure mid-loop leaves a half-priced cart; there is no price-list version.
let total = 0;
for (const line of cart.lines) {
  const price = await pricing.getPrice(line.sku);
  total += price.amountMinor * line.qty;
}

// After: one batch call carries the version and a request id; missing items are part of the contract.
const res = await pricing.getPrices({
  skus: cart.lines.map((l) => l.sku),
  priceListVersion: cart.priceListVersion,
  requestId: cart.id,                                  // lets the service deduplicate a retry
});
// res: { prices: Record<string, { amountMinor: number; currency: string }>, missing: string[] }
if (res.missing.length > 0) throw new PricingIncomplete(res.missing);
const total = cart.lines.reduce((sum, l) => sum + res.prices[l.sku].amountMinor * l.qty, 0);
```

If pricing and checkout turn out to change together on nearly every release, the stronger fix is to question the boundary, not to batch the calls.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Distributed monolith | Releases of several services must be coordinated | Merge, or define a stable contract with versioning |
| Shared writable table | Two services update the same table | One owner; others read through an API or a feed |
| Per-item remote call | A network call inside a loop over items | Batch endpoint or local cache of reference data |
| Contract without identity | A request with no ids, no version, no retry semantics | Add ids, version and failure semantics |
| Split invariant | A rule needs two services to agree atomically | Merge, or one owner plus reconciliation |

## Trade-offs and exceptions

- Organizational boundaries (teams, compliance, scaling units) can justify a split that data ownership alone would not. The rule asks that the cost of the split be known, not that every split be rejected.
- Chatty calls off the hot path, such as an admin screen, may be acceptable.
- A shared database within one team can be a stable arrangement if ownership by table is enforced.
- Batch endpoints add API surface; add them where the loop exists, not everywhere.

## Verification

- [ ] Every dataset has one writing service that enforces its invariants.
- [ ] No operation that must be atomic spans services without a stated coordination design.
- [ ] The busiest request makes a small, fixed number of remote calls.
- [ ] Each contract names identifiers, version, retry behavior and partial-failure results.
- [ ] Reference-data caches state their source and staleness bound.

## Related

`/data-intensive-apps:source-of-truth` for dataset ownership; `/data-intensive-apps:encoding-and-evolution` for contract change; `/data-intensive-apps:transactions-and-isolation` for cross-service atomicity; `/data-intensive-apps:partitioning-locality` for cuts inside a store; `data-intensive-apps:service-boundary-reviewer` to review a diff.

## Source

- `API and Service Boundary Rules`
- `Encoding and Data Flow Rules`: only the rule against RPC designs that hide network failure, version skew, latency or partial failure.
- `Review Checklist`: only the item on service boundaries and data ownership.
