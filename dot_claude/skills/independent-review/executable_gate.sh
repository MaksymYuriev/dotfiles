#!/usr/bin/env bash
# Routes verified findings. Auto-fix only: CONFIRMED + correctness + quoted code is on an added line of diff.patch.
# A finding inside a hunk the scope lens flagged goes to the human: fixing it would entrench the out-of-scope change.
# Everything else goes to human.json with a reason; REFUTED goes to refuted.json. Anchors on the quote, not on
# line numbers, because reviewers report lines off by one.
# Usage: gate.sh <run-dir>   (reads diff.patch, findings.json, verdicts.json, scope.json; writes fix/human/refuted.json)
set -euo pipefail
RUN=${1:?usage: gate.sh <run-dir>}
for f in diff.patch findings.json verdicts.json; do
  [[ -f "$RUN/$f" ]] || { echo "gate: missing $RUN/$f" >&2; exit 2; }
done
[[ -f "$RUN/scope.json" ]] || echo '{"skipped":"scope lens did not run"}' >"$RUN/scope.json"

awk '
  /^diff --git / { hdr = 1; file = ""; next }
  hdr && /^\+\+\+ / { file = ($2 == "/dev/null") ? "" : substr($2, 3); next }
  /^@@/ { hdr = 0; hunk++; next }
  !hdr && file != "" && /^\+/ { print file "\t" hunk "\t" substr($0, 2) }
' "$RUN/diff.patch" |
  jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {file: .[0], hunk: (.[1] | tonumber), text: (.[2:] | join("\t"))})
            | group_by(.file) | map({key: .[0].file, value: map({hunk, text})}) | from_entries' >"$RUN/added.json"

jq -n \
  --slurpfile findings "$RUN/findings.json" \
  --slurpfile verdicts "$RUN/verdicts.json" \
  --slurpfile added "$RUN/added.json" \
  --slurpfile scope "$RUN/scope.json" '
  def trim: gsub("^\\s+|\\s+$"; "");
  def qlines($quote): $quote // "" | split("\n") | map(trim) | map(select(length > 0));
  def in_diff($file; $quote):
    qlines($quote) as $q | ($added[0][$file] // [] | map(.text | trim)) as $lines
    | ($q | length) > 0 and all($q[]; . as $l | any($lines[]; contains($l)));
  def hunks($file; $quote):
    qlines($quote) as $q | [$added[0][$file] // [] | .[] | select((.text | trim) as $t | any($q[]; . as $l | $t | contains($l))) | .hunk] | unique;
  def oos_hunks: [$scope[0].out_of_scope // [] | .[] | . as $s | hunks($s.file; $s.quote)[] | "\($s.file)#\(.)"] | unique;
  def in_oos($file; $quote): oos_hunks as $o | any(hunks($file; $quote)[]; "\($file)#\(.)" as $k | $o | index($k) != null);
  def route($f; $vs):
    if ($vs | length) != 1 then {reason: "unverified"}
    else $vs[0] as $v
      | if $v.verdict == "REFUTED" then {reason: "refuted"}
        elif $v.verdict == "PLAUSIBLE" then {reason: "plausible"}
        elif $v.verdict != "CONFIRMED" then {reason: "unverified"}
        elif $v.kind != "correctness" then {reason: "non-correctness"}
        elif in_diff($v.file // $f.file; $v.quote) | not then {reason: "outside-diff"}
        elif in_oos($v.file // $f.file; $v.quote) then {reason: "in-out-of-scope-change"}
        else {reason: "fix"} end
      | . + {verdict: $v.verdict, quote: $v.quote, evidence: $v.evidence, file: ($v.file // $f.file), line: ($v.line // $f.line)}
    end;
  ($findings[0] | map(. as $f | ($verdicts[0] | map(select(.id == $f.id))) as $vs | $f + route($f; $vs))) as $routed
  | ($scope[0].out_of_scope // [] | map({file, quote, detail: .reason, reason: "scope"})) as $scope_items
  | ($scope[0].unmet // [] | map({criterion, detail: .reason, reason: "unmet-criterion"})) as $unmet
  | {
      fix: ($routed | map(select(.reason == "fix"))),
      refuted: ($routed | map(select(.reason == "refuted"))),
      human: (($routed | map(select(.reason != "fix" and .reason != "refuted"))) + $scope_items + $unmet)
    }' >"$RUN/gate.json"

jq '.fix' "$RUN/gate.json" >"$RUN/fix.json"
jq '.human' "$RUN/gate.json" >"$RUN/human.json"
jq '.refuted' "$RUN/gate.json" >"$RUN/refuted.json"
jq -r '"gate: \(.fix | length) to fix, \(.human | length) for the human, \(.refuted | length) refuted"' "$RUN/gate.json"
