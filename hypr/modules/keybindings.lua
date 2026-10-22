local paths = require("modules.paths")
local keys = require("modules.keys")
local overrides, custom, catalog = {}, {}, {}
local M = {}

local file = io.open(paths.keybindings, "r")
if file then
    local text = file:read("*a")
    file:close()
    local chunk = load(text, "@" .. paths.keybindings, "t", {})
    if chunk then
        local ok, data = pcall(chunk)
        if ok and type(data) == "table" then
            for _, entry in ipairs(data.overrides or {}) do overrides[entry.id] = entry end
            custom = data.custom or {}
        end
    end
end

local function bind(entry, action, options)
    if entry.enabled == false then return end
    if entry.kind ~= "default" then
        action = hl.dsp.exec_cmd(entry.command)
        options = {}
    end
    local copy = {}
    for key, value in pairs(options or {}) do copy[key] = value end
    copy.description = "yonux-bind|" .. entry.id .. "|" .. entry.title
    hl.bind(entry.keys, action, copy)
end

function M.create_bind(id, action, options)
    options = options or {}
    local chord = assert(keys[id], "Unknown keybinding: " .. id)
    local title = options.description or id
    catalog[#catalog + 1] = { id = id, keys = chord, title = title, mouse = options.mouse == true }
    local override = overrides[id]
    bind(override or { id = id, keys = chord, title = title, kind = "default" }, action, options)
end

local function json_string(value)
    return '"' .. value:gsub('[%z\1-\31\\"]', function(char)
        if char == '"' then return '\\"' end
        if char == '\\' then return '\\\\' end
        return string.format('\\u%04x', char:byte())
    end) .. '"'
end

function M.finish()
    for _, entry in ipairs(custom) do bind(entry) end
    local rows = {}
    for _, entry in ipairs(catalog) do
        rows[#rows + 1] = '{"id":' .. json_string(entry.id) .. ',"keys":' .. json_string(entry.keys)
            .. ',"title":' .. json_string(entry.title) .. ',"mouse":' .. tostring(entry.mouse) .. '}'
    end
    local path = paths.keybindings_catalog
    local output = io.open(path .. ".tmp", "w")
    if not output then return end
    output:write("[\n", table.concat(rows, ",\n"), "\n]\n")
    output:close()
    os.rename(path .. ".tmp", path)
end

return M
