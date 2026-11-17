---
type: llm
weight: 1
---

PASS if the review notices that "not found" and failure are reported in different ways within the module (for example `load_order` returns None when nothing matches while `load_charge` raises `LookupError`, and other routines return False) and proposes one convention. FAIL otherwise.
