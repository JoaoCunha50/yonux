local keybindings = require("modules.keybindings")
local paths = require("modules.paths")
local create_bind = keybindings.create_bind

-- Apps
create_bind("terminal", hl.dsp.exec_cmd("ghostty"), { description = "Open terminal" })
create_bind("browser", hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"), { description = "Open browser" })
create_bind("fileManager", hl.dsp.exec_cmd("nautilus"), { description = "Open file manager" })
create_bind("launcher", hl.dsp.global("yonux:launcher"), { description = "Toggle application launcher" })
create_bind("colorPicker", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pick a colour" })
create_bind("clipboard", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"), { description = "Clipboard history" })
create_bind("lock", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock the session" })
create_bind("screenshotArea", hl.dsp.exec_cmd(paths.hypr .. "/scripts/screenshot area"), { description = "Screenshot an area" })
create_bind("screenshotScreen", hl.dsp.exec_cmd(paths.hypr .. "/scripts/screenshot screen"), { description = "Screenshot the focused monitor" })
create_bind("gameMode", hl.dsp.exec_cmd(paths.hypr .. "/scripts/game-mode toggle"), { description = "Toggle game mode" })
create_bind("controlCenter", hl.dsp.global("yonux:controlcenter"), { description = "Toggle control center" })
create_bind("power", hl.dsp.global("yonux:power"), { description = "Toggle power menu" })
create_bind("settings", hl.dsp.global("yonux:settings"), { description = "Toggle settings" })
create_bind("exit", hl.dsp.exit(), { description = "Exit Hyprland" })

-- Windows
create_bind("closeWindow", hl.dsp.window.close(), { description = "Close window" })
create_bind("fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle fullscreen" })
create_bind("clientFullscreen", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }), { description = "Toggle client fullscreen" })
create_bind("floating", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1000, y = 660, exact = true }))
    hl.dispatch(hl.dsp.window.center())
end, { description = "Toggle floating window" })
create_bind("pin", hl.dsp.window.pin(), { description = "Pin window" })

local function layout()
    return yonux and yonux.layout or "dwindle"
end

yonux = yonux or {}
yonux.fitted = yonux.fitted or {}

local function set_fitted(value)
    local window = hl.get_active_window()
    if window then yonux.fitted[window.address] = value end
end

create_bind("maximize", function()
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
create_bind("toggleSplit", function()
    local action = layout_toggle[layout()]
    if action then hl.dispatch(hl.dsp.layout(action)) end
end, { description = "Toggle split or swap with master" })
create_bind("narrowColumn", function()
    if layout() ~= "scrolling" then return end
    hl.dispatch(hl.dsp.layout("colresize -0.1"))
    set_fitted(nil)
end, { description = "Narrow the column (scrolling)" })
create_bind("widenColumn", function()
    if layout() ~= "scrolling" then return end
    hl.dispatch(hl.dsp.layout("colresize +0.1"))
    set_fitted(nil)
end, { description = "Widen the column (scrolling)" })

-- Focus, move and resize with the arrows
create_bind("focusLeft", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
create_bind("focusRight", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
create_bind("focusUp", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
create_bind("focusDown", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })
create_bind("moveLeft", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
create_bind("moveRight", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
create_bind("moveUp", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
create_bind("moveDown", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
create_bind("shrinkWidth", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true, description = "Shrink window horizontally" })
create_bind("growWidth", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true, description = "Grow window horizontally" })
create_bind("shrinkHeight", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true, description = "Shrink window vertically" })
create_bind("growHeight", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true, description = "Grow window vertically" })

-- Move/resize with the mouse
create_bind("dragWindow", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
create_bind("resizeWindow", hl.dsp.window.resize(), { mouse = true, description = "Resize window with mouse" })

-- Workspaces: Super+N focus, Super+Shift+N move and follow, Super+Alt+N move silently
for i = 1, 10 do
    create_bind("workspace" .. i, hl.dsp.focus({ workspace = i }), { description = "Focus workspace " .. i })
    create_bind("moveToWorkspace" .. i, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
    create_bind("sendToWorkspace" .. i, hl.dsp.window.move({ workspace = i, follow = false }), { description = "Send window to workspace " .. i })
end
create_bind("nextWorkspace", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
create_bind("previousWorkspace", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Media, volume and brightness
create_bind("volumeUp", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { description = "Raise volume", locked = true, repeating = true })
create_bind("volumeDown", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { description = "Lower volume", locked = true, repeating = true })
create_bind("mute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Mute audio", locked = true })
create_bind("muteMicrophone", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { description = "Mute microphone", locked = true })
create_bind("playPause", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Play or pause", locked = true })
create_bind("pause", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Pause playback", locked = true })
create_bind("nextTrack", hl.dsp.exec_cmd("playerctl next"), { description = "Next track", locked = true })
create_bind("previousTrack", hl.dsp.exec_cmd("playerctl previous"), { description = "Previous track", locked = true })
create_bind("brightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { description = "Raise brightness", locked = true, repeating = true })
create_bind("brightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { description = "Lower brightness", locked = true, repeating = true })

keybindings.finish()
