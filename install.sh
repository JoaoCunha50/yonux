#!/usr/bin/env bash
# Link this repo into place:
#   ~/.config/hypr              -> yonux/hypr/
#   ~/.config/quickshell/yonux  -> yonux/shell/quickshell/ (run it with `qs -c yonux`)
# An existing non-symlink target is moved aside to <name>.bak-<timestamp>.
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
