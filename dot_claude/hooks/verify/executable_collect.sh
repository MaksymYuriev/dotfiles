#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): record touched JS/TS files for the turn-boundary gate.
# Near-zero cost on purpose; the checks run once per turn in verify-stop.sh.
set -u

[[ "${CLAUDE_VERIFY:-1}" == "0" ]] && exit 0
# A project that ships its own verify gate wins; don't double-run.
[[ -n "${CLAUDE_PROJECT_DIR:-}" && -e "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-stop.sh" ]] && exit 0

INPUT=$(cat)
FILE=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")
SESSION=$(jq -r '.session_id // "default"' <<<"$INPUT")
# Per-agent lists: a subagent's Stop must not verify (or spend the retry budget on) another agent's edits.
AGENT=$(jq -r '.agent_id // "main"' <<<"$INPUT")

[[ -z "$FILE" ]] && exit 0
case "$FILE" in
  */node_modules/* | */.next/* | */dist/*) exit 0 ;;
  *.ts | *.tsx | *.mts | *.cts | *.js | *.jsx | *.mjs | *.cjs) ;;
  *) exit 0 ;;
esac

echo "$FILE" >>"${TMPDIR:-/tmp}/claude-verify-${SESSION}-${AGENT}.list"
exit 0
