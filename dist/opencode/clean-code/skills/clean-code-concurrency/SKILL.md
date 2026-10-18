---
name: "clean-code-concurrency"
description: "Use when adding or changing threads, async tasks, locks, queues, workers, shutdown or cancellation, or when a test of such code fails intermittently. Decides whether concurrency is warranted and keeps shared state in check; a flaky test with no concurrency is clean-code-clean-tests."
license: "MIT"
metadata:
  plugin: "clean-code"
  book: "Clean Code"
  invocation: "auto"
---

# Concurrency and async work

Treats timing as an input to correctness. It decides whether concurrency belongs in the design at all, keeps shared mutable state small, makes lifecycle explicit and makes concurrent behavior testable. Reliability policy for production dependencies (retry budgets, circuit breaking) is outside this book.

## When to use

- You are about to add a thread, goroutine, async task, executor, timer or background loop.
- Code shares mutable state between callers that may run at the same time.
- Something must stop cleanly: shutdown, cancellation, timeouts, in-flight work.
- A test of threaded, async or timer-driven code fails one run in twenty, or only on CI. A flaky test whose code under test has no concurrency is order, clock or environment dependence: `clean-code-clean-tests`.
- You change code you did not write and do not know how it is scheduled.

## Rules

1. **Do not add concurrency without a real benefit.** Name the benefit (latency hidden, throughput required, a blocking call that must not freeze the caller). Check: you can state the benefit and how you would notice if it were not realized.
2. **Prefer plain sequential code when it does the job.** Check: you tried, or reasoned about, the sequential version first.
3. **Keep as little mutable state shared as possible.** What is not shared cannot race. Check: list every variable reachable from more than one concurrent path; shrink the list.
4. **Prefer immutable data, message passing or one clear owner for each piece of state.** Each piece of mutable data has exactly one owner at a time. Check: for each shared datum, you can name who may write it and how others get a view.
5. **Keep every locked or synchronized region as small as it can be.** Do the slow work outside the lock and keep invariants inside it. Check: no I/O, callback or foreign call executes while holding a lock.
6. **State shutdown, cancellation, timeout and cleanup behavior openly.** Every started task has an owner who stops it and waits for it; every wait has an upper bound or a cancellation path. Check: you can say what happens to in-flight work when the process is asked to stop.
7. **Give concurrent behavior careful tests wherever it matters.** Use controllable schedulers, latches, fake clocks and deterministic hand-offs, not `sleep`. Check: the test would fail if the lock were removed.
8. **Understand the execution model before you change concurrent code.** Which thread, loop or pool runs this callback? Can it block? Is this object shared? Check: you can answer these questions for the code you edit, or you read until you can.
9. **Avoid letting one synchronized method rely on another.** Two individually safe calls are not safe as a sequence (check-then-act). Check: invariants that span several calls are protected by one operation or one lock scope.
10. **Make single-threaded behavior correct before introducing threads.** Keep the logic testable without threads, and keep threading policy separate from logic. Check: the core algorithm has tests that run on one thread.
11. **Make threaded code configurable, with swappable policy, when its policy or degree of concurrency may change.** Pool size, executor and scheduling are injected or configured. Check: you can run the logic with a synchronous executor in tests.
12. **Where practical, exercise timing-sensitive tests with different thread counts, schedules and platforms.** Check: repeated runs, stress with different parallelism, and the race detector or equivalent where the platform provides one.
13. **Assume an unexplained failure may be a concurrency defect until evidence shows it is not.** Do not rerun until green. Check: every intermittent failure has either a root cause or an open question recorded.

## Procedure

1. State why concurrency is needed and what the sequential baseline costs.
2. Inventory shared state in the touched code: who reads, who writes, and under which protection.
3. Reduce it: pass values instead of references, copy at hand-off, or move the data behind one owner.
4. Keep the unit of concurrent work small, pure where possible, and independent of its scheduler.
5. Define the lifecycle: start, stop, cancel, wait, timeout. Write the shutdown path first.
6. Test the logic single-threaded, then test the concurrency with deterministic hooks.
7. Run the concurrent tests repeatedly and under variation. Record the command.

## Example

```go
// Before: goroutines never stop, errors vanish, counter is shared unprotected
func warmCaches(ids []string) int {
	count := 0
	for _, id := range ids {
		go func(id string) {
			if _, err := loadProfile(id); err == nil {
				count++ // data race
			}
		}(id)
	}
	return count // returns before the work is done
}

// After: bounded lifetime, ownership of the result, caller can cancel
func warmCaches(ctx context.Context, ids []string, load func(context.Context, string) error) (int, error) {
	var wg sync.WaitGroup
	results := make(chan error, len(ids))
	for _, id := range ids {
		wg.Add(1)
		go func(id string) {
			defer wg.Done()
			results <- load(ctx, id)
		}(id)
	}
	wg.Wait()
	close(results)

	warmed := 0
	for err := range results {
		if err == nil {
			warmed++
		}
	}
	return warmed, ctx.Err()
}
```

The result is collected by one owner, the function waits for what it started, `load` is injectable so tests need no network, and cancellation flows through the context. Whether this concurrency is worth having is rule 1: a loop might be enough.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Concurrency by reflex | Threads added with no stated benefit | Remove, or state and measure the benefit |
| Unprotected shared counter | Writes to a variable from several tasks | Channel, atomic, or one owner |
| Check-then-act | `if (!map.has(k)) map.put(k, v)` across separate synchronized calls | One atomic operation |
| Lock held over I/O | A callback or network call inside a critical section | Shrink the section |
| Orphaned task | A task started with no owner to stop or wait | Tie lifetime to a scope or context |
| Sleep synchronization | `sleep` in code or tests to wait for another task | Latch, signal, fake clock |
| Rerun until green | Flaky test suppressed by retry | Find the cause |
| Hard-coded policy | Pool size and executor fixed in logic | Inject, configure |

## Trade-offs and exceptions

- Async I/O in a single-threaded event loop shares less state than threads, but still has ordering hazards and needs cancellation and error handling for every task. Do not fire and forget.
- Some libraries require a particular concurrency style. Follow the framework, and isolate it from your logic.
- "As small as possible" means as small as the invariant allows: a section is minimal when splitting it would break the invariant it protects. Correctness comes first; do not shrink a lock scope by guesswork and introduce a race.
- Tests that cannot be made deterministic still need a recorded repeat count and the environment they ran in.
- This skill does not choose a memory model or a lock-free algorithm; if the problem needs one, say so and keep it behind a small, well-tested interface.

## Verification

- [ ] The benefit of the concurrency is stated.
- [ ] Every shared mutable variable has one named owner or a named protection.
- [ ] Every started task has an owner that waits for it or cancels it.
- [ ] Every wait has a bound or a cancellation path.
- [ ] The logic is tested without threads, and the concurrency is tested without `sleep`.
- [ ] Concurrent tests were run repeatedly or with a race detector, and the command is recorded.

## Related

`clean-code-clean-tests` for deterministic test structure; `clean-code-error-handling` for failure and cleanup paths; `clean-code-system-construction` for injecting executors; `clean-code-concurrency-reviewer` to review a diff.

## Source

- `Concurrency and async work`
- `Error handling`: only the rule on visible cleanup and shutdown paths.
