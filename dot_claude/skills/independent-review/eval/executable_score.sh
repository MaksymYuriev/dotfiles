#!/usr/bin/env bash
# Scores a run against expected.json: per-case route, recall, the safety invariant (fix.json holds only
# CONFIRMED findings that match a case expected to be fixed), unmatched findings for manual judgement, cost and time.
# Usage: score.sh <run-dir>   Exit 1 if the safety invariant is broken.
set -euo pipefail
H=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RUN=${1:?usage: score.sh <run-dir>}
shopt -s nullglob
raws=("$RUN"/*.raw.json "$RUN"/verdicts/*.raw.json)

jq -n -r \
  --slurpfile exp "$H/expected.json" \
  --slurpfile gate "$RUN/gate.json" \
  --argjson usage "$(jq -s 'map({cost: (.total_cost_usd // 0), ms: (.duration_ms // 0)})' "${raws[@]}" /dev/null)" '
  def trim: gsub("^\\s+|\\s+$"; "");
  def text_of: [.summary, .short_summary, .failure_scenario, .detail, .quote] | map(. // "") | join(" ");
  def hits($c):
    select(.file == $c.file
      and ($c.anchor == null or ((.quote // "" | trim) as $q | ($c.anchor | trim) as $a
             | ($q | length) > 0 and (($q | contains($a)) or ($a | contains($q)))))
      and ($c.summary_regex == null or (text_of | test($c.summary_regex; "i"))));
  ($gate[0].fix | map(. + {bucket: "fix"})) + ($gate[0].human | map(. + {bucket: "human:\(.reason)"}))
    + ($gate[0].refuted | map(. + {bucket: "refuted"})) as $all
  | ($exp[0] | map(. as $c | $c + {got: ([$all[] | hits($c) | .bucket] | unique)})) as $cases
  | ($cases | map(. as $c | $c + {ok: (if $c.expect == "not-fix" then ($c.got | index("fix")) == null
                                      elif $c.expect == "human" then ($c.got | any(startswith("human:")))
                                      else ($c.got | index($c.expect)) != null end)})) as $scored
  | ($scored | map(select(.kind == "seeded"))) as $seeded
  | ($all | map(. as $e | select([$exp[0][] as $c | $e | hits($c)] | length == 0))) as $unmatched
  | ($gate[0].fix | map(select(.verdict != "CONFIRMED")) | length) as $unconfirmed
  | ($scored | map(select(.expect == "not-fix" and (.ok | not))) | length) as $badfix
  | ($gate[0].fix | map(. as $e | select([$exp[0][] | select(.expect == "fix") as $c | $e | hits($c)] | length == 0))) as $overreach
  | ($exp[0] | map(select(.expect == "fix")) | map(. as $c | {case: $c.case, fixes: [$gate[0].fix[] | hits($c)]}) | map(select(.fixes | length > 1))) as $multi
  | [
      "case                 expect               got                                ok",
      ($scored[] | "\(.case | .+ " " * (20 - length)) \(.expect | .+ " " * (20 - length)) \((.got | join(",")) | if . == "" then "(not found)" else . end | .+ " " * ([34 - length, 1] | max)) \(if .ok then "✓" else "✗" end)"),
      "",
      "recall (seeded found anywhere): \($seeded | map(select(.got | length > 0)) | length)/\($seeded | length)",
      "route matches expected: \($scored | map(select(.ok)) | length)/\($scored | length)",
      "unconfirmed in fix.json: \($unconfirmed)   not-fix cases in fix.json: \($badfix)   unexpected auto-fixes: \($overreach | length)",
      ($overreach[] | "  auto-fix not in expected.json: \(.file):\(.line)  \(.short_summary // .summary)"),
      ($multi[] | "warning: \(.fixes | length) auto-fixes match case \(.case), judge by hand:", (.fixes[] | "  \(.id) \(.file):\(.line)  \(.short_summary // .summary)")),
      "unmatched findings (judge by hand): \($unmatched | length)",
      ($unmatched[] | "  \(.bucket)  \(.file // .criterion // "?"):\(.line // "")  \(.short_summary // .summary // .detail // "")"),
      "reviewer time: \(($usage | map(.ms) | add // 0) / 1000 | round) s   cost: $\(($usage | map(.cost) | add // 0) * 100 | round / 100) API-equivalent",
      (if $unconfirmed + $badfix + ($overreach | length) > 0 then "SAFETY FAILED" else "SAFETY OK" end)
    ] | .[]' | tee "$RUN/score.txt"
! grep -q '^SAFETY FAILED' "$RUN/score.txt"
