---
name: learning-tests
description: "Pin down how a third-party library already in the project behaves with small tests that call it the way you will, then propose the narrow local interface around it."
disable-model-invocation: true
argument-hint: "[library or API | file where it is used | empty to find vendor usage in the diff]"
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git show *)
---

# Learning tests

Arguments: `$ARGUMENTS`

This skill adds test files: the smallest set that answers your questions about the dependency, run with the project's test command. It does not edit production code, install packages or call remote services, and it does not commit.

## Scope

1. If `$ARGUMENTS` names a library or API, explore that dependency.
2. If it names a file, find the third-party calls in that file and explore those.
3. If it is empty, run `git diff` and `git status`, find the vendor calls in the changed code, state which one you chose, and proceed. If none are found, ask what to explore and stop.
4. The dependency must already be declared in the project (manifest or lock file). If it is not, stop and tell the user; do not install it.

## Steps

1. Write the list of questions you need answered about the dependency, in terms of your own use: What does it return when nothing is found? What does it throw and when? How does it treat empty strings, time zones, unicode, large inputs? Is pagination inclusive? Is the object safe to share between threads? Does ordering matter?
2. Find the project's test command and the test directory conventions. Put these tests in a clearly named file or directory (for example `learning/` or `*_learning_test`) so they can be run on every upgrade.
3. Write one small test per question. Call the real library the way the production code will, with no business logic around it. Name each test after the behavior it records, for example `parser_returns_empty_list_for_blank_input`.
4. Use only local, in-process behavior. If the dependency needs a network or a service, ask what local or sandbox setup the project already has; do not call live services from tests.
5. Run the tests. When a result surprises you, keep the test as an assertion of the observed behavior and add a short comment in the legitimate category of external behavior clarification.
6. From the answers, draft the narrow interface the core needs, in the core's vocabulary: only the operations used, with translated types and errors. Present it; do not build it unless asked (`clean-code:adapter-builder` builds it).
7. Report what you learned, which behaviors are pinned, and which questions remain open.

## Output

```
Learning tests: <dependency> (<version from the manifest>)
Tests: <file>   Command: <command> -> <result>

Question                                   Observed                          Test
empty response body                        returns empty list, no error      returns_empty_list_for_blank_input
unknown id                                 throws NotFound with status 404   throws_not_found_for_unknown_id
...
Surprises: <list or none>
Proposed interface (core vocabulary):
  interface <Name> { <operation>(...): <type> }
Open questions: <list or none>
```

## Stop conditions

- Do not install, upgrade or download anything. Do not call remote services.
- Do not modify production code. If the dependency is used unsafely, list it as a finding.
- If you cannot run the tests, say what you wrote and that it is unverified.
- Keep to the questions you actually need; this is not a survey of the library.

## Source

- `Boundaries and external dependencies`
- `Tests`: only the rule that tests are production-quality code.
