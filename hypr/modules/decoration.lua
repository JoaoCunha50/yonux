local paths = require("modules.paths")

hl.config({
    general = {
        gaps_in = 10,
        gaps_out = 15,
        border_size = 2,
        layout = "dwindle",
        resize_on_border = true,
        -- only windows with the `immediate` rule tear (games, window_rules.lua)
        allow_tearing = true,
        -- fallbacks until the wallpaper palette below has been generated
        ["col.active_border"] = "rgb(89b4fa)",
        ["col.inactive_border"] = "rgb(1e1e2e)",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1,
        inactive_opacity = 1,
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = 0xaa0a0807,
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            vibrancy = 0.17,
            noise = 0.01,
            new_optimizations = true,
        },
    },
})

local f = io.open(paths.colors, "r")
if f then
    f:close()
    local ok, err = pcall(dofile, paths.colors)
    if not ok then print("yonux: failed to load " .. paths.colors .. ": " .. tostring(err)) end
end

hl.layer_rule({
    name = "yonux-shell-noanim",
    match = { namespace = "^(quickshell|yonux-.*)$" },
    no_anim = true,
})
