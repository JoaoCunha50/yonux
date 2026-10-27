hl.monitor({ output = "DP-1", mode = "2560x1440@240.00", position = "0x0", scale = 1, cm = "srgb", bitdepth = 8, sdrbrightness = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60.00", position = "-1920x0", scale = 1, cm = "srgb", bitdepth = 8, sdrbrightness = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("GDK_SCALE", "1")
