pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

SettingsStore {
    id: root

    readonly property string luaPath: `${Paths.config}/hyprland.lua`
    path: `${Paths.config}/hypr.json`

    onValuesChanged: if (ready)
        writeLua.restart()
    onReadyChanged: if (ready)
        writeLua.restart()

    readonly property string cursorTheme: ready ? value("cursor.theme") : ""
    readonly property int cursorSize: ready ? Math.max(16, Math.min(64, Math.round(value("cursor.size")))) : 22
    readonly property var cursorEnvironment: ({
            XCURSOR_THEME: cursorTheme,
            XCURSOR_SIZE: String(cursorSize),
            HYPRCURSOR_THEME: cursorTheme,
            HYPRCURSOR_SIZE: String(cursorSize)
        })
    property var installedCursorThemes: []
    signal cursorApplied

    readonly property var cursorOptions: {
        let names = installedCursorThemes.slice();
        for (let name of [defaults["cursor.theme"], cursorTheme])
            if (name && !names.includes(name))
                names.push(name);
        return names.sort().map(name => ({
                    value: name,
                    label: name
                }));
    }

    onCursorThemeChanged: cursorCommit.restart()
    onCursorSizeChanged: cursorCommit.restart()

    Timer {
        id: cursorCommit
        interval: 0
        onTriggered: root.applyCursor()
    }

    Process {
        id: cursorDiscovery
        running: true
        command: ["sh", "-c", `
            for base in "$@"; do
                for theme in "$base"/*; do
                    [ -d "$theme/cursors" ] && printf '%s\\n' "\${theme##*/}"
                done
            done
            exit 0
        `, "yonux-cursors", Quickshell.env("HOME") + "/.icons", (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/icons", "/usr/share/icons", "/usr/local/share/icons", Quickshell.env("HOME") + "/.nix-profile/share/icons", "/run/current-system/sw/share/icons"]
        stdout: StdioCollector {
            onStreamFinished: root.installedCursorThemes = [...new Set(this.text.split("\n").filter(name => name.length > 0))].sort()
        }
    }

    settings: [
        Setting {
            key: "cursor.theme"
            section: "Theme"
            label: "Cursor theme"
            desc: "Applies to Hyprland; GTK apps need a matching XCursor theme"
            control: Setting.Select
            resettable: true
            hyprOption: false
            options: root.cursorOptions
            defaultValue: "Bibata-Modern-Ice"
        },
        Setting {
            key: "cursor.size"
            section: "Theme"
            label: "Cursor size"
            desc: "Base size in pixels; monitor scaling also affects the result"
            control: Setting.Slider
            resettable: true
            hyprOption: false
            min: 16
            max: 64
            step: 1
            defaultValue: 22
        },
        Setting {
            key: "animations.enabled"
            section: "Theme"
            label: "Animations"
            desc: "Window and shell animations"
            control: Setting.Switch
            defaultValue: true
        },
        Setting {
            key: "animations.speed"
            section: "Theme"
            label: "Animation speed"
            desc: "Scales how fast windows and the shell animate"
            control: Setting.Slider
            resettable: true
            hyprOption: false
            min: 0.25
            max: 2
            step: 0.05
            percent: true
            defaultValue: 1
            shown: root.value("animations.enabled") === true
        },
        Setting {
            key: "general.layout"
            section: "Layout"
            label: "Tiling layout"
            desc: "Binary splits, a master and stack, or one endless horizontal strip"
            control: Setting.Segmented
            options: [
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
            ]
            defaultValue: "dwindle"
        },
        Setting {
            key: "scrolling.column_width"
            section: "Layout"
            label: "Column width"
            desc: "Share of the screen each new column takes"
            control: Setting.Slider
            resettable: true
            min: 0.1
            max: 1
            step: 0.05
            percent: true
            defaultValue: 0.5
            shown: root.value("general.layout") === "scrolling"
        },
        Setting {
            key: "scrolling.follow_focus"
            section: "Layout"
            label: "Follow focus"
            desc: "Pan the strip to keep the focused column in view"
            control: Setting.Switch
            defaultValue: true
            shown: root.value("general.layout") === "scrolling"
        },
        Setting {
            key: "dwindle.preserve_split"
            section: "Layout"
            label: "Preserve split"
            desc: "Keep the split direction when windows close and reopen"
            control: Setting.Switch
            defaultValue: true
            shown: root.value("general.layout") === "dwindle"
        },
        Setting {
            key: "general.gaps_in"
            section: "Windows"
            label: "Inner gaps"
            desc: "Space between windows"
            control: Setting.Slider
            resettable: true
            min: 0
            max: 30
            step: 1
            defaultValue: 10
        },
        Setting {
            key: "general.gaps_out"
            section: "Windows"
            label: "Outer gaps"
            desc: "Space between windows and the screen edge"
            control: Setting.Slider
            resettable: true
            min: 0
            max: 50
            step: 1
            defaultValue: 15
        },
        Setting {
            key: "general.border_size"
            section: "Windows"
            label: "Border width"
            desc: "Thickness of the window border"
            control: Setting.Slider
            resettable: true
            min: 0
            max: 8
            step: 1
            defaultValue: 2
        },
        Setting {
            key: "decoration.rounding"
            section: "Windows"
            label: "Corner radius"
            desc: "Roundness of window corners"
            control: Setting.Slider
            resettable: true
            min: 0
            max: 30
            step: 1
            defaultValue: 10
        },
        Setting {
            key: "decoration.active_opacity"
            section: "Windows"
            label: "Active opacity"
            desc: "Opacity of the focused window"
            control: Setting.Slider
            resettable: true
            min: 0.5
            max: 1
            step: 0.05
            percent: true
            defaultValue: 1
        },
        Setting {
            key: "decoration.inactive_opacity"
            section: "Windows"
            label: "Inactive opacity"
            desc: "Opacity of unfocused windows"
            control: Setting.Slider
            resettable: true
            min: 0.5
            max: 1
            step: 0.05
            percent: true
            defaultValue: 1
        },
        Setting {
            key: "decoration.blur.enabled"
            section: "Effects"
            label: "Blur"
            desc: "Blur what is behind translucent windows"
            control: Setting.Switch
            defaultValue: true
        },
        Setting {
            key: "decoration.blur.size"
            section: "Effects"
            label: "Blur size"
            desc: "Radius of each blur pass"
            control: Setting.Slider
            resettable: true
            min: 1
            max: 12
            step: 1
            defaultValue: 4
            shown: root.value("decoration.blur.enabled") === true
        },
        Setting {
            key: "decoration.blur.passes"
            section: "Effects"
            label: "Blur passes"
            desc: "More passes look smoother and cost more GPU"
            control: Setting.Slider
            resettable: true
            min: 1
            max: 4
            step: 1
            defaultValue: 2
            shown: root.value("decoration.blur.enabled") === true
        },
        Setting {
            key: "decoration.shadow.enabled"
            section: "Effects"
            label: "Shadows"
            desc: "Drop shadows under windows"
            control: Setting.Switch
            defaultValue: true
        },
        Setting {
            key: "decoration.shadow.range"
            section: "Effects"
            label: "Shadow range"
            desc: "How far the shadow spreads"
            control: Setting.Slider
            resettable: true
            min: 0
            max: 50
            step: 1
            defaultValue: 20
            shown: root.value("decoration.shadow.enabled") === true
        },
        Setting {
            key: "input.follow_mouse"
            section: "Input"
            label: "Focus follows mouse"
            desc: "When hovering a window gives it keyboard focus"
            control: Setting.Segmented
            options: [
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
            ]
            defaultValue: 1
        },
        Setting {
            key: "input.sensitivity"
            section: "Input"
            label: "Pointer speed"
            desc: "Added on top of the flat acceleration profile"
            control: Setting.Slider
            resettable: true
            min: -1
            max: 1
            step: 0.05
            defaultValue: 0
        },
        Setting {
            key: "input.touchpad.natural_scroll"
            section: "Input"
            label: "Natural scrolling"
            desc: "Touchpad content follows your fingers"
            control: Setting.Switch
            defaultValue: false
        }
    ]

    function toLua(): string {
        let tree = {};
        for (let key in values) {
            if (settings.find(setting => setting.key === key)?.hyprOption === false)
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

hl.env("XCURSOR_THEME", ${literal(cursorTheme, 0)})
hl.env("XCURSOR_SIZE", "${cursorSize}")
hl.env("HYPRCURSOR_THEME", ${literal(cursorTheme, 0)})
hl.env("HYPRCURSOR_SIZE", "${cursorSize}")

hl.config(${literal(tree, 0)})
if yonux.apply_animations then yonux.apply_animations() end
`;
    }

    function applyCursor(): void {
        if (!ready || !cursorTheme || cursorApply.running)
            return;

        cursorApply.theme = cursorTheme;
        cursorApply.size = cursorSize;
        cursorApply.environment = cursorEnvironment;
        cursorApply.command = ["sh", "-c", `
            hyprctl setcursor "$XCURSOR_THEME" "$XCURSOR_SIZE" &&
            dbus-update-activation-environment --systemd XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE
        `];
        cursorApply.running = true;
    }

    Process {
        id: cursorApply
        property string theme: ""
        property int size: 22
        stderr: StdioCollector {
            id: cursorError
        }
        onExited: code => {
            if (code !== 0)
                Alerts.error("Could not apply the cursor settings", cursorError.text.trim() || "Exit code: " + code);
            else
                root.cursorApplied();
            if (theme !== root.cursorTheme || size !== root.cursorSize)
                cursorCommit.restart();
        }
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
