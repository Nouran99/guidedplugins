---
type: llm
weight: 2
---

PASS if the review flags that the `LoanStore` interface is declared in the `infrastructure` package and imported by the application-layer `RenewLoan` (the core depends on an interface owned by the outer layer, so the arrow points outward), and proposes declaring it in the application or domain layer with `JdbcLoanStore` implementing it.
FAIL if it only mentions the SMTP class or the Spring imports, or accepts the use case as fine because it depends on an interface.
