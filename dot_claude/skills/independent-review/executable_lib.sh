# Sourced by run.sh and recheck.sh.

# Reviewers must not edit: in the spike, /code-review max finders tried to write probe files.
READ_ONLY=(Read Grep Glob Agent "Bash(git diff:*)" "Bash(git show:*)" "Bash(git log:*)" "Bash(git status:*)"
  "Bash(git rev-parse:*)" "Bash(git ls-files:*)" "Bash(git merge-base:*)" "Bash(git branch:*)")

# headless <prompt> <raw-out.json> <budget-usd> [json-schema]   Fresh claude -p session; returns 1 on any error.
headless() {
  local args=(-p "$1" --output-format json --no-session-persistence --max-budget-usd "$3")
  [[ -n ${4:-} ]] && args+=(--json-schema "$4")
  args+=(--allowedTools "${READ_ONLY[@]}")
  claude "${args[@]}" </dev/null >"$2" 2>"${2%.json}.err" || true
  jq -e '.is_error == false and .subtype == "success"' "$2" >/dev/null 2>&1
}
