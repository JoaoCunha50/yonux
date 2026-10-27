import QtQuick
import QtQuick.Layouts
import yonux.components
import yonux.theme

Rectangle {
    id: root

    property string icon
    property string label
    property string detail
    property bool active: false

    signal clicked

    implicitHeight: 56
    radius: Theme.radius.lg
    color: {
        if (active)
            return area.pressed ? Qt.darker(Theme.colors.active, 1.1) : Theme.colors.active;
        if (area.pressed)
            return Theme.colors.controlPressedFill;
        return area.containsMouse ? Theme.colors.controlHoverFill : Theme.colors.field;
    }

    Behavior on color {
        ColorAnimation {
            duration: Motion.small
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.md
        anchors.rightMargin: Theme.spacing.md
        spacing: Theme.spacing.sm

        ShellIcon {
            icon.name: root.icon
            icon.size: 20
            icon.color: root.active ? Theme.colors.onActive : Theme.colors.fg
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            UIText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.pixelSize: Theme.font.label.medium
                font.weight: Font.DemiBold
                color: root.active ? Theme.colors.onActive : Theme.colors.fg
            }

            UIText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.detail
                elide: Text.ElideRight
                font.pixelSize: Theme.font.label.small
                color: root.active ? Theme.colors.onActive : Theme.colors.fgMuted
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
