#!/usr/bin/env bash
# Regression test for gate.sh: no network, no claude calls. Each routing rule has a case that must land in
# exactly one bucket, so a broken rule fails here.
# Usage: ~/.claude/skills/independent-review/test.sh   Exit 1 if any case fails.
set -u
H=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
R=$(mktemp -d "${TMPDIR:-/tmp}/independent-review-test.XXXXXX")
FAILED=0

cat >"$R/diff.patch" <<'EOF'
diff --git a/src/cart.ts b/src/cart.ts
index 1111111..2222222 100644
--- a/src/cart.ts
+++ b/src/cart.ts
@@ -3,6 +3,7 @@ export function total(items: Item[]): number {
   let sum = 0;
-  for (let i = 0; i < items.length; i++) {
+  for (let i = 0; i <= items.length; i++) {
+    const d = items[i].discount || 0.1;
     sum += items[i].price * items[i].qty;
   }
   return sum;
diff --git a/src/new.ts b/src/new.ts
new file mode 100644
--- /dev/null
+++ b/src/new.ts
@@ -0,0 +1 @@
+export const ++counter = 1;
diff --git a/src/api.ts b/src/api.ts
--- a/src/api.ts
+++ b/src/api.ts
@@ -1,2 +1,3 @@
+const retries = retry(3);
+const url = `/api?q=${q}`;
 export {};
EOF

f() { printf '{"id":"%s","file":"%s","line":%s,"summary":"s %s","failure_scenario":"x"}' "$1" "$2" "$3" "$1"; }
v() { printf '{"id":"%s","verdict":"%s","kind":"%s","file":"%s","line":%s,"quote":"%s","evidence":"e"}' "$1" "$2" "$3" "$4" "$5" "$6"; }

{
  echo '['
  f FIX src/cart.ts 4; echo ,
  f FIXWRONGLINE src/cart.ts 99; echo ,
  f FIXNEWFILE src/new.ts 1; echo ,
  f PLAUS src/cart.ts 5; echo ,
  f CLEAN src/cart.ts 5; echo ,
  f LEGACY src/cart.ts 6; echo ,
  f EMPTYQ src/cart.ts 4; echo ,
  f REF src/cart.ts 4; echo ,
  f NOVERDICT src/cart.ts 4; echo ,
  f DUPVERDICT src/cart.ts 4; echo ,
  f BADVERDICT src/cart.ts 4; echo ,
  f INOOS src/api.ts 2
  echo ']'
} >"$R/findings.json"
{
  echo '['
  v FIX CONFIRMED correctness src/cart.ts 4 'for (let i = 0; i <= items.length; i++) {'; echo ,
  v FIXWRONGLINE CONFIRMED correctness src/cart.ts 7 'const d = items[i].discount || 0.1;'; echo ,
  v FIXNEWFILE CONFIRMED correctness src/new.ts 1 'export const ++counter = 1;'; echo ,
  v PLAUS PLAUSIBLE correctness src/cart.ts 5 'const d = items[i].discount || 0.1;'; echo ,
  v CLEAN CONFIRMED cleanup src/cart.ts 5 'const d = items[i].discount || 0.1;'; echo ,
  v LEGACY CONFIRMED correctness src/cart.ts 6 'sum += items[i].price * items[i].qty;'; echo ,
  v EMPTYQ CONFIRMED correctness src/cart.ts 4 '  '; echo ,
  v REF REFUTED correctness src/cart.ts 4 'for (let i = 0; i <= items.length; i++) {'; echo ,
  v DUPVERDICT CONFIRMED correctness src/cart.ts 4 'for (let i = 0; i <= items.length; i++) {'; echo ,
  v DUPVERDICT CONFIRMED correctness src/cart.ts 4 'for (let i = 0; i <= items.length; i++) {'; echo ,
  v BADVERDICT MAYBE correctness src/cart.ts 4 'for (let i = 0; i <= items.length; i++) {'; echo ,
  v INOOS CONFIRMED correctness src/api.ts 2 'const url = `/api?q=${q}`;'
  echo ']'
} >"$R/verdicts.json"
echo '{"out_of_scope":[{"file":"src/api.ts","quote":"const retries = retry(3);","reason":"not in brief"}],"unmet":[{"criterion":"Enter submits","reason":"no handler"}]}' >"$R/scope.json"

if ! "$H/gate.sh" "$R" >/dev/null; then
  echo "FAIL  gate.sh exited non-zero"
  exit 1
fi

# expect <id> <bucket> [reason]
expect() {
  local got
  got=$(jq -r --arg id "$1" '[(.fix[] | select(.id == $id) | "fix:\(.reason)"),
                              (.human[] | select(.id == $id) | "human:\(.reason)"),
                              (.refuted[] | select(.id == $id) | "refuted:\(.reason)")] | join(",")' "$R/gate.json")
  if [[ "$got" == "$2:${3:-$2}" ]]; then
    echo "PASS  $1 -> $got"
  else
    echo "FAIL  $1: expected $2:${3:-$2}, got '${got}'"
    FAILED=1
  fi
}

expect FIX fix
expect FIXWRONGLINE fix
expect FIXNEWFILE fix
expect PLAUS human plausible
expect CLEAN human non-correctness
expect LEGACY human outside-diff
expect EMPTYQ human outside-diff
expect REF refuted
expect NOVERDICT human unverified
expect DUPVERDICT human unverified
expect BADVERDICT human unverified
expect INOOS human in-out-of-scope-change

for reason in scope unmet-criterion; do
  if jq -e --arg r "$reason" '[.human[] | select(.reason == $r and (.detail | length) > 0)] | length == 1' "$R/gate.json" >/dev/null; then
    echo "PASS  $reason item routed to human"
  else
    echo "FAIL  $reason item not routed to human"
    FAILED=1
  fi
done

if jq -e '[.fix[] | select(.verdict != "CONFIRMED")] | length == 0' "$R/gate.json" >/dev/null; then
  echo "PASS  no unconfirmed finding in fix"
else
  echo "FAIL  unconfirmed finding in fix"
  FAILED=1
fi

rm -f "$R/scope.json" "$R/findings.json"
if "$H/gate.sh" "$R" >/dev/null 2>&1; then
  echo "FAIL  gate.sh accepted a run without findings.json"
  FAILED=1
else
  echo "PASS  missing findings.json fails loudly"
fi

rm -rf "$R"
[[ $FAILED == 0 ]] && echo "ALL PASSED" || { echo "SOME FAILED"; exit 1; }
