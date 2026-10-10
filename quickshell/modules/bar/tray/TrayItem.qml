pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

Item {
    id: root

    property bool shown: true
    property bool fillWidth: false

    property alias icon: iconItem.icon
    property string text: ""
    property int textSize: Theme.font.label.medium

    property bool alert: false

    property alias popup: anchor.popup
    property alias hover: anchor.hover
    property alias hoverText: anchor.hoverText
    property bool clickable: popup !== null

    property Item contentItem: null

    readonly property bool hasLabel: icon.name !== "" || text !== ""
    readonly property alias popupOpen: anchor.popupOpen
    readonly property color contentColor: popupOpen ? Theme.colors.onActive : alert ? Theme.colors.alert : Theme.colors.fg

    signal clicked

    implicitWidth: hasLabel ? row.implicitWidth + (clickable ? 12 : 0) : contentItem?.implicitWidth ?? 0
    implicitHeight: hasLabel ? 30 : contentItem?.implicitHeight ?? 0

    onContentItemChanged: {
        if (!contentItem)
            return;
        contentItem.parent = root;
        contentItem.anchors.fill = root;
    }

    PopupAnchor {
        id: anchor
        hovered: hoverHandler.hovered
    }

    Rectangle {
        anchors.fill: parent
        visible: root.clickable
        radius: Theme.radius.sm
        color: {
            if (root.popupOpen)
                return Theme.colors.active;
            if (tapHandler.pressed)
                return Theme.colors.controlPressedFill;
            if (hoverHandler.hovered)
                return Theme.colors.controlHoverFill;
            return "transparent";
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        visible: root.hasLabel
        spacing: 5

        ShellIcon {
            id: iconItem
            visible: icon.name !== ""
            icon.size: 18
            icon.color: root.contentColor
        }

        UIText {
            visible: root.text !== ""
            text: root.text
            color: root.contentColor
            font.pixelSize: root.textSize
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tapHandler
        enabled: root.clickable
        onTapped: {
            root.clicked();
            anchor.togglePopup();
        }
    }
}
