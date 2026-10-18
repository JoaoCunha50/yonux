<div align="center">

# Yonux Shell

A Quickshell desktop shell and Hyprland configuration, with Material styling and wallpaper-based colours.

[Components](#components) · [Installation](#installation) · [Usage](#usage) · [Configuration](#configuration) · [FAQ](#faq)

</div>

## Components

- **Bar:** workspaces, system tray, clock, CPU, memory, disk, temperature, battery, network and audio.
- **Launcher:** search and launch desktop applications.
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

### Manual installation

Install these dependencies using your distribution's packages or upstream builds.
Package names may vary by distribution.

Dependencies:

- [`hyprland`](https://github.com/hyprwm/Hyprland) — requires Lua API support
- [`quickshell`](https://git.outfoxxed.me/quickshell/quickshell) — with Qt Quick, Wayland, NetworkManager, PipeWire and UPower support
- [`networkmanager`](https://gitlab.freedesktop.org/NetworkManager/NetworkManager)
- [`pipewire`](https://gitlab.freedesktop.org/pipewire/pipewire) — including PulseAudio compatibility for PulseAudio applications
- [`wireplumber`](https://gitlab.freedesktop.org/pipewire/wireplumber) — provides `wpctl`
- [`upower`](https://gitlab.freedesktop.org/upower/upower)
- [`matugen`](https://github.com/InioX/matugen)
- [`lm_sensors`](https://github.com/lm-sensors/lm-sensors)
- [`wl-clipboard`](https://github.com/bugaevc/wl-clipboard)
- [`cliphist`](https://github.com/sentriz/cliphist)
- [`fuzzel`](https://codeberg.org/dnkl/fuzzel)
- [`grim`](https://gitlab.freedesktop.org/emersion/grim)
- [`slurp`](https://github.com/emersion/slurp)
- [`libnotify`](https://gitlab.gnome.org/GNOME/libnotify) — provides `notify-send`
- [`playerctl`](https://github.com/altdesktop/playerctl)
- [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
- [`hyprpicker`](https://github.com/hyprwm/hyprpicker)
- [`hyprsunset`](https://github.com/hyprwm/hyprsunset)
- [`hyprpolkitagent`](https://github.com/hyprwm/hyprpolkitagent)
- [`hyprlock`](https://github.com/hyprwm/hyprlock)
- [`hypridle`](https://github.com/hyprwm/hypridle)
- [`nautilus`](https://gitlab.gnome.org/GNOME/nautilus)
- [`gvfs`](https://gitlab.gnome.org/GNOME/gvfs)
- [`udisks2`](https://github.com/storaged-project/udisks)
- [`gnome-keyring`](https://gitlab.gnome.org/GNOME/gnome-keyring)
- [`glib`](https://gitlab.gnome.org/GNOME/glib) — provides `gsettings`
- [`dconf`](https://gitlab.gnome.org/GNOME/dconf)
- [`xdg-terminal-exec`](https://github.com/Vladimir-csp/xdg-terminal-exec)
- [`xdg-desktop-portal-hyprland`](https://github.com/hyprwm/xdg-desktop-portal-hyprland)
- [`xdg-desktop-portal-gtk`](https://github.com/flatpak/xdg-desktop-portal-gtk)
- [`bash`](https://git.savannah.gnu.org/cgit/bash.git) and [`coreutils`](https://git.savannah.gnu.org/cgit/coreutils.git)
- [`dbus`](https://gitlab.freedesktop.org/dbus/dbus) and [`systemd`](https://github.com/systemd/systemd) — session bus, user services and logind

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
is available or adapt [autostart.lua](hypr/modules/autostart.lua) to your installation.
Configure desktop portals and keyring session integration for your distribution.

To match the remaining NixOS desktop integrations, also configure Bluetooth
(BlueZ), power-profiles-daemon, AppImage support, Gamescope and GameMode. `btop`
is included by the NixOS module as a manual monitoring utility.

Continue with **Link the configuration** below, then log into Hyprland. You can
check the main dependencies with `qs --version`, `sensors -j` and `wpctl status`.

### Link the configuration

Clone the repository and run the installer from its root:

```sh
git clone https://github.com/joaocunha50/yonux-shell.git
cd yonux-shell
./install.sh
```

The installer links `hypr/` to `~/.config/hypr` and `quickshell/` to
`~/.config/quickshell/yonux`. Existing directories or files are moved to
`*.bak-<timestamp>`; existing symlinks are replaced. Keep the checkout in place.
The installer supplies the user configuration; packages and services must be
provided by either the NixOS module or the manual steps above.

The default application bindings expect Ghostty, Zen Browser via Flatpak,
Nautilus, Vesktop and Spotify. Nautilus is provided by the module; install the
other applications yourself or change their bindings.

## Usage

Start a Hyprland session to launch the shell automatically, or run:

```sh
qs -c yonux
```

During development, run directly from the checkout:

```sh
qs -p quickshell/shell.qml
```

Set or query the wallpaper through IPC:

```sh
qs -c yonux ipc call wallpaper set /absolute/path/to/image.png
qs -c yonux ipc call wallpaper get
```

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

See [hypr/modules/binds.lua](hypr/modules/binds.lua) for bindings and
[hypr/modules/special.lua](hypr/modules/special.lua) for special workspaces.
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

Put machine-specific Hyprland overrides in `hypr/user.lua`. This file is ignored
by Git and loaded last, after generated settings.

### Colours

[Colors.qml](quickshell/theme/Colors.qml) runs Matugen when the wallpaper or palette
settings change, using [config.toml](quickshell/matugen/config.toml).

| Application      | Generated output                             |
| ---------------- | -------------------------------------------- |
| Hyprland borders | `~/.cache/yonux/hypr-colors.lua`             |
| Fish             | `~/.config/fish/conf.d/zz-yonux-colors.fish` |
| Hyprlock         | `~/.cache/yonux/hyprlock-colors.conf`        |
| Ghostty          | `~/.config/ghostty/yonux-colors`             |

Hyprland and Hyprlock include their generated files through the supplied
configuration. Include the Ghostty output in your Ghostty configuration to use
it. The templates reload Hyprland and Ghostty and notify existing Fish sessions
of colour changes. Add templates and entries in `config.toml` to theme more applications.

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

Pull changes into the checkout to update the linked configuration. If using the
NixOS flake module, update the `yonux-shell` input and rebuild the system as well.
Restart the shell or log into a fresh Hyprland session as needed.

## FAQ

**Can I use another distribution?**
Yes, follow [Manual installation](#manual-installation). Automated dependency
and service setup is currently provided through NixOS only; on other distributions,
install the dependencies and configure the services yourself.

**Why is the temperature indicator missing?**
Run `sensors -j` and check for supported CPU labels. Installing `lm_sensors`
does not guarantee that the kernel exposes a sensor for your hardware.

**Where is the lock screen?**
Yonux uses [Hyprlock](hypr/hyprlock.conf) and [Hypridle](hypr/hypridle.conf).
The supplied idle policy locks after ten minutes and turns displays off after eleven.

## Credits

Built with [Quickshell](https://quickshell.org/), [Hyprland](https://hypr.land/)
and [Matugen](https://github.com/InioX/matugen). README organisation inspired by
[Caelestia](https://github.com/caelestia-dots/shell).

Typography and icons: [Google Sans Flex](https://github.com/google/fonts/tree/main/ofl/googlesansflex),
[Material Symbols](https://github.com/google/material-design-icons) and
[JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) via Nerd Fonts.
The bundled font's license is in [quickshell/assets/fonts/LICENSE](quickshell/assets/fonts/LICENSE).
Yonux code is licensed under [MIT](LICENSE).
