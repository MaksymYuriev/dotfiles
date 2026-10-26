#!/usr/bin/env bash
# Independent review, step 7: one round of checks on the author's fixes. Mechanical: a fix hunk more than 10
# lines from every fixed finding is an unrequested edit. Reviewer: a fresh claude -p checks that each finding is
# addressed, that the fix lines add no new defect, and flags nearby edits no finding needed. Writes recheck-human.json.
# Usage: recheck.sh <run-dir>
set -euo pipefail
H=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$H/lib.sh"
RUN=${1:?usage: recheck.sh <run-dir>}
cd "$(jq -r .root "$RUN/meta.json")"
SNAPSHOT=$(jq -r .snapshot "$RUN/meta.json")

# -U0 keeps each edit in its own hunk; with context, an extra edit merges into the hunk of a real fix.
git diff --no-color -U0 "$SNAPSHOT" >"$RUN/fix.patch"
if [[ ! -s $RUN/fix.patch ]]; then
  jq 'map(. + {reason: "not-fixed"})' "$RUN/fix.json" >"$RUN/recheck-human.json"
  echo '{"skipped":"no edits since the snapshot"}' >"$RUN/recheck.json"
  echo "recheck: no edits since the snapshot"
  exit 0
fi

: >"$RUN/fix-lines.tsv"
while IFS=$'\t' read -r file quote; do
  line=$(git show "$SNAPSHOT:$file" 2>/dev/null | awk -v q="$quote" '
    { s = $0; gsub(/^[ \t]+|[ \t]+$/, "", s) } index(s, q) { print NR; exit }')
  printf '%s\t%s\n' "$file" "${line:-0}" >>"$RUN/fix-lines.tsv"
done < <(jq -r '.[] | [.file, (.quote | split("\n") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)) | .[0] // "")] | @tsv' "$RUN/fix.json")

awk -v pad=10 '
  NR == FNR { split($0, t, "\t"); lines[t[1]] = lines[t[1]] " " t[2]; next }
  /^diff --git / { flush(); hdr = 1; file = ""; next }
  hdr && /^--- / { old = ($2 == "/dev/null") ? "" : substr($2, 3); next }
  hdr && /^\+\+\+ / { file = ($2 == "/dev/null") ? old : substr($2, 3); next }
  /^@@/ {
    hdr = 0; flush()
    split($2, o, ","); start = -o[1]; count = (o[2] == "") ? 1 : o[2]
    stop = start + (count > 0 ? count : 1) - 1; first = ""; removed = ""; open = 1; next
  }
  open && first == "" && /^\+/ { first = substr($0, 2) }
  open && removed == "" && /^-/ { removed = substr($0, 2) }
  END { flush() }
  function flush(   n, ls, i, ok) {
    if (!open) return
    ok = 0; n = split(lines[file], ls, " ")
    for (i = 1; i <= n; i++) if (ls[i] > 0 && ls[i] >= start - pad && ls[i] <= stop + pad) ok = 1
    if (first == "") first = removed
    if (!ok) { gsub(/\\/, "\\\\", first); gsub(/"/, "\\\"", first); gsub(/\t/, " ", first)
      printf "{\"file\":\"%s\",\"line\":%d,\"quote\":\"%s\",\"reason\":\"unrequested-edit\"}\n", file, start, first }
    open = 0
  }
' "$RUN/fix-lines.tsv" "$RUN/fix.patch" | jq -s '.' >"$RUN/unrequested.json"

RECHECK_SCHEMA='{"type":"object","additionalProperties":false,"required":["results","new_issues","unrequested_edits"],
  "properties":{"results":{"type":"array","items":{"type":"object","additionalProperties":false,
      "required":["id","addressed","evidence"],"properties":{"id":{"type":"string"},"addressed":{"type":"boolean"},"evidence":{"type":"string"}}}},
    "new_issues":{"type":"array","items":{"type":"object","additionalProperties":false,
      "required":["file","line","quote","summary","failure_scenario"],
      "properties":{"file":{"type":"string"},"line":{"type":"integer"},"quote":{"type":"string"},
        "summary":{"type":"string"},"failure_scenario":{"type":"string"}}}},
    "unrequested_edits":{"type":"array","items":{"type":"object","additionalProperties":false,
      "required":["file","line","quote","detail"],"properties":{"file":{"type":"string"},"line":{"type":"integer"},
        "quote":{"type":"string"},"detail":{"type":"string"}}}}}}'

echo "recheck: reviewing the fix diff"
if headless "$(cat "$H/prompts/recheck.md")

Snapshot: $SNAPSHOT

Findings that were supposed to be fixed:
$(jq -c 'map({id, file, line, summary, failure_scenario})' "$RUN/fix.json")" "$RUN/recheck.raw.json" 2 "$RECHECK_SCHEMA"; then
  jq '.structured_output' "$RUN/recheck.raw.json" >"$RUN/recheck.json"
else
  echo "{\"skipped\":\"recheck reviewer failed, see $RUN/recheck.raw.json\"}" >"$RUN/recheck.json"
fi

jq -n --slurpfile fix "$RUN/fix.json" --slurpfile rc "$RUN/recheck.json" --slurpfile un "$RUN/unrequested.json" '
  ($rc[0].results // []) as $res
  | ($fix[0] | map(. as $f | ($res | map(select(.id == $f.id))) as $r
      | if ($rc[0].skipped // null) != null or ($r | length) != 1 then $f + {reason: "fix-unverified"}
        elif $r[0].addressed then empty
        else $f + {reason: "not-addressed", evidence: $r[0].evidence} end))
  + ($rc[0].new_issues // [] | map(. + {reason: "fix-introduced"}))
  + ([$un[0][], ($rc[0].unrequested_edits // [] | .[] | . + {reason: "unrequested-edit"})] | unique_by([.file, (.quote | gsub("^\\s+|\\s+$"; ""))]))' >"$RUN/recheck-human.json"
jq -r '"recheck: \(length) item(s) for the human"' "$RUN/recheck-human.json"
