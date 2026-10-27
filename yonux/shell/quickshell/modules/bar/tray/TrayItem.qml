pragma ComponentBehavior: Bound
import QtQuick
import yonux.theme
import yonux.components

ShellButton {
    id: root

    property bool shown: true
    property bool fillWidth: false
    property int textSize: Theme.font.label.medium
    property bool alert: false

    property string overlay: ""

    property alias popup: anchor.popup
    property alias hover: anchor.hover
    property alias hoverText: anchor.hoverText
    clickable: popup !== null || overlay !== ""
    showDefaultContent: false

    property Item contentItem: null

    readonly property bool hasLabel: icon.name !== "" || text !== ""
    readonly property alias popupOpen: anchor.popupOpen
    readonly property color labelColor: active ? Theme.colors.onActive : alert ? Theme.colors.alert : Theme.colors.fg

    active: overlay !== "" ? OverlayManager.isOpen(overlay, anchor.screenName) : popupOpen
    icon.color: labelColor

    implicitWidth: hasLabel ? row.implicitWidth + (clickable ? 12 : 0) : contentItem?.implicitWidth ?? 0
    implicitHeight: hasLabel ? 30 : contentItem?.implicitHeight ?? 0
    color: {
        if (!clickable)
            return "transparent";
        if (active)
            return Theme.colors.active;
        if (pressed)
            return Theme.colors.controlPressedFill;
        if (hovered)
            return Theme.colors.controlHoverFill;
        return "transparent";
    }

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        if (overlay !== "")
            OverlayManager.toggle(overlay, anchor.screenName);
        else
            anchor.togglePopup();
    }

    onContentItemChanged: {
        if (!contentItem)
            return;
        contentItem.parent = root;
        contentItem.anchors.fill = root;
    }

    TrayAnchor {
        id: anchor
        hovered: root.hovered
    }

    Item {
        id: row
        x: Math.round((root.width - width) / 2)
        height: root.height
        implicitWidth: (iconItem.visible ? iconItem.implicitWidth : 0) + (iconItem.visible && label.visible ? 5 : 0) + (label.visible ? label.implicitWidth : 0)
        width: implicitWidth
        visible: root.hasLabel

        ShellIcon {
            id: iconItem
            icon: root.icon
            anchors.verticalCenter: parent.verticalCenter
            visible: icon.name !== ""
        }

        UIText {
            id: label
            anchors.left: iconItem.visible ? iconItem.right : parent.left
            anchors.leftMargin: iconItem.visible ? 5 : 0
            anchors.baseline: parent.verticalCenter
            anchors.baselineOffset: capOffset
            visible: root.text !== ""
            text: root.text
            color: root.labelColor
            font.pixelSize: root.textSize
            font.weight: 550
        }
    }
}
