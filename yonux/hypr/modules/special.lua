-- Special workspaces. The app ones launch their app on first toggle and are where that app always opens.
local apps = {
    chat = { key = "SUPER + D", classes = { "vesktop", "discord" }, command = "vesktop" },
    music = { key = "SUPER + M", classes = { "Spotify", "spotify" }, command = "spotify" },
}

-- get_windows matches class exactly, not as a regex
local function running(classes)
    for _, class in ipairs(classes) do
        if #hl.get_windows({ class = class }) > 0 then
            return true
        end
    end
    return false
end

for name, app in pairs(apps) do
    local class = "^(" .. table.concat(app.classes, "|") .. ")$"
    hl.window_rule({ name = "special-" .. name, match = { class = class }, workspace = "special:" .. name, tile = true })
    hl.bind(app.key, function()
        if not running(app.classes) then
            hl.dispatch(hl.dsp.exec_cmd(app.command))
        end
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
    end, { description = "Toggle " .. name .. " special workspace" })
end