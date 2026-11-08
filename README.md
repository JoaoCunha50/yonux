<div align="center">

# Yonux Shell

A Quickshell desktop shell and Hyprland configuration, with Material styling and wallpaper-based colours.

[Components](#components) · [Installation](#installation) · [Usage](#usage) · [Configuration](#configuration) · [FAQ](#faq)

</div>

## Components

- **Bar:** workspaces, system tray, clock, CPU, memory, disk, temperature, battery, network and audio.
- **Launcher:** search and launch desktop applications and the AppImages in `~/Applications`.
- **Control center:** audio controls, notifications and desktop toggles.
- **Notifications:** pop-up notifications and notification history.
- **Wallpaper and colours:** wallpaper background and Matugen palettes for the shell and other applications.
- **Settings:** shell appearance, bar layout and Hyprland preferences.
- **Power menu:** session and power actions; locking and idle management use Hyprlock and Hypridle.
- **Hyprland configuration:** window rules, keybindings, screenshots, clipboard history and night light.

## Installation

Yonux is developed on NixOS with Hyprland and Quickshell. The Hyprland configuration
uses the Lua API (`hyprland.lua`); it needs a Hyprland build supporting that API.

### NixOS

Add the repository to your system flake:

```nix
# inputs
yonux-shell = {
  url = "github:joaocunha50/yonux-shell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Include its module in your `nixosSystem.modules` list:

```nix
inputs.yonux-shell.nixosModules.default
```

The module installs Quickshell and the desktop utilities, enables Hyprland with
UWSM, NetworkManager, PipeWire/WirePlumber, Bluetooth, UPower, the power profiles
service, Hyprlock and Hypridle. It also configures GTK, fonts, cursors, keyring,
removable storage, AppImage support, Gamescope and GameMode. It includes Steam
cursor configuration, but does not enable Steam itself.

This is an opinionated desktop module: inspect [nix/yonux.nix](nix/yonux.nix)
before importing it into an existing system. Your login user needs membership in
`networkmanager` to manage connections without administrator authentication.

Quickshell defaults to `pkgs.quickshell`. To use a different build, set:

```nix
programs.yonux.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
```

If your system already installs that package separately, move its selection here
and remove the separate package-list entry to keep one Quickshell version.
NetworkManager and PipeWire declarations can also be centralised in this module;
remove conflicting audio or network configuration before rebuilding.

For a local checkout, replace the input URL with `path:/absolute/path/to/yonux-shell`.
After editing the checkout, update that input in your system flake before rebuilding:

```sh
sudo nix flake update yonux-shell --flake /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#YOUR_HOST
```

### CachyOS / Arch Linux package

The package recipe is kept in
[`packaging/aur/yonux-git`](packaging/aur/yonux-git). It has not been
published to the AUR; build it locally rather than assuming an AUR helper can
install it:

```sh
sudo pacman -Syu --needed base-devel git
git clone --branch development https://github.com/JoaoCunha50/yonux.git
cd yonux/packaging/aur/yonux-git
makepkg -si
yonux install
```

Run `makepkg` and `yonux install` as your regular user, not root; `makepkg -si`
requests elevation only for package operations. The recipe builds both Go
commands and installs `/usr/bin/yonux`, `/usr/bin/yonux-ipc`, and the Hyprland,
Quickshell, Matugen and portal assets under `/usr/share/yonux` from the same
`development` revision. Only Git and Go (at least 1.26.10) are additional build
dependencies beyond Arch's standard `base-devel` environment. Package installation
and upgrade hooks never write to a user's home directory.

`yonux install` composes copies into your configuration roots. Existing files
that are not yet managed are backed up under `$XDG_STATE_HOME/yonux/backups/`;
the ownership manifest records their original locations. Reapplying does not
create duplicate backups. `hypr/user.lua` and unrelated files are preserved.
After upgrading the package, run `yonux apply` to refresh the copies.

The supported package versions start at
[`hyprland` 0.57.1](https://archlinux.org/packages/extra/x86_64/hyprland/),
[`quickshell` 0.3.2](https://archlinux.org/packages/extra/x86_64/quickshell/), and
[`matugen` 4.2.0](https://archlinux.org/packages/extra/x86_64/matugen/).
The recipe includes the runtime utilities listed below, including PipeWire,
WirePlumber, `xdg-desktop-portal`, `xdg-desktop-portal-hyprland` and
`xdg-desktop-portal-gtk`. Keep both portal backends: Hyprland handles screencasting
and GTK provides file pickers; other desktop portal packages can coexist.
Enable NetworkManager and UPower, and start PipeWire and WirePlumber in your user
session using the distribution's service setup. Install the fonts and cursor
theme below separately if desired, and review the default application bindings.
UWSM is optional; a normal Hyprland session is supported.

The package supplies Hyprland and GTK portal backends. Yonux applies a
Hyprland-specific `xdg-desktop-portal/hyprland-portals.conf`, selecting Hyprland
for screen capture and GTK for file selection without changing other desktops.
After the first installation, start a fresh Hyprland session before testing
screen sharing. Both plain Hyprland and UWSM-managed sessions are supported.
If capture fails, inspect `journalctl --user -b -u xdg-desktop-portal
-u xdg-desktop-portal-hyprland`; a running service alone does not prove that
capture works. Test source selection and transmitted video in Discord and a
browser. Applying configuration never interrupts existing shares by restarting
the portal services.

### Manual installation

Install these dependencies using your distribution's packages or upstream builds.
Package names may vary by distribution.

Dependencies:

- [`hyprland`](https://github.com/hyprwm/Hyprland)
- [`quickshell`](https://git.outfoxxed.me/quickshell/quickshell)
- [`networkmanager`](https://gitlab.freedesktop.org/NetworkManager/NetworkManager)
- [`pipewire`](https://gitlab.freedesktop.org/pipewire/pipewire)
- [`wireplumber`](https://gitlab.freedesktop.org/pipewire/wireplumber)
- [`upower`](https://gitlab.freedesktop.org/upower/upower)
- [`matugen`](https://github.com/InioX/matugen)
- [`lm_sensors`](https://github.com/lm-sensors/lm-sensors)
- [`wl-clipboard`](https://github.com/bugaevc/wl-clipboard)
- [`cliphist`](https://github.com/sentriz/cliphist)
- [`fuzzel`](https://codeberg.org/dnkl/fuzzel)
- [`grim`](https://gitlab.freedesktop.org/emersion/grim)
- [`slurp`](https://github.com/emersion/slurp)
- [`libnotify`](https://gitlab.gnome.org/GNOME/libnotify)
- [`playerctl`](https://github.com/altdesktop/playerctl)
- [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
- [`hyprpicker`](https://github.com/hyprwm/hyprpicker)
- [`hyprsunset`](https://github.com/hyprwm/hyprsunset)
- [`hyprpolkitagent`](https://github.com/hyprwm/hyprpolkitagent)
- [`hyprlock`](https://github.com/hyprwm/hyprlock)
- [`hypridle`](https://github.com/hyprwm/hypridle)
- [`squashfs-tools`](https://github.com/plougher/squashfs-tools) (AppImages in the launcher)
- [`nautilus`](https://gitlab.gnome.org/GNOME/nautilus)
- [`gvfs`](https://gitlab.gnome.org/GNOME/gvfs)
- [`udisks2`](https://github.com/storaged-project/udisks)
- [`gnome-keyring`](https://gitlab.gnome.org/GNOME/gnome-keyring)
- [`dconf`](https://gitlab.gnome.org/GNOME/dconf)
- [`xdg-terminal-exec`](https://github.com/Vladimir-csp/xdg-terminal-exec)
- [`xdg-desktop-portal-hyprland`](https://github.com/hyprwm/xdg-desktop-portal-hyprland)
- [`xdg-desktop-portal-gtk`](https://github.com/flatpak/xdg-desktop-portal-gtk)

Fonts and themes:

- [Google Sans Flex](https://github.com/google/fonts/tree/main/ofl/googlesansflex)
- [JetBrains Mono Nerd Font](https://github.com/ryanoasis/nerd-fonts)
- [Bibata cursors](https://github.com/ful1e5/Bibata_Cursor)
- [Adwaita icons](https://gitlab.gnome.org/GNOME/adwaita-icon-theme)
- [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)

Install Google Sans Flex and JetBrains Mono Nerd Font into
`~/.local/share/fonts` (or your system's font directory), then refresh fontconfig:

```sh
fc-cache -f
```

Material Symbols Rounded is already bundled in the repository.

Enable NetworkManager and start PipeWire and WirePlumber in your user session
using your distribution's service setup. Configure permission to manage network
connections, and enable UPower for battery reporting. Start Hypridle in the
Hyprland session so the supplied lock and idle policy takes effect. The supplied
autostart configuration starts the shell, clipboard watchers, Hyprsunset and
GNOME Keyring, and starts the `hyprpolkitagent` user service; ensure that service
is available or adapt [autostart.lua](yonux/hypr/modules/autostart.lua) to your installation.
Configure desktop portals and keyring session integration for your distribution.

To match the remaining NixOS desktop integrations, also configure Bluetooth
(BlueZ), power-profiles-daemon, AppImage support, Gamescope and GameMode. `btop`
is included by the NixOS module as a manual monitoring utility.

Continue with **Apply the configuration** below, then log into Hyprland. You can
check the main dependencies with `qs --version`, `sensors -j` and `wpctl status`.

### Apply the configuration

Clone the repository and run the installer from its root:

```sh
git clone --branch development https://github.com/JoaoCunha50/yonux.git
cd yonux
./install.sh
```

The installer needs Go and runs `yonux dev-apply --from <clone root>` from the
checkout. It builds the `yonux` CLI and the `yonux-ipc` helper into
`~/.local/bin` and applies Hyprland, Quickshell, Matugen and portal configuration
through the same composition and backups as `yonux install`. After success the
clone is recorded as the source; later `yonux apply` reads it. A failed run
keeps the previous source record. Changes to Go require another `dev-apply`;
QML and configuration changes need only `yonux apply`.
The installer supplies the user configuration; packages and services must be
provided by either the NixOS module or the manual steps above.

The default application bindings expect Ghostty, Zen Browser via Flatpak,
Nautilus, Vesktop and Spotify. Nautilus is provided by the module; install the
other applications yourself or change their bindings. The module also makes
Ghostty the terminal `xdg-terminal-exec` uses for terminal applications and
shortcuts; on other systems list `com.mitchellh.ghostty.desktop` in
`~/.config/xdg-terminals.list`.

## Usage

Start a Hyprland session to launch the shell automatically, or run:

```sh
qs -c yonux
```

Set or query the wallpaper through IPC:

```sh
qs -c yonux ipc call wallpaper set /absolute/path/to/image.png
qs -c yonux ipc call wallpaper get
```

### AppImages

Put AppImages in `~/Applications`; they don't have to be executable. When the
shell starts and each time the launcher opens, `yonux-ipc appimages` reads each
AppImage's embedded desktop file and icon with `unsquashfs`. It writes
`yonux-appimage-<id>.desktop` to `~/.local/share/applications` and the icon to
`~/.local/share/yonux/appimages/`, so the launcher and the shortcut editor list
the app under its own name and icon. Removing the AppImage removes both files on
the next sync. Entries launch through `appimage-run` when it is installed (as on
NixOS); otherwise they run the file directly, which must then be executable.

### Keybindings

| Keys                          | Action                                                  |
| ----------------------------- | ------------------------------------------------------- |
| Super + Return / B / E        | Ghostty / Zen Browser / Nautilus                        |
| Super + Space                 | Application launcher                                    |
| Super + C                     | Control centre                                          |
| Super + comma                 | Settings                                                |
| Super + Escape                | Power menu                                              |
| Super + Q                     | Close window                                            |
| Super + F                     | Maximise, or fit the active column in scrolling layout  |
| Super + Shift + F             | Fullscreen                                              |
| Super + Ctrl + F              | Toggle the fullscreen state reported to the application |
| Super + A                     | Toggle floating and centre at 1000×660                  |
| Super + Shift + P             | Pin floating window                                     |
| Super + T                     | Toggle split, or swap with master                       |
| Super + R                     | Resize mode; Escape exits                               |
| Super + arrows                | Focus window                                            |
| Super + Shift + arrows        | Move window                                             |
| Super + Ctrl + arrows         | Resize window                                           |
| Super + LMB / RMB drag        | Move / resize window                                    |
| Super + 1…0                   | Switch workspace                                        |
| Super + Shift + 1…0           | Move to workspace and follow                            |
| Super + Alt + 1…0             | Move to workspace silently                              |
| Super + scroll                | Previous / next workspace                               |
| Super + D / M                 | Chat / music special workspace                          |
| Super + G                     | Toggle compositor game mode                             |
| Super + Shift + C             | Colour picker                                           |
| Super + V                     | Clipboard history                                       |
| Super + L                     | Lock session                                            |
| Super + Shift + S / Super + S | Capture area / focused monitor                          |
| Super + Shift + Escape        | Exit Hyprland                                           |

See [yonux/hypr/modules/binds.lua](yonux/hypr/modules/binds.lua) for bindings and
[yonux/hypr/modules/special.lua](yonux/hypr/modules/special.lua) for special workspaces.
Compositor game mode adjusts Hyprland effects; Feral GameMode is a separate service.

## Configuration

Use the settings window for supported shell and Hyprland preferences. Settings
are saved under `$XDG_CONFIG_HOME/yonux` (normally `~/.config/yonux`):

| File           | Purpose                     |
| -------------- | --------------------------- |
| `shell.json`   | Shell preferences           |
| `bar.json`     | Bar layout                  |
| `hypr.json`    | Hyprland preferences        |
| `hyprland.lua` | Generated Hyprland settings |

Put machine-specific Hyprland overrides in `~/.config/hypr/user.lua`. It is
loaded last, after generated settings, and `./install.sh` keeps it.

### Colours

[Colors.qml](yonux/shell/quickshell/theme/Colors.qml) calls `yonux-ipc theme` when the wallpaper
or palette settings change, which runs Matugen with `~/.config/yonux/matugen/config.toml`, laid there from
[yonux/shell/matugen/](yonux/shell/matugen/config.toml) by `yonux materialize`.

To change a template or the config, put your version at the same path under
`~/.config/yonux/user_preferences/matugen/` (for example
`user_preferences/matugen/templates/fish-colors.fish`) and run `materialize` again.
Your file wins over the default, and a new file there adds a template. Delete it
to get the default back. Files in `~/.config/yonux/matugen/` are managed output:
`materialize` replaces them with the selected base or preference file, and removes
them when neither source exists, even if the active file was edited. It never
copies those edits into `user_preferences`.

Keep Matugen customizations in `user_preferences/matugen/`. `materialize` takes
the base from `YONUX_BASE` for that run when set, else from the clone recorded by
`yonux dev-apply`, else from the installed package; a recorded clone that is gone
is an error. Hyprland's `~/.config/hypr/user.lua` remains a dedicated
personalization file and is never owned or overwritten by the composer.

| Application      | Generated output                             |
| ---------------- | -------------------------------------------- |
| Hyprland borders | `~/.cache/yonux/hypr-colors.lua`             |
| Fish             | `~/.config/fish/conf.d/zz-yonux-colors.fish` |
| Hyprlock         | `~/.cache/yonux/hyprlock-colors.conf`        |
| Ghostty          | `~/.config/ghostty/yonux-colors`             |
| Tmux             | `~/.config/tmux/yonux-colors.conf`           |

Hyprland and Hyprlock include their generated files through the supplied
configuration. Include the Ghostty and Tmux outputs in their respective
configurations to use them. The templates reload Hyprland, Ghostty and running
Tmux servers, and notify existing Fish sessions of colour changes. Add templates
and entries in `config.toml` to theme more applications.

### Fonts and sensors

Google Sans Flex is installed system-wide because the shell, GTK and Hyprlock
share it. Material Symbols Rounded is bundled for shell icons; JetBrains Mono
Nerd Font supplies the desktop monospace font.

CPU temperature is read every five seconds from `sensors -j` (`lm_sensors`),
which applies the system's `libsensors` configuration. Yonux takes the hottest
CPU package/die reading, preferring `Tdie` over `Tctl` per chip. It recognises
`Package id N`, `Tdie` and `Tctl` labels; custom labels or unsupported hardware
may require adapting the selection. Without a valid reading, the indicator is hidden.

## Updating

After upgrading the package, run `yonux apply`. For a development checkout,
pull and run `./install.sh` to rebuild the binaries and apply it.
Quickshell watches its configuration copies. In an active Hyprland session,
`install`, `apply` and `dev-apply` pause autoreload during writes, restore its
previous setting even on failure, and reload once after success if autoreload
was originally enabled. They do not restart the shell or portals.

## FAQ

**Can I use another distribution?**
Yes, follow [Manual installation](#manual-installation). Automated dependency
and service setup is currently provided through NixOS only; on other distributions,
install the dependencies and configure the services yourself.

**Why is the temperature indicator missing?**
Run `sensors -j` and check for supported CPU labels. Installing `lm_sensors`
does not guarantee that the kernel exposes a sensor for your hardware.

**Where is the lock screen?**
Yonux uses [Hyprlock](yonux/hypr/hyprlock.conf) and [Hypridle](yonux/hypr/hypridle.conf).
The supplied idle policy locks after ten minutes and turns displays off after eleven.

## Credits

Built with [Quickshell](https://quickshell.org/), [Hyprland](https://hypr.land/)
and [Matugen](https://github.com/InioX/matugen). README organisation inspired by
[Caelestia](https://github.com/caelestia-dots/shell).

Typography and icons: [Google Sans Flex](https://github.com/google/fonts/tree/main/ofl/googlesansflex),
[Material Symbols](https://github.com/google/material-design-icons) and
[JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) via Nerd Fonts.
The bundled font's license is in [LICENSE](yonux/shell/quickshell/assets/fonts/LICENSE).
Yonux code is licensed under [MIT](LICENSE).
