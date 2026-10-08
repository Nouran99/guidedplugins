# Security policy

These plugins contain Markdown instructions and one small shell script per plugin (`scripts/session-context.sh`, opt-in, prints a bundled file and nothing else).

## What to report

- A component that could cause an agent to run destructive or network commands it should not (see the safety rules in [docs/PLUGIN_SPEC.md](docs/PLUGIN_SPEC.md)).
- A script that reads or writes outside its plugin directory.

## How to report

Open a private security advisory on the GitHub repository (Security tab, "Report a vulnerability"). Please do not open a public issue for these.
