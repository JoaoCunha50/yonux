import QtQuick
import qs.theme
import qs.modules.bar.tray
import qs.modules.bar

Rectangle {
    id: bar

    width: parent.width
    implicitHeight: Theme.bar.height
    color: Theme.colors.bg

    TrayArea {
        id: center
        anchors.centerIn: parent

        spacing: Theme.spacing.sm
        items: BarModel.center
    }

    TrayArea {
        anchors.left: parent.left
        anchors.right: center.left
        anchors.verticalCenter: parent.verticalCenter

        anchors.leftMargin: 15
        anchors.rightMargin: Theme.spacing.md

        spacing: 10
        items: BarModel.left
    }

    TrayArea {
        anchors.left: center.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        anchors.leftMargin: Theme.spacing.md
        anchors.rightMargin: 15

        alignEnd: true
        items: BarModel.right
    }
}
