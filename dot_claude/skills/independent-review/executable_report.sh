#!/usr/bin/env bash
# Prints the independent-review report for a run directory. Run it after run.sh, and again after recheck.sh.
# Usage: report.sh <run-dir>
set -euo pipefail
RUN=${1:?usage: report.sh <run-dir>}
shopt -s nullglob
raws=("$RUN"/*.raw.json "$RUN"/verdicts/*.raw.json)
ROOT=$(jq -r .root "$RUN/meta.json")
BASE=$(jq -r .base "$RUN/meta.json")
files=$(git -C "$ROOT" diff --name-only "$BASE" | wc -l | tr -d ' ')
recheck=$( [[ -f $RUN/recheck-human.json ]] && cat "$RUN/recheck-human.json" || echo null)
security=$( [[ -f $RUN/security.md ]] && echo "$RUN/security.md" || echo "")

jq -n -r \
  --slurpfile meta "$RUN/meta.json" \
  --slurpfile fix "$RUN/fix.json" \
  --slurpfile human "$RUN/human.json" \
  --slurpfile refuted "$RUN/refuted.json" \
  --slurpfile scope "$RUN/scope.json" \
  --argjson recheck "$recheck" \
  --argjson usage "$(jq -s 'map({cost: (.total_cost_usd // 0), ms: (.duration_ms // 0)})' "${raws[@]}" /dev/null)" \
  --arg files "$files" --arg run "$RUN" --arg security "$security" '
  def loc: if .criterion then "criterion: \(.criterion)" else "\(.file // "?"):\(.line // "?")" end;
  def text: .short_summary // .summary // .detail // "";
  def row: "    \(loc)  \(text)\(if .detail and (.summary // .short_summary) then " — \(.detail)" else "" end)";
  ($meta[0]) as $m
  | ($human[0] + ($recheck // [])) as $all
  | ($usage | map(.cost) | add // 0) as $cost
  | ($usage | map(.ms) | add // 0) as $ms
  | [
      "Independent review · base \($m.base[0:7]) · \($files) files · \($ms / 60000 * 10 | round / 10) reviewer-min · $\($cost * 100 | round / 100) API-equivalent",
      "",
      "Fixed automatically (\($fix[0] | length))"
        + (if $recheck == null then " — not re-checked yet: run recheck.sh"
           elif ($recheck | length) == 0 then " — fix diff re-reviewed: clean"
           else " — fix diff re-reviewed: \($recheck | length) item(s) below" end),
      ($fix[0][] | "  ✓ \(loc)  \(text)"),
      "",
      "For you (\($all | length))\(if $recheck != null then " — scope and criteria items describe the code before the fixes" else "" end)",
      ($all | group_by(.reason)[] | "  \(.[0].reason)", (.[] | row)),
      "",
      "Refuted by verifiers (\($refuted[0] | length))",
      ($refuted[0][] | "    \(loc)  \(text)"),
      "",
      "Not run: " + ([ (if $scope[0].skipped then "scope (\($scope[0].skipped))" else empty end),
                      (if $m.security then empty else "security (no --security)" end) ]
                    | if length == 0 then "nothing" else join(", ") end),
      (if $security != "" then "Security review (read it yourself): \($security)" else empty end),
      "Raw: \($run)"
    ] | .[]'
