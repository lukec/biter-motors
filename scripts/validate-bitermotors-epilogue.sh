#!/usr/bin/env bash
set -euo pipefail
# Full qualification never silently falls back to the headless mechanical route.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BITERMOTORS_VALIDATE_EPILOGUE=1
export BITERMOTORS_EPILOGUE_SINGLE_PLAYER="${BITERMOTORS_EPILOGUE_SINGLE_PLAYER:-0}"
case "${1:-}" in
  --single-player) export BITERMOTORS_EPILOGUE_SINGLE_PLAYER=1; shift ;;
  --full) export BITERMOTORS_EPILOGUE_SINGLE_PLAYER=0; shift ;;
esac
if (( $# != 0 )); then
  printf 'Usage: %s [--single-player|--full]\n' "$0" >&2
  exit 2
fi
exec bash "$repo_root/scripts/validate-bitermotors-finale.sh" "$@"
