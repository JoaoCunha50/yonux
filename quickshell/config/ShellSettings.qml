pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.theme

SettingsStore {
    id: root

    file: "shell.json"

    // Only on explicit changes, so a fresh install never overrides GTK fonts the user picked elsewhere
    onEdited: key => {
        if (key.startsWith("font."))
            applyGtkFont();
    }

    settings: [
        Setting {
            key: "theme.scheme"
            section: "Theme"
            label: "Color scheme"
            desc: "How matugen turns the wallpaper into a palette"
            control: Setting.Select
            resettable: true
            options: [
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
            ]
            defaultValue: "scheme-tonal-spot"
        },
        Setting {
            key: "font.scale"
            section: "Theme"
            label: "Font size"
            desc: "Scales every text size in the shell and GTK apps"
            control: Setting.Slider
            resettable: true
            min: 0.8
            max: 1.5
            step: 0.05
            percent: true
            defaultValue: 1
        },
        Setting {
            key: "theme.radius"
            section: "Theme"
            label: "Shell corners"
            desc: "Roundness of the bar, popups and controls"
            control: Setting.Slider
            resettable: true
            min: 0
            max: 2
            step: 0.05
            percent: true
            defaultValue: 1
        },
        Setting {
            key: "bar.height"
            section: "Bar"
            label: "Bar height"
            desc: "Text and icons keep their size"
            control: Setting.Slider
            resettable: true
            min: 32
            max: 56
            step: 1
            defaultValue: 40
        },
        Setting {
            key: "notifications.timeout"
            section: "Notifications"
            label: "Notification timeout"
            desc: "Seconds a notification stays on screen unless the app sets its own. Critical ones stay until closed"
            control: Setting.Slider
            resettable: true
            min: 2
            max: 15
            step: 1
            defaultValue: 5
        }
    ]

    function applyGtkFont(): void {
        let size = Math.round(11 * value("font.scale"));
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "font-name", `${Theme.font.family} ${size}`]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "monospace-font-name", `${Theme.font.mono} ${size}`]);
    }
}
