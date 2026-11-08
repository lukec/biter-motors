#!/usr/bin/env bash
set -euo pipefail
# Both validators use the same isolated server/checkpoint protocol.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BITERMOTORS_ENDING_CASE=delivery exec bash "$repo_root/scripts/validate-bitermotors-finale.sh" "$@"
