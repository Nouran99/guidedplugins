---
type: llm
weight: 1
---

PASS if the review flags `format_address` in `utils/common.py` as shared code that serves both invoicing and the shipping label through flag parameters (`for_label`, `upper`, `vat_id`) and proposes separate functions per caller or letting each keep its own copy. FAIL if it only suggests removing the unused parameter or renaming.
