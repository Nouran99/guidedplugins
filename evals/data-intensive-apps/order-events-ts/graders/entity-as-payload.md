---
type: llm
weight: 1
---

PASS if the review flags that events are `JSON.stringify` of the ORM entity, so internal fields such as `internalNotes` and `customerEmail`, and every future column rename or addition, become part of the event contract, and proposes an explicit, versioned event shape that is separate from the entity.
FAIL if it only mentions payload size or date serialization.
