pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

SettingsStore {
    id: root

    readonly property var fontFamilies: [...new Set(Qt.fontFamilies())].sort((a, b) => a.localeCompare(b))
    property var monoFamilies: []

    file: "shell.json"

    // Only on explicit changes, so a fresh install never overrides GTK fonts the user picked elsewhere
    onEdited: key => {
        if (key.startsWith("font."))
            applyGtkFont();
    }

    schema: [
        {
            section: "Theme",
            key: "wallpaper",
            label: "Wallpaper",
            desc: "The colour palette is generated from it",
            control: "wallpaper"
        },
        {
            section: "Theme",
            key: "theme.scheme",
            label: "Color scheme",
            desc: "How matugen turns the wallpaper into a palette",
            control: "select",
            resettable: true,
            opts: [
                {
                    value: "scheme-tonal-spot",
                    label: "Tonal spot"
                },
                {
                    value: "scheme-content",
                    label: "Content"
                },
                {
                    value: "scheme-expressive",
                    label: "Expressive"
                },
                {
                    value: "scheme-fidelity",
                    label: "Fidelity"
                },
                {
                    value: "scheme-fruit-salad",
                    label: "Fruit salad"
                },
                {
                    value: "scheme-monochrome",
                    label: "Monochrome"
                },
                {
                    value: "scheme-neutral",
                    label: "Neutral"
                },
                {
                    value: "scheme-rainbow",
                    label: "Rainbow"
                },
                {
                    value: "scheme-vibrant",
                    label: "Vibrant"
                },
                {
                    value: "scheme-smart",
                    label: "Smart"
                }
            ],
            def: "scheme-tonal-spot"
        },
        {
            section: "Theme",
            key: "font.family",
            label: "Font",
            desc: "Used by the shell and GTK apps",
            control: "font",
            resettable: true,
            def: "Google Sans Flex"
        },
        {
            section: "Theme",
            key: "font.mono",
            label: "Monospace font",
            desc: "Used by the shell and as the GTK monospace font",
            control: "font",
            mono: true,
            resettable: true,
            def: "JetBrainsMono Nerd Font"
        },
        {
            section: "Theme",
            key: "font.scale",
            label: "Font size",
            desc: "Scales every text size in the shell and GTK apps",
            control: "slider",
            resettable: true,
            min: 0.8,
            max: 1.5,
            step: 0.05,
            percent: true,
            def: 1
        },
        {
            section: "Theme",
            key: "theme.radius",
            label: "Shell corners",
            desc: "Roundness of the bar, popups and controls",
            control: "slider",
            resettable: true,
            min: 0,
            max: 2,
            step: 0.05,
            percent: true,
            def: 1
        },
        {
            section: "Bar",
            key: "bar.height",
            label: "Bar height",
            desc: "Text and icons keep their size",
            control: "slider",
            resettable: true,
            min: 32,
            max: 56,
            step: 1,
            def: 40
        },
        {
            section: "Notifications",
            key: "notifications.timeout",
            label: "Notification timeout",
            desc: "Seconds a notification stays on screen unless the app sets its own. Critical ones stay until closed",
            control: "slider",
            resettable: true,
            min: 2,
            max: 15,
            step: 1,
            def: 5
        }
    ]

    function applyGtkFont(): void {
        let size = Math.round(11 * value("font.scale"));
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "font-name", `${value("font.family")} ${size}`]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "monospace-font-name", `${value("font.mono")} ${size}`]);
    }

    Process {
        running: true
        command: ["fc-list", ":spacing=mono:scalable=true", "family"]

        stdout: StdioCollector {
            onStreamFinished: {
                let families = this.text.split("\n").map(line => line.split(",")[0].trim()).filter(name => name !== "" && !name.includes("Emoji"));
                root.monoFamilies = [...new Set(families)].sort((a, b) => a.localeCompare(b));
            }
        }
    }
}
