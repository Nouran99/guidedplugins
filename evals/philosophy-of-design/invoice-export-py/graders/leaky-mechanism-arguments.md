---
type: llm
weight: 2
---

PASS if the review flags `page_size`, `use_index` or `presorted` as parameters that expose implementation choices (paging, a database index hint, sort state) which every caller has to pass or decide, and proposes keeping them inside the module. FAIL if it only says there are too many parameters without saying they expose how the export works.
