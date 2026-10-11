pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

PanelWindow { // qmllint disable uncreatable-type
    id: root

    readonly property int gap: HyprSettings.value("general.gaps_out")

    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null
    visible: Notifications.popupIds.length > 0 || column.height > 0

    WlrLayershell.namespace: "yonux-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins {
        top: gap
        right: gap
    }

    implicitWidth: 380
    mask: Region {
        item: column
    }
    color: "transparent"

    Column {
        id: column
        width: parent.width

        Repeater {
            model: Notifications.model

            NotificationToast {
                width: column.width
            }
        }
    }
}
