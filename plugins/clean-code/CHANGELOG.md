# Changelog

All notable changes to this plugin are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/).

## [1.1.0]

### Added
- Project settings: the `principles` skill, the `review`, `audit`, `checklist`, `fix` and `plan` workflows and the `lead` and `final-gate` agents read an optional `.guided-plugins.json` (ignored paths, strictness, report size, primary and secondary books).
- `/clean-code:review --json` returns the findings format used by the CI runner and the `guided` companion plugin.

## [1.0.0]

### Added
- Initial release of the Clean Code plugin: skills, subagents and output styles built on the upstream rule set.
- Opt-in SessionStart hook that injects the compact rules (`inject_rules` option, off by default).
- Vendored upstream rule sets (full, mini, nano) with traceability from every component to the upstream sections.

### Changed
- Wording pass on 2026-10-17, after the 1.0.0 date and before the repository was published (it has no remote yet), so the version stays 1.0.0: the output style `boy-scout` was renamed `campsite` (the skill `boy-scout` keeps its name), and the `lead` agent now states its five-step cap.
