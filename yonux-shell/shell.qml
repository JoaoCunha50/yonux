import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.config
import qs.modules.bar
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.power
import qs.modules.controlcenter
import qs.modules.wallpaper
import qs.modules.settings

ShellRoot {
    Component.onCompleted: Keybindings.refresh()

    WallpaperBackground {}

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "yonux-bar"
            anchors {
                top: true
                left: true
                right: true
            }
            color: "transparent"

            implicitHeight: Theme.bar.height
            exclusiveZone: Theme.bar.height

            Bar {}
        }
    }

    AppLauncher {}

    ToastStack {}

    PowerMenu {}

    ControlCenter {}

    SettingsWindow {}
}
