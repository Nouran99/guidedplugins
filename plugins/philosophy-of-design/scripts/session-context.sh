#!/usr/bin/env bash
# SessionStart hook. Prints the compact A Philosophy of Software Design rules so Claude Code adds them to the session context.
# Disabled unless the plugin option "inject_rules" is true (Claude Code exports it as CLAUDE_PLUGIN_OPTION_INJECT_RULES).
set -eu

case "${CLAUDE_PLUGIN_OPTION_INJECT_RULES:-false}" in
  true|TRUE|True|1|yes|on) ;;
  *) exit 0 ;;
esac

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
nano="$root/skills/principles/references/nano.md"
[ -r "$nano" ] || exit 0

printf '%s\n\n' "Always-on rules from the A Philosophy of Software Design plugin (philosophy-of-design). Apply them to every code change in this session. The philosophy-of-design:principles skill holds the longer rule set."
cat "$nano"
