import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components

PopupWindow {
    id: root

    property bool open: false
    property bool dismissOnClickOutside: false
    property Item anchorItem: null
    property int gap: 6
    property int padding: 12
    property int shadowPadding: 0
    property int shadowBlur: 16
    property real _offset: 0

    default property alias content: body.data
    readonly property Item body: body

    color: "transparent"
    visible: false
    mask: Region {
        item: surface
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom // qmllint disable missing-type
    anchor.gravity: Edges.Bottom // qmllint disable missing-type
    anchor.rect.width: anchorItem ? anchorItem.width : 0
    anchor.rect.height: anchorItem ? anchorItem.height + _offset : 0

    onVisibleChanged: if (!visible)
        open = false

    HyprlandFocusGrab {
        active: root.dismissOnClickOutside && root.open && root.visible
        windows: root.anchorItem ? [root, root.anchorItem.QsWindow.window] : [root]
        onCleared: root.open = false
    }

    Reveal {
        anchors.fill: parent
        shown: root.open
        window: root
        transformOrigin: Item.Top
        onAboutToShow: if (root.anchorItem)
            root._offset = Theme.bar.height - root.anchorItem.mapToItem(null, 0, 0).y - root.anchorItem.height + root.gap - root.shadowPadding

        RectangularShadow {
            anchors.fill: surface
            visible: root.shadowPadding > 0
            radius: surface.radius
            blur: root.shadowBlur
            offset.y: 4
            color: Qt.rgba(0, 0, 0, 0.35)
        }

        Rectangle {
            id: surface
            anchors.fill: parent
            anchors.margins: root.shadowPadding
            color: Theme.colors.bg
            radius: Theme.radius.md
        }

        Item {
            id: body
            anchors.fill: surface
            anchors.margins: root.padding
        }
    }
}
