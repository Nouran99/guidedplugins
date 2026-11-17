---
type: llm
weight: 1
---

PASS if the review flags `IRepository<T>` / `EfRepository<T>` as a generic CRUD abstraction (GetAll, Where with a predicate, Update, Delete) shared by every repository and not shaped by what the use cases need, and proposes repository interfaces defined per aggregate root with intention-named methods. FAIL otherwise.
