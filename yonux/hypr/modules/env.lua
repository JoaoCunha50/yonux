hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Prefer native Wayland, fall back to X11.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- nixpkgs wrappers only run native Wayland when this is set
hl.env("NIXOS_OZONE_WL", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QS_ICON_THEME", "Adwaita")

-- GTK4 apps (nautilus) hang at startup on non-GNOME compositors with the default renderer; the GL one takes a direct Wayland path.
hl.env("GSK_RENDERER", "gl")

-- Without an input method daemon, GTK4's default Wayland IM module drops dead keys (us intl); the simple one composes them itself.
hl.env("GTK_IM_MODULE", "simple")

hl.env("TERMINAL", "ghostty")
hl.env("BROWSER", "flatpak run app.zen_browser.zen")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
