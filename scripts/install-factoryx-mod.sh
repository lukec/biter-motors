#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/mod/factoryx_0.1.0"
mods_dir="$HOME/Library/Application Support/factorio/mods"
target_dir="$mods_dir/factoryx_0.1.0"
mod_list="$mods_dir/mod-list.json"

mkdir -p "$mods_dir"
rm -f "$target_dir"
ln -sfn "$source_dir" "$target_dir"

if [[ -f "$mod_list" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to update $mod_list" >&2
    exit 1
  fi
  tmp_mod_list="$(mktemp "$mods_dir/mod-list.json.XXXXXX")"
  jq '.mods = ([.mods[] | select(.name != "factoryx")] + [{"name": "factoryx", "enabled": true}])' \
    "$mod_list" >"$tmp_mod_list"
  mv "$tmp_mod_list" "$mod_list"
fi

echo "Installed FactoryX mod at:"
echo "$target_dir"
if [[ -f "$mod_list" ]]; then
  echo "Enabled factoryx in:"
  echo "$mod_list"
fi
