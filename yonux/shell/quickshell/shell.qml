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

    ToastStack {}

    SettingsWindow {
        id: settings
    }

    Shortcuts {
        settingsWindow: settings
    }
}
