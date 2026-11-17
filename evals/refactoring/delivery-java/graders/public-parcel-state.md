---
type: llm
weight: 1
---

PASS if the review flags that `Parcel` is open to uncontrolled change (public mutable fields, the live `getEvents()` list that `DeliveryService` edits directly, or the shipped transition written out by the service twice in `ship` and `reship`) and proposes encapsulating it: private fields, a method on `Parcel` such as `markShipped()`, a read-only view of the events. FAIL if it only comments on the naming or formatting of the fields.
