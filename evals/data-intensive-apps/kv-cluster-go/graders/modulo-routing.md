---
type: llm
weight: 1
---

PASS if the review flags that `Owners` picks the home node with `hash % len(nodes)`, so adding or removing a node changes the home of most keys and forces a mass data move, and proposes a fixed number of logical partitions mapped to nodes (or consistent hashing).
FAIL if it only mentions the int conversion of the hash or an empty node list.
