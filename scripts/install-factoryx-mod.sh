#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/mod/factoryx_0.1.0"
client_mods_dir="${FACTORIO_CLIENT_MODS_DIR:-${FACTORIO_MODS_DIR:-$HOME/Library/Application Support/factorio/mods}}"
server_mods_dir="${FACTORIO_SERVER_MODS_DIR:-}"

link_factoryx() {
  local mods_dir="$1"
  local target_dir="$mods_dir/factoryx_0.1.0"
  local mod_list="$mods_dir/mod-list.json"

  mkdir -p "$mods_dir"
  if [[ -e "$target_dir" && ! -L "$target_dir" ]]; then
    echo "Refusing to replace non-symlink FactoryX install: $target_dir" >&2
    exit 2
  fi
  ln -sfn "$source_dir" "$target_dir"

  if [[ -f "$mod_list" ]]; then
    if ! command -v jq >/dev/null 2>&1; then
      echo "jq is required to update $mod_list" >&2
      exit 1
    fi
    local tmp_mod_list
    tmp_mod_list="$(mktemp "$mods_dir/mod-list.json.XXXXXX")"
    jq '.mods = ([.mods[] | select(.name != "factoryx")] + [{"name": "factoryx", "enabled": true}])' \
      "$mod_list" >"$tmp_mod_list"
    mv "$tmp_mod_list" "$mod_list"
  fi

  echo "$target_dir -> $source_dir"
}

echo "Linked FactoryX development mod:"
link_factoryx "$client_mods_dir"
if [[ -n "$server_mods_dir" && "$server_mods_dir" != "$client_mods_dir" ]]; then
  link_factoryx "$server_mods_dir"
fi
