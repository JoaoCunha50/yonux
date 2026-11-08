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
    visible: Notifications.toasts.length > 0 || list.contentHeight > 0

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
        item: list
    }
    color: "transparent"

    ListView {
        id: list
        width: parent.width
        height: contentHeight
        interactive: false
        model: ScriptModel {
            values: Notifications.toasts
        }

        delegate: NotificationToast {
            width: ListView.view.width
        }
    }
}
