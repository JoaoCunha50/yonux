import QtQuick
import qs.theme
import qs.modules.bar.tray

TrayItem {
    id: root

    property date now: new Date()

    text: Qt.formatDateTime(now, "ddd, dd MMM  hh:mm:ss")
    textSize: Theme.font.body.medium
    hoverText: Qt.formatDate(now, "dddd, d MMMM yyyy")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
