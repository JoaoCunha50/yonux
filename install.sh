#!/usr/bin/env bash
# Link this repo into place:
#   ~/.config/hypr              -> yonux/hypr/
#   ~/.config/quickshell/yonux  -> yonux/shell/quickshell/

# An existing non-symlink target is moved aside to <name>.bak-<timestamp>.
# Then it builds `yonux` and `yonux-ipc` into ~/.local/bin, and `yonux materialize`
# links each file of yonux/shell/matugen/ into ~/.config/yonux/matugen/.
# files in ~/.config/yonux/user_preferences/matugen/ are copied over them instead.

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="$(date +%Y%m%d-%H%M%S)"

link() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst ]]; then
    rm "$dst"
  elif [[ -e $dst ]]; then
    mv "$dst" "$dst.bak-$stamp"
    echo "backed up $dst -> $dst.bak-$stamp"
  fi
  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

link "$repo/yonux/hypr" "$config/hypr"
link "$repo/yonux/shell/quickshell" "$config/quickshell/yonux"

command -v go >/dev/null || { echo "go is required to build yonux and yonux-ipc" >&2; exit 1; }
bindir="$HOME/.local/bin"
mkdir -p "$bindir"
(cd "$repo/yonux/cli" && go build -o "$bindir/yonux" ./cmd)
(cd "$repo/yonux/shell/ipc" && go build -o "$bindir/yonux-ipc" ./cmd)
echo "built $bindir/yonux $bindir/yonux-ipc"

YONUX_BASE="$repo/yonux" "$bindir/yonux" materialize
echo "materialized ~/.config/yonux/matugen"
