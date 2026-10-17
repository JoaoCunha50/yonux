import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules.bar.tray

TrayItem {
    id: root

    icon.name: Notifications.dnd ? Icons.notificationsOff : Icons.notifications
    clickable: true
    hoverText: Notifications.dnd ? "Do not disturb" : "Notifications"
    onClicked: OverlayManager.toggle("controlcenter")

    Rectangle {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 6
        anchors.verticalCenterOffset: -6
        width: 7
        height: 7
        radius: width / 2
        visible: Notifications.unread && !Notifications.viewing
        color: Theme.colors.active
        border.color: Theme.colors.bg
        border.width: 1
    }
}
