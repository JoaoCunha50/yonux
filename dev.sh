#!/usr/bin/env bash
# Dev loop: run ./install.sh (re-links, rebuilds yonux and yonux-ipc from this
# checkout, materializes), then restarts the shell in the foreground so its log
# is on this terminal. Ctrl+C stops it; `qs -c yonux -d` or a new Hyprland
# session brings the normal one back.
#
#   ./dev.sh          install + restart the shell
#   ./dev.sh --build  install only, leave the running shell alone
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

"$repo/install.sh"
[[ ${1:-} == --build ]] && exit 0

qs kill -c yonux >/dev/null 2>&1 || true
PATH="$HOME/.local/bin:$PATH" QML_IMPORT_PATH="$config/quickshell" QT_QPA_PLATFORMTHEME=xdgdesktopportal \
  exec qs -c yonux
