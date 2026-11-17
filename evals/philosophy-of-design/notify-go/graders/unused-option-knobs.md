---
type: llm
weight: 1
---

PASS if the review flags `Options` as a bag of knobs (`Timeout`, `Jitter`, `UseHTTP2`, `TrackOpens`, `TrackClicks`, `SandboxMode`) that no caller sets and the code never reads, and proposes removing them or keeping only what callers need with sensible defaults. FAIL if it only says the struct is large.
