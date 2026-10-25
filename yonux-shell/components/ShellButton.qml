import QtQuick
import qs.theme

Rectangle {
    id: root

    enum Type {
        Filled,
        Tonal,
        Ghost,
        Muted
    }

    property int type: ShellButton.Filled
    property string text
    property alias icon: iconItem.icon
    property bool iconFirst: false
    property bool active: false
    property bool clickable: true
    property int acceptedButtons: Qt.LeftButton
    property bool showDefaultContent: true

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed
    readonly property bool iconOnly: text === ""

    readonly property color restingColor: ({
            [ShellButton.Filled]: Theme.colors.field,
            [ShellButton.Tonal]: Theme.colors.surface,
            [ShellButton.Ghost]: "transparent",
            [ShellButton.Muted]: "transparent"
        })[type]

    readonly property color contentColor: {
        if (!enabled)
            return Theme.colors.fgMuted;
        if (active)
            return Theme.colors.onActive;
        if (type === ShellButton.Muted && !hovered)
            return Theme.colors.fgMuted;
        return Theme.colors.fg;
    }

    readonly property int padding: type === ShellButton.Muted ? Theme.spacing.sm : Theme.spacing.md
    readonly property int iconInset: iconItem.visible && !iconOnly ? Math.round(iconItem.icon.size / 12) : 0

    signal clicked(mouse: MouseEvent)

    implicitWidth: iconOnly ? implicitHeight : label.implicitWidth + (iconItem.visible ? iconItem.width + row.spacing : 0) + padding * 2 - iconInset
    implicitHeight: 30
    radius: Theme.radius.sm
    color: {
        if (!enabled)
            return "transparent";
        if (pressed)
            return Theme.colors.controlPressedFill;
        if (active)
            return Theme.colors.active;
        if (hovered)
            return Theme.colors.controlHoverFill;
        return restingColor;
    }

    Row {
        id: row
        visible: root.showDefaultContent
        x: Math.round((root.width - width + root.iconInset) / 2) - (root.iconFirst ? root.iconInset : 0)
        anchors.verticalCenter: parent.verticalCenter
        layoutDirection: root.iconFirst ? Qt.RightToLeft : Qt.LeftToRight
        spacing: Theme.spacing.xs

        UIText {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.width - root.padding * 2 + root.iconInset - (iconItem.visible ? iconItem.width + row.spacing : 0))
            visible: text !== ""
            text: root.text
            elide: Text.ElideRight
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
        z: root.clickable ? 1 : -1
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: root.clickable ? root.acceptedButtons : Qt.NoButton
        cursorShape: root.clickable ? Qt.PointingHandCursor : undefined
        onClicked: mouse => root.clicked(mouse)
    }
}
