#!/usr/bin/env bash
# Enforces the comment rules in ~/.claude/rules/code.md on lines ADDED this turn only:
# comment runs over 2 content lines, section banners, JSDoc on non-exported declarations.
# Scoped to added lines so touching a legacy file never blocks on its existing comments.
# Usage: comment-budget.sh <file>...  -> prints violations to stdout, exit 1 if any.
set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

VIOLATIONS=""

for f in "$@"; do
  [[ -f "$f" ]] || continue

  if git rev-parse --verify -q HEAD >/dev/null && git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    ADDED=$(git diff -U0 --no-color HEAD -- "$f" | awk '
      /^@@/ {
        match($0, /\+[0-9]+(,[0-9]+)?/)
        n = split(substr($0, RSTART + 1, RLENGTH - 1), p, ",")
        cnt = (n > 1 ? p[2] : 1)
        for (i = 0; i < cnt; i++) printf "%d,", p[1] + i
      }')
    [[ -z "$ADDED" ]] && continue
  else
    ADDED=all
  fi

  OUT=$(awk -v added="$ADDED" -v file="$f" '
    BEGIN {
      all = (added == "all")
      n = split(added, a, ",")
      for (i = 1; i <= n; i++) if (a[i] != "") add[a[i] + 0] = 1
    }
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    # A line carrying prose; bare /**, *, */ delimiters do not count against the budget.
    function contentful(s,   r) {
      r = s
      sub(/^\/\/+/, "", r); sub(/^\/\*+/, "", r); sub(/^\*+\/?/, "", r)
      sub(/\*\/[[:space:]]*$/, "", r)
      gsub(/[[:space:]]/, "", r)
      return (r != "")
    }
    function is_directive(s) {
      return s ~ /^(\/\/|\/\*+)[[:space:]]*(eslint|@?ts-|tslint|prettier-ignore|biome-ignore|oxlint|istanbul ignore|c8 ignore|v8 ignore|@jsx|globals|#(region|endregion))/
    }
    function flush(next_code,   nxt) {
      if (run == 0) return
      if (touched && !directive) {
        nxt = trim(next_code)
        if (banner)
          print file ":" start ": section-divider banner — rules/code.md forbids banners"
        else if (content > 2)
          print file ":" start ": " content "-line comment — budget is 2 lines, 1 line is the target"
        else if (jsdoc && nxt !~ /^(export|declare)/ && nxt ~ /^(async|function|const|let|var|class|type|interface|enum|abstract)[[:space:]]/)
          print file ":" start ": JSDoc on a non-exported declaration — JSDoc is for exported public API only"
      }
      run = 0
    }
    {
      t = trim($0)
      if (t ~ /^(\/\/|\/\*|\*)/) {
        if (run == 0) {
          start = NR; content = 0; touched = 0; banner = 0
          jsdoc = (t ~ /^\/\*\*/); directive = is_directive(t)
        }
        run++
        if (contentful(t)) content++
        if (all || (NR in add)) touched = 1
        if (t ~ /(====|----|────|━━━━|####|\*\*\*\*)/) banner = 1
        next
      }
      flush($0)
    }
    END { flush("") }
  ' "$f")

  [[ -n "$OUT" ]] && VIOLATIONS+="$OUT"$'\n'
done

[[ -z "$VIOLATIONS" ]] && exit 0
printf '%s' "$VIOLATIONS"
exit 1
