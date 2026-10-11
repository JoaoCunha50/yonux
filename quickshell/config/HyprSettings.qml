pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

SettingsStore {
    id: root

    readonly property string luaPath: `${dir}/hyprland.lua`

    file: "hypr.json"

    onValuesChanged: if (ready)
        writeLua.restart()
    onReadyChanged: if (ready)
        writeLua.restart()

    schema: [
        {
            section: "Theme",
            key: "animations.enabled",
            label: "Animations",
            desc: "Window and shell animations",
            ctl: "switch",
            def: true
        },
        {
            section: "Theme",
            key: "animations.speed",
            label: "Animation speed",
            desc: "Scales how fast windows and the shell animate",
            ctl: "slider",
            resettable: true,
            lo: 0.25,
            hi: 2,
            step: 0.05,
            pct: true,
            def: 1,
            hyprOption: false,
            when: {
                key: "animations.enabled",
                value: true
            }
        },
        {
            section: "Layout",
            key: "general.layout",
            label: "Tiling layout",
            desc: "Binary splits, a master and stack, or one endless horizontal strip",
            ctl: "seg",
            opts: [
                {
                    value: "dwindle",
                    label: "Dwindle"
                },
                {
                    value: "master",
                    label: "Master"
                },
                {
                    value: "scrolling",
                    label: "Scrolling"
                }
            ],
            def: "dwindle"
        },
        {
            section: "Layout",
            key: "scrolling.column_width",
            label: "Column width",
            desc: "Share of the screen each new column takes",
            ctl: "slider",
            resettable: true,
            lo: 0.1,
            hi: 1,
            step: 0.05,
            pct: true,
            def: 0.5,
            when: {
                key: "general.layout",
                value: "scrolling"
            }
        },
        {
            section: "Layout",
            key: "scrolling.follow_focus",
            label: "Follow focus",
            desc: "Pan the strip to keep the focused column in view",
            ctl: "switch",
            def: true,
            when: {
                key: "general.layout",
                value: "scrolling"
            }
        },
        {
            section: "Layout",
            key: "dwindle.preserve_split",
            label: "Preserve split",
            desc: "Keep the split direction when windows close and reopen",
            ctl: "switch",
            def: true,
            when: {
                key: "general.layout",
                value: "dwindle"
            }
        },
        {
            section: "Windows",
            key: "general.gaps_in",
            label: "Inner gaps",
            desc: "Space between windows",
            ctl: "slider",
            resettable: true,
            lo: 0,
            hi: 30,
            step: 1,
            def: 10
        },
        {
            section: "Windows",
            key: "general.gaps_out",
            label: "Outer gaps",
            desc: "Space between windows and the screen edge",
            ctl: "slider",
            resettable: true,
            lo: 0,
            hi: 50,
            step: 1,
            def: 15
        },
        {
            section: "Windows",
            key: "general.border_size",
            label: "Border width",
            desc: "Thickness of the window border",
            ctl: "slider",
            resettable: true,
            lo: 0,
            hi: 8,
            step: 1,
            def: 2
        },
        {
            section: "Windows",
            key: "decoration.rounding",
            label: "Corner radius",
            desc: "Roundness of window corners",
            ctl: "slider",
            resettable: true,
            lo: 0,
            hi: 30,
            step: 1,
            def: 10
        },
        {
            section: "Windows",
            key: "decoration.active_opacity",
            label: "Active opacity",
            desc: "Opacity of the focused window",
            ctl: "slider",
            resettable: true,
            lo: 0.5,
            hi: 1,
            step: 0.05,
            pct: true,
            def: 1
        },
        {
            section: "Windows",
            key: "decoration.inactive_opacity",
            label: "Inactive opacity",
            desc: "Opacity of unfocused windows",
            ctl: "slider",
            resettable: true,
            lo: 0.5,
            hi: 1,
            step: 0.05,
            pct: true,
            def: 1
        },
        {
            section: "Effects",
            key: "decoration.blur.enabled",
            label: "Blur",
            desc: "Blur what is behind translucent windows",
            ctl: "switch",
            def: true
        },
        {
            section: "Effects",
            key: "decoration.blur.size",
            label: "Blur size",
            desc: "Radius of each blur pass",
            ctl: "slider",
            resettable: true,
            lo: 1,
            hi: 12,
            step: 1,
            def: 4,
            when: {
                key: "decoration.blur.enabled",
                value: true
            }
        },
        {
            section: "Effects",
            key: "decoration.blur.passes",
            label: "Blur passes",
            desc: "More passes look smoother and cost more GPU",
            ctl: "slider",
            resettable: true,
            lo: 1,
            hi: 4,
            step: 1,
            def: 2,
            when: {
                key: "decoration.blur.enabled",
                value: true
            }
        },
        {
            section: "Effects",
            key: "decoration.shadow.enabled",
            label: "Shadows",
            desc: "Drop shadows under windows",
            ctl: "switch",
            def: true
        },
        {
            section: "Effects",
            key: "decoration.shadow.range",
            label: "Shadow range",
            desc: "How far the shadow spreads",
            ctl: "slider",
            resettable: true,
            lo: 0,
            hi: 50,
            step: 1,
            def: 20,
            when: {
                key: "decoration.shadow.enabled",
                value: true
            }
        },
        {
            section: "Input",
            key: "input.follow_mouse",
            label: "Focus follows mouse",
            desc: "When hovering a window gives it keyboard focus",
            ctl: "seg",
            opts: [
                {
                    value: 0,
                    label: "Off"
                },
                {
                    value: 1,
                    label: "Always"
                },
                {
                    value: 2,
                    label: "Detached"
                },
                {
                    value: 3,
                    label: "Loose"
                }
            ],
            def: 1
        },
        {
            section: "Input",
            key: "input.sensitivity",
            label: "Pointer speed",
            desc: "Added on top of the flat acceleration profile",
            ctl: "slider",
            resettable: true,
            lo: -1,
            hi: 1,
            step: 0.05,
            def: 0
        },
        {
            section: "Input",
            key: "input.touchpad.natural_scroll",
            label: "Natural scrolling",
            desc: "Touchpad content follows your fingers",
            ctl: "switch",
            def: false
        }
    ]

    function toLua(): string {
        let tree = {};
        for (let key in values) {
            if (schema.find(row => row.key === key)?.hyprOption === false)
                continue;
            let parts = key.split(".");
            let node = tree;
            for (let part of parts.slice(0, -1))
                node = node[part] = node[part] ?? {};
            node[parts[parts.length - 1]] = values[key];
        }

        let literal = (value, indent) => {
            if (typeof value === "string")
                return JSON.stringify(value);
            if (typeof value !== "object")
                return String(value);
            let pad = "    ".repeat(indent + 1);
            let fields = Object.keys(value).map(k => `${pad}${k} = ${literal(value[k], indent + 1)},`);
            return `{\n${fields.join("\n")}\n${"    ".repeat(indent)}}`;
        };

        return `-- Generated by the yonux settings window from hypr.json. Edit hypr.json, not this file.
yonux = yonux or {}
yonux.layout = ${JSON.stringify(value("general.layout"))}
yonux.animation_speed = ${value("animations.speed")}

hl.config(${literal(tree, 0)})
if yonux.apply_animations then yonux.apply_animations() end
`;
    }

    Timer {
        id: writeLua
        interval: 50
        onTriggered: luaFile.setText(root.toLua())
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false

        onSaved: Quickshell.execDetached(["hyprctl", "eval", `dofile(${JSON.stringify(root.luaPath)})`])
        onSaveFailed: error => Alerts.error("Could not write hyprland.lua", FileViewError.toString(error))
    }
}
