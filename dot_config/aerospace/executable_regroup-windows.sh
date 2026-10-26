#!/bin/bash
# Re-apply the on-window-detected app -> workspace rules from .aerospace.toml to windows that already exist.
set -euo pipefail
PATH="/opt/homebrew/bin:$PATH"

config="$HOME/.aerospace.toml"
rules=$(awk -F"'" '
  /^\[\[on-window-detected\]\]/ { app = "" }
  /^if\.app-id *=/ { app = $2 }
  /^run *= *.move-node-to-workspace / && app != "" { split($2, a, " "); print app, a[2] }
' "$config")

aerospace list-windows --all --format '%{window-id} %{app-bundle-id} %{workspace}' |
  while read -r id app ws; do
    target=$(awk -v app="$app" '$1 == app { print $2; exit }' <<<"$rules")
    if [[ -n $target && $target != "$ws" ]]; then
      ${DRY_RUN:+echo} aerospace move-node-to-workspace --window-id "$id" "$target"
    fi
  done
