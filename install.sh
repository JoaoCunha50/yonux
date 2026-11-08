#!/usr/bin/env bash
# Apply this clone with `yonux dev-apply`: builds yonux and yonux-ipc into
# ~/.local/bin, copies hypr/ and quickshell/yonux/ into ~/.config, materializes
# Matugen, and records this clone as the source. Needs Go; no installed yonux.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v go >/dev/null || { echo "go is required to apply yonux" >&2; exit 1; }
cd "$repo/yonux/cli"
exec go run ./cmd dev-apply --from "$repo"
