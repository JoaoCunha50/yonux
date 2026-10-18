hl.config({
    misc = {
        focus_on_activate = true,
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        allow_session_lock_restore = true,
        animate_manual_resizes = true,
    },
    xwayland = {
        force_zero_scaling = true,
        use_nearest_neighbor = true,
    },
    render = {
        direct_scanout = 1,
        -- the night light fade drops frames on amdgpu
        ctm_animation = 0,
    },
    dwindle = {
        preserve_split = true,
    },
})
