local paths = require("modules.paths")

hl.on("hyprland.start", function()
    hl.exec_cmd('hyprctl setcursor "$HYPRCURSOR_THEME" "$HYPRCURSOR_SIZE"')
    hl.exec_cmd("command -v gnome-keyring-daemon >/dev/null && gnome-keyring-daemon --start --components=secrets,pkcs11")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark")

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- hyprlock.conf sources this file; it only exists after the first matugen run
    hl.exec_cmd("mkdir -p ~/.cache/yonux && touch ~/.cache/yonux/hyprlock-colors.conf")

    hl.exec_cmd(paths.qs)
end)
