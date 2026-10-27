-- Resize mode: Super+R enters, arrows or hjkl resize, Escape/Return/Super+R leave.
local step = 40

hl.bind("SUPER + R", function()
    hl.dispatch(hl.dsp.submap("resize"))
    hl.dispatch(hl.dsp.exec_cmd("hyprctl notify -1 2200 0 'Resize mode: arrows or hjkl, Esc exits'"))
end)

hl.define_submap("resize", function()
    hl.bind("Left", hl.dsp.window.resize({ x = -step, y = 0, relative = true }), { repeating = true })
    hl.bind("Right", hl.dsp.window.resize({ x = step, y = 0, relative = true }), { repeating = true })
    hl.bind("Up", hl.dsp.window.resize({ x = 0, y = -step, relative = true }), { repeating = true })
    hl.bind("Down", hl.dsp.window.resize({ x = 0, y = step, relative = true }), { repeating = true })
    hl.bind("h", hl.dsp.window.resize({ x = -step, y = 0, relative = true }), { repeating = true })
    hl.bind("l", hl.dsp.window.resize({ x = step, y = 0, relative = true }), { repeating = true })
    hl.bind("k", hl.dsp.window.resize({ x = 0, y = -step, relative = true }), { repeating = true })
    hl.bind("j", hl.dsp.window.resize({ x = 0, y = step, relative = true }), { repeating = true })
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("SUPER + R", hl.dsp.submap("reset"))
end)
