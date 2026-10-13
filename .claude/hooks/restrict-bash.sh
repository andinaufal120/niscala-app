#!/usr/bin/env bash
# PreToolUse guard for Bash in the TDD subagents: allows only the
# commands they need, so Bash can't be used to bypass the edit guard.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')

case "$cmd" in
  *';'* | *'&'* | *'|'* | *'>'* | *'<'* | *'`'* | *'$('* | *$'\n'*)
    echo "Chained or redirected commands are not allowed: $cmd" >&2
    exit 2
    ;;
esac

case "$cmd" in
  "flutter test" | "flutter test "* | \
  "flutter analyze" | "flutter analyze "* | \
  "dart analyze" | "dart analyze "* | \
  "flutter pub get" | \
  "git status" | "git status "* | \
  "git diff" | "git diff "* | \
  "git log" | "git log "*)
    exit 0
    ;;
esac

echo "Command not allowed for this subagent: $cmd" >&2
exit 2
