import QtQuick
import Quickshell
import Quickshell.Wayland
import yonux.theme
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

    ToastStack {}

    SettingsWindow {
        id: settings
    }

    Shortcuts {
        settingsWindow: settings
    }
}
