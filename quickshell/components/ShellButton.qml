import QtQuick
import qs.theme

Rectangle {
    id: root

    property string text
    property alias icon: iconItem.icon
    property bool muted: false

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed
    readonly property color contentColor: !enabled || (muted && !hovered) ? Theme.colors.fgMuted : Theme.colors.fg

    readonly property int padding: muted ? Theme.spacing.sm : Theme.spacing.md
    readonly property int iconInset: iconItem.visible ? Math.round(iconItem.icon.size / 12) : 0

    signal clicked

    implicitWidth: row.implicitWidth + padding * 2 - iconInset
    implicitHeight: 30
    radius: Theme.radius.sm
    color: {
        if (!enabled)
            return "transparent";
        if (pressed)
            return Theme.colors.controlPressedFill;
        if (hovered)
            return Theme.colors.controlHoverFill;
        return muted ? "transparent" : Theme.colors.field;
    }

    Row {
        id: row
        x: root.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.xs

        UIText {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: root.text
            font.pixelSize: Theme.font.label.medium
            color: root.contentColor
        }

        ShellIcon {
            id: iconItem
            anchors.verticalCenter: parent.verticalCenter
            visible: icon.name !== ""
            icon.size: 18
            icon.color: root.contentColor
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
