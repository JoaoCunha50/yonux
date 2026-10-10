local home = os.getenv("HOME") or ""
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local cache = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")

return {
    hypr = config .. "/hypr",
    -- rendered by matugen from quickshell/matugen/templates/ on every wallpaper change
    colors = cache .. "/yonux/hypr-colors.lua",
    -- written by the shell settings window from ~/.config/yonux/hypr.json
    settings = config .. "/yonux/hyprland.lua",
    -- `qs -c yonux` finds the shell through ~/.config/quickshell/yonux
    -- the portal theme makes FileDialog open the native GTK chooser
    qs = "QT_QPA_PLATFORMTHEME=xdgdesktopportal qs -c yonux",
}
