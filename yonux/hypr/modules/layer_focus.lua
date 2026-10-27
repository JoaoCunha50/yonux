-- Hyprland 0.56 sends pointer focus to a newly mapped keyboard-interactive
-- layer, even outside its bounds. Hit-test again when the pointer is over
-- our bar, keeping the keyboard in the overlay and the pointer in the bar.
hl.on("layer.opened", function(layer)
    if not layer.namespace:match("^yonux%-") or layer.interactivity == 0 then
        return
    end

    local pos = hl.get_cursor_pos()
    if not pos then
        return
    end

    for _, bar in ipairs(hl.get_layers({ namespace = "yonux-bar" })) do
        if bar.mapped and pos.x >= bar.x and pos.x < bar.x + bar.w
            and pos.y >= bar.y and pos.y < bar.y + bar.h then
            hl.dispatch(hl.dsp.cursor.move(pos))
            return
        end
    end
end)
