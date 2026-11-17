---
type: llm
weight: 1
---

PASS if the review flags that `Product` knows about storage: it loads and saves itself with SQL (`Product.load`, `save`), or a domain method queries the database (`priceCentsOn(db, ...)`), and proposes moving that SQL into a mapper or repository so the model works without a `Db`.
FAIL if it only discusses `BaseRepository`, or says nothing about `Product` doing its own persistence.
