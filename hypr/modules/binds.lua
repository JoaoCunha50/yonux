local paths = require("modules.paths")
local mod = "SUPER"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + Space", hl.dsp.global("yonux:launcher"), { description = "Toggle application launcher" })
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"), { description = "Clipboard history" })
hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock the session" })
hl.bind(mod .. "+ SHIFT + S", hl.dsp.exec_cmd(paths.hypr .. "/scripts/screenshot area"), { description = "Screenshot an area" })
hl.bind(mod .. "+ S", hl.dsp.exec_cmd(paths.hypr .. "/scripts/screenshot screen"), { description = "Screenshot the focused monitor" })
hl.bind(mod .. " + G", hl.dsp.exec_cmd(paths.hypr .. "/scripts/game-mode toggle"), { description = "Toggle game mode" })
hl.bind(mod .. " + C", hl.dsp.global("yonux:controlcenter"), { description = "Toggle control center" })
hl.bind(mod .. " + Escape", hl.dsp.global("yonux:power"), { description = "Toggle power menu" })
hl.bind(mod .. " + comma", hl.dsp.global("yonux:settings"), { description = "Toggle settings" })
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exit())

-- Windows
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))
hl.bind(mod .. " + A", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1000, y = 660, exact = true }))
    hl.dispatch(hl.dsp.window.center())
end)
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pin())

local function layout()
    return yonux and yonux.layout or "dwindle"
end

yonux = yonux or {}
yonux.fitted = yonux.fitted or {}

local function set_fitted(value)
    local window = hl.get_active_window()
    if window then yonux.fitted[window.address] = value end
end

hl.bind(mod .. " + F", function()
    if layout() ~= "scrolling" then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
        return
    end
    local window = hl.get_active_window()
    if not window then return end
    if yonux.fitted[window.address] then
        hl.dispatch(hl.dsp.layout("colresize " .. hl.get_config("scrolling.column_width")))
        yonux.fitted[window.address] = nil
    else
        hl.dispatch(hl.dsp.layout("fit active"))
        yonux.fitted[window.address] = true
    end
end, { description = "Maximize, or fit the column (scrolling)" })

hl.on("window.close", function(window)
    if window then yonux.fitted[window.address] = nil end
end)

local layout_toggle = { dwindle = "togglesplit", master = "swapwithmaster" }
hl.bind(mod .. " + T", function()
    local action = layout_toggle[layout()]
    if action then hl.dispatch(hl.dsp.layout(action)) end
end, { description = "Toggle split or swap with master" })
hl.bind(mod .. " + bracketleft", function()
    if layout() ~= "scrolling" then return end
    hl.dispatch(hl.dsp.layout("colresize -0.1"))
    set_fitted(nil)
end, { description = "Narrow the column (scrolling)" })
hl.bind(mod .. " + bracketright", function()
    if layout() ~= "scrolling" then return end
    hl.dispatch(hl.dsp.layout("colresize +0.1"))
    set_fitted(nil)
end, { description = "Widen the column (scrolling)" })

-- Focus, move and resize with the arrows
hl.bind(mod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + Down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + CTRL + Left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Move/resize with the mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces: Super+N focus, Super+Shift+N move and follow, Super+Alt+N move silently
for i = 1, 10 do
    local key = i % 10 -- 10 maps to the 0 key
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Media, volume and brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
