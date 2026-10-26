#!/usr/bin/env bash
# Independent review, steps 1-5: snapshot, /code-review finders, one verifier per finding, scope lens,
# optional /security-review, gate. Every reviewer is a fresh claude -p process that never sees the author's session.
# Usage: run.sh [--brief <file>] [--security] [--base <ref>]   The last line of stdout is the run directory.
set -euo pipefail
H=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$H/lib.sh"

BRIEF= SECURITY=0 BASE=
while (($#)); do
  case $1 in
    --brief) BRIEF=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); shift 2 ;;
    --security) SECURITY=1; shift ;;
    --base) BASE=$2; shift 2 ;;
    *) echo "run.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done
[[ -z $BRIEF || -f $BRIEF ]] || { echo "run.sh: brief not found: $BRIEF" >&2; exit 2; }

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

untracked=$(git ls-files --others --exclude-standard)
if [[ -n $untracked ]]; then
  {
    echo "run.sh: untracked files are invisible to git diff and /code-review:"
    sed 's/^/  /' <<<"$untracked"
    echo "Mark the ones that belong to the task with 'git add -N <file>', or ignore the rest, then rerun."
  } >&2
  exit 2
fi

if [[ -z $BASE ]]; then
  for ref in origin/HEAD origin/main main origin/master master; do
    BASE=$(git merge-base HEAD "$ref" 2>/dev/null) && break
  done
fi
[[ -n $BASE ]] || { echo "run.sh: no base found; pass --base <ref>" >&2; exit 2; }

RUN="${TMPDIR:-/tmp}/independent-review/$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD)"
mkdir -p "$RUN/verdicts"
[[ -n "$(git diff --name-only "$BASE")" ]] || { echo "run.sh: nothing to review against $BASE" >&2; exit 3; }
# -w: a legacy line that the change only re-indented must not count as changed, or the gate would allow a drive-by fix.
git diff --no-color -w "$BASE" >"$RUN/diff.patch"

SNAPSHOT=$(GIT_INDEX_FILE="$RUN/snapshot.index" sh -c 'git read-tree HEAD && git add -A && git write-tree')
jq -n --arg root "$ROOT" --arg base "$BASE" --arg snapshot "$SNAPSHOT" --arg brief "$BRIEF" \
  --argjson security "$SECURITY" --arg started "$(date +%s)" \
  '{root: $root, base: $base, snapshot: $snapshot, brief: $brief, security: ($security == 1), started: ($started | tonumber)}' \
  >"$RUN/meta.json"
echo "run: $RUN"
echo "base: $BASE · files: $(git diff --name-only "$BASE" | wc -l | tr -d ' ')"

echo "review: /code-review high (finders)"
headless "/code-review high --max-findings all" "$RUN/review.raw.json" 5 ||
  { echo "run.sh: /code-review failed, see $RUN/review.raw.json" >&2; exit 1; }
jq '.result | capture("```(json)?\\s*(?<j>\\[[\\s\\S]*\\])\\s*```").j | fromjson
    | to_entries | map(.value + {id: "F\(.key + 1)"})' "$RUN/review.raw.json" >"$RUN/findings.json" ||
  { echo "run.sh: no JSON findings block in /code-review output, see $RUN/review.raw.json" >&2; exit 1; }

VERDICT_SCHEMA='{"type":"object","additionalProperties":false,
  "required":["verdict","kind","file","line","quote","evidence"],
  "properties":{"verdict":{"type":"string","enum":["CONFIRMED","PLAUSIBLE","REFUTED"]},
    "kind":{"type":"string","enum":["correctness","cleanup"]},
    "file":{"type":"string"},"line":{"type":"integer"},"quote":{"type":"string"},"evidence":{"type":"string"}}}'

verify_one() {
  local id=$1 finding
  finding=$(jq -c --arg id "$id" '.[] | select(.id == $id) | del(.id)' "$RUN/findings.json")
  if headless "$(cat "$H/prompts/verify.md")

Base: $BASE

Candidate:
$finding" "$RUN/verdicts/$id.raw.json" 1 "$VERDICT_SCHEMA"; then
    jq --arg id "$id" '.structured_output + {id: $id}' "$RUN/verdicts/$id.raw.json" >"$RUN/verdicts/$id.json"
  fi
}

ids=($(jq -r '.[].id' "$RUN/findings.json"))
echo "verify: ${#ids[@]} findings, one verifier each"
for ((i = 0; i < ${#ids[@]}; i += 4)); do
  for id in "${ids[@]:i:4}"; do verify_one "$id" & done
  wait
done
shopt -s nullglob
verdict_files=("$RUN"/verdicts/F*[0-9].json)
jq -s '.' "${verdict_files[@]}" /dev/null >"$RUN/verdicts.json"
missing=$((${#ids[@]} - ${#verdict_files[@]}))
((missing == 0)) || echo "verify: $missing verifier(s) failed; those findings go to the human as unverified" >&2

SCOPE_SCHEMA='{"type":"object","additionalProperties":false,"required":["out_of_scope","unmet"],
  "properties":{"out_of_scope":{"type":"array","items":{"type":"object","additionalProperties":false,
      "required":["file","quote","reason"],"properties":{"file":{"type":"string"},"quote":{"type":"string"},"reason":{"type":"string"}}}},
    "unmet":{"type":"array","items":{"type":"object","additionalProperties":false,
      "required":["criterion","reason"],"properties":{"criterion":{"type":"string"},"reason":{"type":"string"}}}}}}'

if [[ -z $BRIEF ]]; then
  echo '{"skipped":"no --brief given"}' >"$RUN/scope.json"
else
  echo "scope: checking against $BRIEF"
  if headless "$(cat "$H/prompts/scope.md")

Base: $BASE

Brief:
$(cat "$BRIEF")" "$RUN/scope.raw.json" 2 "$SCOPE_SCHEMA"; then
    jq '.structured_output' "$RUN/scope.raw.json" >"$RUN/scope.json"
  else
    echo "{\"skipped\":\"scope lens failed, see $RUN/scope.raw.json\"}" >"$RUN/scope.json"
  fi
fi

if ((SECURITY)); then
  echo "security: /security-review"
  if headless "/security-review" "$RUN/security.raw.json" 3; then
    jq -r '.result' "$RUN/security.raw.json" >"$RUN/security.md"
  else
    echo "security-review failed, see $RUN/security.raw.json" >"$RUN/security.md"
  fi
fi

"$H/gate.sh" "$RUN"
echo "$RUN"
