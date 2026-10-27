import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import yonux.theme
import yonux.components
import yonux.config
import yonux.modules.bar
import yonux.modules.launcher
import yonux.modules.notifications
import yonux.modules.power
import yonux.modules.controlcenter
import yonux.modules.wallpaper
import yonux.modules.settings

ShellRoot {
    Component.onCompleted: Keybindings.refresh()

    WallpaperBackground {}

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: perScreen
            required property ShellScreen modelData

            PanelWindow { // qmllint disable uncreatable-type
                screen: perScreen.modelData
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

            AppLauncher {
                screen: perScreen.modelData
            }

            PowerMenu {
                screen: perScreen.modelData
            }

            ControlCenter {
                screen: perScreen.modelData
            }
        }
    }

    // Registered once here, not per overlay instance; each toggles the focused monitor.
    GlobalShortcut { // qmllint disable unresolved-type
        appid: "yonux"
        name: "launcher"
        onPressed: OverlayManager.toggle("launcher", "")
    }

    GlobalShortcut { // qmllint disable unresolved-type
        appid: "yonux"
        name: "power"
        onPressed: OverlayManager.toggle("power", "")
    }

    GlobalShortcut { // qmllint disable unresolved-type
        appid: "yonux"
        name: "controlcenter"
        onPressed: OverlayManager.toggle("controlcenter", "")
    }

    ToastStack {}

    SettingsWindow {}
}
