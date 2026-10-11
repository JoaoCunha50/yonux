# yonux-shell

- `quickshell/`: the Quickshell desktop shell (bar, launcher, wallpaper, matugen theming)
- `hypr/`: the Hyprland (Lua) config it runs on

## Install

```sh
./install.sh   # symlinks hypr/ -> ~/.config/hypr and quickshell/ -> ~/.config/quickshell/yonux
```

Existing non-symlink targets are moved to `*.bak-<timestamp>`. Machine-local Hyprland
overrides go in `hypr/user.lua` (gitignored, loaded last).

During development, run the shell straight from the repo with `qs -p quickshell/shell.qml`.

## Theming

On every wallpaper change, `quickshell/services/Matugen.qml` runs matugen with
`quickshell/matugen/config.toml`, which themes the shell itself and renders each
template in `quickshell/matugen/templates/` to its output path:

| Template | Output | post_hook |
| --- | --- | --- |
| `hypr-colors.lua` | `~/.cache/yonux/hypr-colors.lua` (loaded by `hypr/modules/decoration.lua`) | `hyprctl eval` applies the borders live |
| `fish-colors.fish` | `~/.config/fish/conf.d/zz-yonux-colors.fish` | bumps a fish universal variable so open shells re-source it |
| `hyprlock-colors.conf` | `~/.cache/yonux/hyprlock-colors.conf` (sourced by `hypr/hyprlock.conf`) | none, hyprlock reads it on every lock |
| `ghostty-colors` | `~/.config/ghostty/yonux-colors` (included by the ghostty config) | `SIGUSR2` makes running ghostty reload its config |

To theme another app, add a template and a `[templates.<name>]` entry to the config.

Set the wallpaper with:

```sh
qs -c yonux ipc call wallpaper set /path/to/image.png
```

## NixOS

`nix/yonux.nix` (exported as `nixosModules.default`) installs everything the
config calls: clipboard (cliphist + fuzzel), screenshots (grim + slurp),
hyprlock + hypridle, media and brightness tools, nautilus, hyprpicker,
hyprpolkitagent, the cursor and GTK theme, gnome-keyring, bluetooth, upower,
power-profiles-daemon, gamescope and gamemode. Import it in `/etc/nixos`:

```nix
# flake.nix, inputs
yonux-shell = {
  url = "path:/home/joaocunha50/dev/yonux-shell";
  inputs.nixpkgs.follows = "nixpkgs";
};

# flake.nix, modules
yonux-shell.nixosModules.default
```

The `path:` input is a locked copy, so after changing anything in the repo run
`nix flake update yonux-shell` in `/etc/nixos` before rebuilding.

## Stand-ins

Until yonux has its own, these come from outside the shell:

- lock screen: hyprlock (`hypr/hyprlock.conf`), idle via hypridle (`hypr/hypridle.conf`: lock at 10 min, screen off at 11)

## Keybinds

| Keys | Action |
| --- | --- |
| Super + Return / B / E | ghostty / zen / nautilus |
| Super + Space | launcher |
| Super + Q | close window |
| Super + F | maximize (keeps bar and gaps) |
| Super + Shift + F | real fullscreen |
| Super + Ctrl + F | fake fullscreen (app thinks it is fullscreen, stays tiled) |
| Super + A | float centred at 1000x660 / tile back |
| Super + Shift + P | pin floating window |
| Super + T | toggle split direction |
| Super + R | resize mode (arrows / hjkl, Esc exits) |
| Super + arrows | focus |
| Super + Shift + arrows | move window |
| Super + Ctrl + arrows | resize window |
| Super + LMB / RMB drag | move / resize window |
| Super + 1..0 | go to workspace |
| Super + Shift + 1..0 | move window to workspace and follow |
| Super + Alt + 1..0 | move window to workspace silently |
| Super + scroll | previous / next workspace |
| Super + D / M | chat (vesktop) / music (Spotify) special workspace |
| Super + H / Shift + H | show scratchpad / send window to scratchpad |
| Super + G | game mode |
| Super + Shift + C | colour picker |
| Super + V | clipboard history |
| Super + L | lock |
| Super + Shift + S / Super + S | screenshot an area / the focused monitor (clipboard + ~/Pictures/Screenshots) |
| Super + Shift + Escape | exit Hyprland |
