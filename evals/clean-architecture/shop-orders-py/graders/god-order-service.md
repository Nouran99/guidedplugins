---
type: llm
weight: 2
---

PASS if the review says `OrderService` bundles unrelated actions for different people (placing, cancelling, refunding, the monthly CSV export, shipping labels, invoices) behind one constructor, and proposes splitting it into one use case per action (for example PlaceOrder, CancelOrder, ExportMonthlyOrders). FAIL if it only comments on the length of the file or on a single long method.
