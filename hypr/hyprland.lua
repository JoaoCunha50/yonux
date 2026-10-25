-- yonux Hyprland config. Lives in the yonux-shell repo and is symlinked to
-- ~/.config/hypr (see install.sh). Each concern is its own module

local function optional(mod)
    if package.searchpath == nil or package.searchpath(mod, package.path) then
        local ok, err = pcall(require, mod)
        if not ok then
            print("yonux: optional config module '" .. mod .. "' failed to load: " .. tostring(err))
        end
    end
end

require("modules.env")
require("modules.monitors")
require("modules.input")
require("modules.layer_focus")
require("modules.misc")
require("modules.decoration")
require("modules.animations")
require("modules.binds")
require("modules.resize")
require("modules.special")
require("modules.window_rules")
require("modules.autostart")

-- Settings from the shell window. After the modules so they win, before user.lua.
local settings = require("modules.paths").settings
local file = io.open(settings, "r")
if file then
    file:close()
    local ok, err = pcall(dofile, settings)
    if not ok then print("yonux: failed to load " .. settings .. ": " .. tostring(err)) end
end

-- Machine-local overrides (gitignored). Loads last, so it wins.
optional("user")
