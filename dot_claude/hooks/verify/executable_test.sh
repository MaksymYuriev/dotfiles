#!/usr/bin/env bash
# Regression test for the verify hooks against a stub project: no installs, no network.
# Every check must both pass on clean input and fail on broken input.
# Usage: ~/.claude/hooks/verify/test.sh [fresh-dir]   (default: a new mktemp dir). Exit 1 if any case fails.
set -u

H=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
S="${1:-$(mktemp -d "${TMPDIR:-/tmp}/verify-hooks-test.XXXXXX")}"
SID="test$$"
ERR="$S/.stop-stderr"
FAILED=0

mkdir -p "$S/src" "$S/node_modules/.bin" && cd "$S" || exit 1
git init -q && git config user.email t@t && git config user.name t && git config commit.gpgsign false
cat >package.json <<'EOF'
{"name":"fx","scripts":{"check-types":"sh -c 'if grep -q TYPEERR src/*.ts; then echo \"src/a.ts(1,1): error TS2322\"; exit 1; fi'"}}
EOF
echo 'export default []' >eslint.config.mjs
echo '{}' >.prettierrc
cat >node_modules/.bin/eslint <<'EOF'
#!/bin/sh
fail=0; for f in "$@"; do [ "$f" = --fix ] && continue; grep -q LINTERR "$f" && { echo "$f: 1:1 error no-lint-err"; fail=1; }; done; exit $fail
EOF
printf '#!/bin/sh\necho ran >> %s/.prettier.log\n' "$S" >node_modules/.bin/prettier
chmod +x node_modules/.bin/*
printf 'node_modules\n.prettier.log\n.stop-stderr\n' >.gitignore
printf 'export const a = 1;\n' >src/a.ts && git add -A && git commit -qm init

collect() { echo "{\"session_id\":\"$SID\"${2:+,\"agent_id\":\"$2\"},\"tool_input\":{\"file_path\":\"$S/$1\"}}" | CLAUDE_PROJECT_DIR="$S" "$H/collect.sh"; }
stop() { echo "{\"session_id\":\"$SID\"${1:+,\"agent_id\":\"$1\"}}" | CLAUDE_PROJECT_DIR="$S" "$H/verify-stop.sh" 2>"$ERR"; }

# expect <label> <expected-exit> <actual-exit> [stderr pattern that must appear]
expect() {
  if [[ "$3" == "$2" ]] && { [[ -z "${4:-}" ]] || grep -q -- "$4" "$ERR"; }; then
    echo "PASS  $1"
  else
    echo "FAIL  $1 (expected exit $2${4:+ with \"$4\"}, got $3)"
    sed 's/^/        /' "$ERR" | head -6
    FAILED=1
  fi
}

# edit <content> <label> <expected-exit> [pattern]: write src/a.ts, collect it, run the Stop gate.
edit() { printf '%b' "$1" >src/a.ts; collect src/a.ts; stop; expect "$2" "$3" $? "${4:-}"; }

stop; expect "no edits: fast path" 0 $?
edit 'export const a = 2;\n' "clean edit passes" 0
edit 'export const a = 2; // LINTERR\n' "eslint error blocks" 2 "no-lint-err"
edit 'export const a: number = "x"; // TYPEERR\n' "typecheck error blocks" 2 "TS2322"
edit '// one\n// two\n// three\nexport const a = 3;\n' "3-line comment blocks" 2 "3-line comment"
edit 'test.only("x", () => {});\n' "4th red stop in a row: loop cap releases" 0
edit 'test.only("x", () => {});\n' ".only blocks after cap reset" 2 "focused test"
edit 'export const a = 4;\n' "clean edit passes, counter resets" 0

printf 'export const a = 5; // LINTERR\n' >src/a.ts
echo "{\"session_id\":\"$SID\",\"tool_input\":{\"file_path\":\"$S/src/a.ts\"}}" | CLAUDE_VERIFY=0 "$H/collect.sh"
echo "{\"session_id\":\"$SID\"}" | CLAUDE_VERIFY=0 "$H/verify-stop.sh" 2>"$ERR"
expect "CLAUDE_VERIFY=0 opts out" 0 $?

printf 'export const a = 6; // LINTERR\n' >src/a.ts
collect src/a.ts sub1
stop; expect "main Stop ignores a subagent's edit" 0 $?
stop other; expect "unrelated SubagentStop ignores it" 0 $?
stop sub1; expect "own SubagentStop blocks" 2 $? "no-lint-err"

mkdir -p .claude/hooks && touch .claude/hooks/verify-stop.sh
collect src/a.ts
stop; expect "project with its own gate: global gate stands down" 0 $?

[[ -s .prettier.log ]] && echo "PASS  prettier ran" || { echo "FAIL  prettier never ran"; FAILED=1; }

for f in "${TMPDIR:-/tmp}"/claude-verify-"$SID"-*; do [[ -e "$f" ]] && rm "$f"; done
echo "fixture: $S"
[[ $FAILED -eq 0 ]] && echo "ALL PASSED" || echo "SOME CASES FAILED"
exit $FAILED
