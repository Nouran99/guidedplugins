---
type: llm
weight: 1
---

PASS if the review flags `street`, `city`, `postalCode` and `country` as a bundle of loose strings that travels together (fields of `Parcel`, parameters of `addressBlock`, `isRemoteArea` and `zoneFor`, with `country.trim().toUpperCase()` repeated) and proposes an address value type or object. FAIL if it only says `addressBlock` takes too many parameters, without proposing a type for the address.
