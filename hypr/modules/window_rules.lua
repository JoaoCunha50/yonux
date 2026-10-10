-- Fixed float sizes are capped to the monitor the window opens on.
local function fit(w, h)
    return {
        "min(" .. w .. ", monitor_w * 0.92)",
        "min(" .. h .. ", monitor_h * 0.88)",
    }
end

-- Apps asking to maximize themselves are ignored; Super+F does it on request.
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "float-system-dialogs",
    match = { class = "(pavucontrol|nm-connection-editor|blueman-manager|hyprpolkitagent|xdg-desktop-portal-gtk)" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "float-file-pickers",
    match = { title = "(Open File|Save File|Save As|Choose Files|Open Folder)" },
    float = true,
})

-- Steam, its games and gamescope render opaque with no blur or shadow,
-- keep the screen awake while fullscreen, and may tear (general.allow_tearing)
-- for lower input latency.
hl.window_rule({
    name = "games",
    match = { class = "^(steam|steam_app_.*|gamescope)$" },
    no_blur = true,
    no_shadow = true,
    opaque = true,
    idle_inhibit = "fullscreen",
    immediate = true,
})

hl.window_rule({
    name = "float-yonux-settings",
    match = { title = "^yonux settings$" },
    float = true,
    size = fit(1080, 760),
    center = true,
})
