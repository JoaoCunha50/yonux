hl.config({ animations = { enabled = true } })

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("bloom", { type = "bezier", points = { { 0.16, 1.12 }, { 0.24, 1 } } })
hl.curve("settle", { type = "bezier", points = { { 0.18, 0.86 }, { 0.24, 1 } } })

yonux = yonux or {}

-- The settings window sets yonux.animation_speed and calls this again; speed is a duration, so it divides.
function yonux.apply_animations()
    local scale = yonux.animation_speed or 1
    local function animation(leaf, speed, bezier, style)
        hl.animation({ leaf = leaf, enabled = true, speed = speed / scale, bezier = bezier, style = style })
    end

    animation("global", 10, "default")
    animation("border", 5.39, "easeOutQuint")
    animation("windows", 4.5, "settle")
    animation("windowsIn", 4, "bloom", "popin 87%")
    animation("windowsOut", 1.5, "linear", "popin 87%")
    animation("fadeIn", 1.73, "almostLinear")
    animation("fadeOut", 1.46, "almostLinear")
    animation("fade", 3.03, "quick")
    animation("layers", 3.81, "easeOutQuint")
    animation("layersIn", 4, "easeOutQuint", "fade")
    animation("layersOut", 1.5, "linear", "fade")
    animation("workspaces", 2.5, "settle", "slide")
    animation("specialWorkspace", 3, "settle", "slidevert")
end

yonux.apply_animations()
