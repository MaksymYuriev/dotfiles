#!/usr/bin/env bash
# Stop/SubagentStop: batched verification of every JS/TS file edited this turn.
# Per nearest package: eslint --fix, prettier --write, then the package's typecheck script
# (one turbo run per repo when turbo defines the task). Plus added-lines checks: comment
# budget and focused tests. Exit 2 blocks the turn and hands stderr back to the agent.
# Tools, configs and scripts are discovered, never assumed; anything missing is skipped.
# Opt out per project via settings "env": CLAUDE_VERIFY=0 (all) / CLAUDE_VERIFY_COMMENTS=0.
set -u

[[ "${CLAUDE_VERIFY:-1}" == "0" ]] && exit 0

INPUT=$(cat)
SESSION=$(jq -r '.session_id // "default"' <<<"$INPUT")
# Same key as collect.sh: Stop has no agent_id (main thread), SubagentStop checks only its own edits.
AGENT=$(jq -r '.agent_id // "main"' <<<"$INPUT")
STATE="${TMPDIR:-/tmp}/claude-verify-${SESSION}-${AGENT}"
LIST="$STATE.list"
FAILS="$STATE.fails"
HOOK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MAX_BLOCKS=3

[[ -s "$LIST" ]] || exit 0

FILES=$(sort -u "$LIST" | while IFS= read -r f; do [[ -f "$f" ]] && echo "$f"; done)
if [[ -z "$FILES" ]]; then
  rm -f "$LIST" "$FAILS"
  exit 0
fi

pkg_dir_of() {
  local d
  d=$(dirname "$1")
  while [[ "$d" != "/" && "$d" != "$HOME" ]]; do
    [[ -f "$d/package.json" ]] && { echo "$d"; return; }
    d=$(dirname "$d")
  done
}

repo_root_of() {
  git -C "$1" rev-parse --show-toplevel 2>/dev/null || echo "$1"
}

# Walk from $1 up to $2 (inclusive) looking for node_modules/.bin/$3.
find_bin() {
  local d="$1"
  while :; do
    [[ -x "$d/node_modules/.bin/$3" ]] && { echo "$d/node_modules/.bin/$3"; return; }
    [[ "$d" == "$2" || "$d" == "/" ]] && return
    d=$(dirname "$d")
  done
}

# Walk from $1 up to $2 (inclusive) for a file whose name matches the ERE $3.
has_config() {
  local d="$1"
  while :; do
    ls -a "$d" 2>/dev/null | grep -Eq "$3" && return 0
    [[ "$d" == "$2" || "$d" == "/" ]] && return 1
    d=$(dirname "$d")
  done
}

run_script_cmd() {
  if [[ -f "$1/pnpm-lock.yaml" ]]; then echo "pnpm run"
  elif [[ -f "$1/yarn.lock" ]]; then echo "yarn run"
  elif [[ -f "$1/bun.lock" || -f "$1/bun.lockb" ]]; then echo "bun run"
  else echo "npm run --silent"
  fi
}

# "pkgdir<TAB>root<TAB>file" per file inside a package.
MAP=$(while IFS= read -r f; do
  p=$(pkg_dir_of "$f")
  [[ -n "$p" ]] && printf '%s\t%s\t%s\n' "$p" "$(repo_root_of "$p")" "$f"
done <<<"$FILES")

if [[ -z "$MAP" ]]; then
  rm -f "$LIST" "$FAILS"
  exit 0
fi

LINT_OUT=""
FORMAT_OUT=""
TYPE_OUT=""
TURBO_JOBS=""

PKG_DIRS=$(cut -f1 <<<"$MAP" | sort -u)
while IFS= read -r PKG; do
  ROOT=$(awk -F'\t' -v p="$PKG" '$1 == p { print $2; exit }' <<<"$MAP")
  PKG_FILES=$(awk -F'\t' -v p="$PKG" '$1 == p { print $3 }' <<<"$MAP")

  ESLINT=$(find_bin "$PKG" "$ROOT" eslint)
  if [[ -n "$ESLINT" ]] && has_config "$PKG" "$ROOT" '^(eslint\.config\.(js|mjs|cjs|ts|mts|cts)|\.eslintrc(\..+)?)$'; then
    OUT=$(cd "$PKG" && tr '\n' '\0' <<<"$PKG_FILES" | xargs -0 "$ESLINT" --fix 2>&1) \
      || LINT_OUT+="$OUT"$'\n'
  fi

  PRETTIER=$(find_bin "$PKG" "$ROOT" prettier)
  if [[ -n "$PRETTIER" ]] && { has_config "$PKG" "$ROOT" '^(\.prettierrc(\..+)?|prettier\.config\..+)$' \
    || jq -e '.prettier' "$PKG/package.json" >/dev/null 2>&1; }; then
    OUT=$(cd "$PKG" && tr '\n' '\0' <<<"$PKG_FILES" | xargs -0 "$PRETTIER" --write --ignore-unknown 2>&1 >/dev/null) \
      || FORMAT_OUT+="$OUT"$'\n'
  fi

  SCRIPT=""
  for s in check-types typecheck type-check tsc; do
    if jq -e --arg s "$s" '.scripts[$s]' "$PKG/package.json" >/dev/null 2>&1; then SCRIPT="$s"; break; fi
  done
  [[ -z "$SCRIPT" ]] && continue

  NAME=$(jq -r '.name // empty' "$PKG/package.json")
  TURBO=$(find_bin "$ROOT" "$ROOT" turbo)
  if [[ -n "$NAME" && -n "$TURBO" && -f "$ROOT/turbo.json" ]] \
    && jq -e --arg t "$SCRIPT" '(.tasks // .pipeline // {}) | has($t)' "$ROOT/turbo.json" >/dev/null 2>&1; then
    TURBO_JOBS+="$ROOT"$'\t'"$SCRIPT"$'\t'"$NAME"$'\n'
  else
    OUT=$(cd "$PKG" && $(run_script_cmd "$ROOT") "$SCRIPT" 2>&1) \
      || TYPE_OUT+="── $PKG ($SCRIPT)"$'\n'"$(tail -30 <<<"$OUT")"$'\n'
  fi
done <<<"$PKG_DIRS"

# One turbo invocation per (repo, task): shared cache, one process for all touched packages.
if [[ -n "$TURBO_JOBS" ]]; then
  while IFS=$'\t' read -r ROOT SCRIPT; do
    [[ -z "$ROOT" ]] && continue
    FILTERS=$(awk -F'\t' -v r="$ROOT" -v s="$SCRIPT" '$1 == r && $2 == s { printf "--filter=%s\n", $3 }' <<<"$TURBO_JOBS" | sort -u)
    OUT=$(cd "$ROOT" && tr '\n' '\0' <<<"$FILTERS" | xargs -0 "$ROOT/node_modules/.bin/turbo" run "$SCRIPT" --output-logs=errors-only 2>&1) \
      || TYPE_OUT+="── turbo $SCRIPT ($ROOT)"$'\n'"$(tail -40 <<<"$OUT")"$'\n'
  done <<<"$(cut -f1,2 <<<"$TURBO_JOBS" | sort -u)"
fi

# Added-lines checks, per git repo so `git diff HEAD` resolves.
COMMENT_OUT=""
FOCUS_OUT=""
ROOTS=$(cut -f2 <<<"$MAP" | sort -u)
while IFS= read -r ROOT; do
  ROOT_FILES=$(awk -F'\t' -v r="$ROOT" '$2 == r { print $3 }' <<<"$MAP")
  if [[ "${CLAUDE_VERIFY_COMMENTS:-1}" != "0" && -x "$HOOK_DIR/comment-budget.sh" ]]; then
    COMMENT_OUT+=$(cd "$ROOT" && tr '\n' '\0' <<<"$ROOT_FILES" | xargs -0 "$HOOK_DIR/comment-budget.sh")
  fi
  while IFS= read -r f; do
    if (cd "$ROOT" && git rev-parse --verify -q HEAD >/dev/null && git ls-files --error-unmatch "$f" >/dev/null 2>&1); then
      ADDED=$(cd "$ROOT" && git diff -U0 --no-color HEAD -- "$f" | grep '^+' | grep -v '^+++')
    else
      ADDED=$(cat "$f")
    fi
    grep -qE '\b(describe|it|test|context)\.only\(' <<<"$ADDED" \
      && FOCUS_OUT+="$f: added a focused test (.only) — it silently skips the rest of the suite"$'\n'
  done <<<"$ROOT_FILES"
done <<<"$ROOTS"

if [[ -z "$LINT_OUT$FORMAT_OUT$TYPE_OUT$COMMENT_OUT$FOCUS_OUT" ]]; then
  rm -f "$LIST" "$FAILS"
  exit 0
fi

# Loop cap: after MAX_BLOCKS consecutive blocked stops, let the turn end and the user take over.
N=$(($(cat "$FAILS" 2>/dev/null || echo 0) + 1))
echo "$N" >"$FAILS"
if [[ $N -gt $MAX_BLOCKS ]]; then
  rm -f "$FAILS"
  exit 0
fi

{
  [[ -n "$LINT_OUT" ]] && { echo "── eslint (not auto-fixable) ──"; tail -25 <<<"$LINT_OUT"; }
  [[ -n "$FORMAT_OUT" ]] && { echo "── prettier ──"; tail -15 <<<"$FORMAT_OUT"; }
  [[ -n "$TYPE_OUT" ]] && { echo "── typecheck ──"; echo "$TYPE_OUT"; }
  [[ -n "$FOCUS_OUT" ]] && { echo "── focused tests ──"; echo "$FOCUS_OUT"; }
  [[ -n "$COMMENT_OUT" ]] && {
    echo "── code comments ──"
    head -20 <<<"$COMMENT_OUT"
    echo "Rewrite or delete these: keep only what the delete test saves — a decision plus its rejected alternative, a landmine, an invariant the types can't express, or a link to a source of truth. Notes about how the work was done go in the PR description. Full rule: ~/.claude/rules/code.md."
  }
  echo "Verification failed for this turn's edits (attempt $N/$MAX_BLOCKS). Fix the cause; if an error is pre-existing and outside this task, say so to the user instead of working around it."
} >&2
exit 2
