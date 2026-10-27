import QtQuick
import Quickshell
import yonux.components
import yonux.modules.settings

// qmllint disable unresolved-type
Scope {
    id: root

    required property SettingsWindow settingsWindow

    YonuxShortcut {
        name: "launcher"
        onPressed: OverlayManager.toggleFocused("launcher")
    }

    YonuxShortcut {
        name: "power"
        onPressed: OverlayManager.toggleFocused("power")
    }

    YonuxShortcut {
        name: "controlcenter"
        onPressed: OverlayManager.toggleFocused("controlcenter")
    }

    YonuxShortcut {
        name: "settings"
        onPressed: root.settingsWindow.visible = !root.settingsWindow.visible
    }
}
