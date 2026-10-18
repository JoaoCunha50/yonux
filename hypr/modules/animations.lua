hl.config({ animations = { enabled = true } })

hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

yonux = yonux or {}

-- The settings window sets yonux.animation_speed and calls this again; speed is a duration, so it divides.
function yonux.apply_animations()
    local scale = yonux.animation_speed or 1
    local function animation(leaf, speed, bezier, style)
        hl.animation({ leaf = leaf, enabled = true, speed = speed / scale, bezier = bezier, style = style })
    end

    animation("layersIn", 5, "emphasizedDecel", "slide")
    animation("layersOut", 4, "emphasizedAccel", "slide")
    animation("fadeLayers", 5, "standard")

    animation("windowsIn", 5, "emphasizedDecel")
    animation("windowsOut", 3, "emphasizedAccel")
    animation("windowsMove", 3.5, "standard")
    animation("workspaces", 5, "standard")

    animation("specialWorkspace", 4, "specialWorkSwitch", "slidefadevert 15%")
    animation("fade", 6, "standard")
    animation("fadeDim", 6, "standard")
    animation("border", 6, "standard")
end

yonux.apply_animations()
