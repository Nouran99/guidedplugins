---
name: "pragmatic-programmer-code-communication"
description: "Use when writing or reviewing names, comments, docs, commit messages, scripts, tests or PR text where intent or rationale is missing, or a comment restates the code. Covers every written artifact. Reporting to the user is `pragmatic-programmer-ownership`; assumptions enforced in code are `pragmatic-programmer-contracts`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Communication in code and artifacts

Code, tests, scripts, comments, documentation and commit messages all carry intent to a later reader. This skill is about the artifacts that stay in the repository. What to tell the user or sponsor about a decision, and when to stop, is `pragmatic-programmer-ownership`; moving an assumption out of a comment and into a check is `pragmatic-programmer-contracts`.

## When to use

- A name hides the domain meaning (`data`, `flag`, `handle2`) or uses another word for a concept the domain already names.
- A comment says what the next line does, or records a rule that code could enforce.
- A non-obvious choice carries no rationale, or a commit message says only "fix".
- A script has no usage line or fails with a message nobody can act on.
- A test name describes a method, not a behavior.

## Rules

1. **Treat code as communication first.** [MUST] Check: a reader new to the file can say what each function is for without running it.
2. **Use names that reflect domain meaning and developer intent.** [MUST] Check: names come from the domain's vocabulary and say why, not only what; one word is used per concept.
3. **Prefer clarity over cleverness.** [SHOULD] Check: you can explain any line you were tempted to compress without reading it twice.
4. **Write comments and docs where they convey decision rationale, contracts or non-obvious behavior.** [MUST] Check: each comment answers a question the code cannot ("why this value", "why not the obvious approach"), not "what".
5. **Do not use comments as a substitute for encoded rules.** [Compact checklist] Check: a comment that states a rule the code could enforce (a check, a type, a test) has been replaced by the enforcement (`pragmatic-programmer-contracts`).
6. **Treat writing as engineering, not overhead.** [MUST] Check: the time spent on the commit message and the doc update is budgeted in the plan.
7. **Make docs, comments, commit messages, scripts and tests communicate intent.** [MUST] Check: for each artifact in the diff you can state the intent it carries.
8. **Use domain vocabulary where it makes rules clearer to the people who must validate or change them.** [Compact checklist] Check: a domain owner can read the names in a rule and recognize their own terms.
9. **Say what changed and why in a commit message.** [Added judgment] The diff shows how. Check: the first line names the change; the body gives the reason and anything the reviewer must know.
10. **Name tests after the behavior they protect.** [Added judgment] Check: the test name reads as a sentence about the system (`pragmatic-programmer-test-portfolio`).
11. **Give scripts a usage line and actionable failures.** [Added judgment] Check: running a script with `--help` or wrong arguments says what to do; a failure names the missing prerequisite.
12. **Keep documentation next to what it describes and change it in the same change.** [Added judgment] Check: the diff that changes behavior also changes the doc that states it.

## Procedure

1. List the written artifacts in the change: names, comments, docs, commit message, scripts, test names, PR text.
2. For each, state the intent it should carry in one sentence. If you cannot, the artifact or the code is unclear.
3. Rename for domain meaning; delete comments that restate code; convert rule-stating comments to checks.
4. Add rationale comments only where a reader would ask "why".
5. Write the commit message: what and why first, how only if non-obvious.
6. Update the doc that the change makes false.

## Example

```python
# Before
def limit(u):
    # check if user is over the limit
    if u.n > 100:                  # 100 requests
        return True
    return False
```

```python
# After
REQUESTS_PER_MINUTE = 100          # Partner agreement: partners share outbound IPs, so we limit per account, not per IP.

def exceeds_request_quota(account: Account) -> bool:
    return account.requests_this_minute > REQUESTS_PER_MINUTE
```

```text
Commit message, before
  fix limit

Commit message, after
  Limit requests per account instead of per IP

  Partners call from shared outbound addresses, so per-IP limits blocked
  unrelated customers. The quota is now keyed on the account; the value is
  unchanged. Existing per-IP counters expire within a minute after deploy.
```

The names say what is asked, the comment records why the quota is per account, and the commit explains the reason and the consequence for deploy.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Restating comment | A comment that paraphrases the next line | Delete it, or rename so it is unnecessary |
| Rule in a comment | "must", "never" or "always" in a comment with no check | Enforce it, then keep only the rationale |
| Vague name | `data`, `info`, `flag`, `tmp`, `handle2` in a non-trivial scope | Name the domain concept |
| Synonym drift | Two words for one concept across the code | Choose one and use it |
| Message "fix" | A commit that says only "fix", "update" or "wip" | State what and why |
| Silent script | A script with no usage text that fails with a stack trace | Usage line and actionable failure |
| Stale doc | A README that describes the old behavior | Update it in the same change |

## Trade-offs and exceptions

- Comments for contracts and non-obvious behavior are encouraged by the source; the objection is to comments that carry a rule code could enforce.
- Local, short-lived names (`i`, `row`) in a three-line scope are clear enough. Added judgment: the wider the scope, the more the name must say.
- Documentation has a maintenance cost. Keep it close to the code and short enough to stay true.
- Naming and function shape at the code level are the territory of a Clean Code plugin; this skill covers all written artifacts, not the micro-rules of identifiers.

## Verification

- [ ] Each name in the change comes from the domain and says intent.
- [ ] No comment restates its line or holds a rule that could be enforced.
- [ ] Every non-obvious choice has its rationale at the choice.
- [ ] The commit message says what changed and why.
- [ ] Docs affected by the change were updated in the same change.

## Related

`pragmatic-programmer-communication-reviewer` to review a diff; `pragmatic-programmer-ownership` for reporting to people; `pragmatic-programmer-contracts` for enforcing instead of describing; `pragmatic-programmer-test-portfolio` for test names.

## Source

- `Naming and Communication Rules`
- `Project and Team Rules`: only the rule that docs, comments, commit messages, scripts and tests must communicate intent.
- `Review Rules`: only the instruction to look for code that communicates poorly.
