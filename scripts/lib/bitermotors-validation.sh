#!/usr/bin/env bash

bitermotors_resolve_source() {
  local metadata
  bitermotors_repo_root="$1"
  metadata="$(python3 "$bitermotors_repo_root/scripts/validation_support.py" source --repo "$bitermotors_repo_root")" || return
  IFS=$'\t' read -r bitermotors_mod_source bitermotors_mod_version <<< "$metadata"
}

bitermotors_stage_mod() {
  local mods="$1"
  if [[ -n "${BITERMOTORS_MOD_ARCHIVE:-}" ]]; then
    python3 "$bitermotors_repo_root/scripts/check-bitermotors-release.py" \
      "$BITERMOTORS_MOD_ARCHIVE" --source "$bitermotors_mod_source" \
      --require-source-match || return
    cp "$BITERMOTORS_MOD_ARCHIVE" "$mods/bitermotors_${bitermotors_mod_version}.zip"
  else
    ln -sfn "$bitermotors_mod_source" "$mods/bitermotors_${bitermotors_mod_version}"
  fi
}

bitermotors_check_log() {
  python3 "$bitermotors_repo_root/scripts/validation_support.py" log "$@"
}
