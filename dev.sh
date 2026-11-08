#!/usr/bin/env bash
# Run the shell straight from this clone, in the foreground with its log on the
# terminal and QML hot reload. It installs and records nothing: yonux and
# yonux-ipc are built into a temp dir, and Matugen is composed there from this
# clone and your real user_preferences.
#
# Not a sandbox: it uses your real preferences and session, and what you change
# in it (settings, shortcuts, theme) stays. The installed shell is stopped while
# it runs and started again on exit.
#
# Go changes: Ctrl+C and run again. Stop it from another terminal with
#   qs kill -p <clone>/yonux/shell/quickshell
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -e $repo/.git ]] || { echo "dev.sh runs from a git clone" >&2; exit 1; }
command -v go >/dev/null || { echo "go is required to run the dev shell" >&2; exit 1; }
shell="$repo/yonux/shell/quickshell"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

if qs list -p "$shell" -j 2>/dev/null | grep -q '"pid"'; then
  echo "a dev shell from this clone is already running" >&2
  exit 1
fi

tmp="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/yonux-dev.XXXXXX")"
resume=0
cleanup() {
  qs kill -p "$shell" >/dev/null 2>&1 || true
  rm -rf "$tmp"
  if ((resume)); then
    PATH="$HOME/.local/bin:$PATH" QT_QPA_PLATFORMTHEME=xdgdesktopportal qs -c yonux -d >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

(cd "$repo/yonux/cli" && go build -o "$tmp/bin/yonux" ./cmd)
(cd "$repo/yonux/shell/ipc" && go build -o "$tmp/bin/yonux-ipc" ./cmd)

mkdir -p "$tmp/config/yonux"
if [[ -d $config/yonux/user_preferences ]]; then
  ln -s "$config/yonux/user_preferences" "$tmp/config/yonux/user_preferences"
fi
XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" YONUX_BASE="$repo/yonux" "$tmp/bin/yonux" materialize

# Only the installed shell: the dev one runs by path.
if qs kill -c yonux >/dev/null 2>&1; then resume=1; fi

PATH="$tmp/bin:$PATH" YONUX_MATUGEN_CONFIG="$tmp/config/yonux/matugen/config.toml" QT_QPA_PLATFORMTHEME=xdgdesktopportal \
  qs -n -p "$shell"
