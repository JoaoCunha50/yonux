local home = os.getenv("HOME") or ""
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local cache = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")

return {
    hypr = config .. "/hypr",
    colors = cache .. "/yonux/hypr-colors.lua",
    settings = config .. "/yonux/hyprland.lua",
    keybindings = config .. "/yonux/keybindings.lua",
    keybindings_catalog = config .. "/yonux/keybindings-catalog.json",
    qs = "QT_QPA_PLATFORMTHEME=xdgdesktopportal qs -c yonux",
}
