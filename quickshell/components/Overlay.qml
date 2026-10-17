pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme
import qs.components

PanelWindow { // qmllint disable uncreatable-type
    id: root

    required property string name
    property bool dim: false
    property int padding: Theme.overlay.padding
    property bool docked: false
    property int dockedWidth: 400
    readonly property bool open: OverlayManager.current === name

    default property alias content: body.data

    signal opened
    signal hidden

    WlrLayershell.namespace: `yonux-${name}`
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false

    onOpenChanged: {
        if (!open)
            return;
        screen = focusedScreen();
        visible = true;
        opened();
    }

    function close(): void {
        if (open)
            OverlayManager.close();
    }

    function focusedScreen(): var {
        let monitor = Hyprland.focusedMonitor;
        return Quickshell.screens.find(screen => screen.name === monitor?.name) ?? Quickshell.screens[0] ?? null;
    }

    GlobalShortcut { // qmllint disable unresolved-type
        appid: "yonux"
        name: root.name
        onPressed: OverlayManager.toggle(root.name)
    }

    Rectangle {
        anchors.fill: parent
        visible: root.dim
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: reveal.opacity
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Reveal {
        id: reveal

        readonly property int corner: root.docked ? Theme.radius.xl : 0

        anchors.centerIn: root.docked ? undefined : parent
        anchors.top: root.docked ? parent.top : undefined
        anchors.right: root.docked ? parent.right : undefined
        anchors.bottom: root.docked ? parent.bottom : undefined

        width: surface.width + corner
        height: root.docked ? undefined : surface.height
        shown: root.open
        hiddenScale: root.docked ? 1 : Motion.revealScale
        hiddenOffset: root.docked ? 0 : Motion.revealOffset
        hiddenOffsetX: root.docked ? width : 0
        hiddenOpacity: root.docked ? 1 : 0

        Keys.onEscapePressed: root.close()

        onActiveChanged: {
            if (active)
                return;
            root.visible = false;
            root.hidden();
        }

        ConcaveCorner {
            visible: root.docked
        }

        ConcaveCorner {
            visible: root.docked
            anchors.bottom: parent.bottom
            atBottom: true
        }

        Rectangle {
            id: surface
            anchors.right: parent.right
            width: root.docked ? root.dockedWidth : body.childrenRect.width + root.padding * 2
            height: root.docked ? reveal.height : body.childrenRect.height + root.padding * 2

            color: root.docked ? Theme.colors.bg : Theme.colors.surface
            radius: root.docked ? 0 : Theme.radius.xl
            border.color: Theme.colors.border
            border.width: root.docked ? 0 : 1

            MouseArea {
                anchors.fill: parent
                preventStealing: true
            }

            Item {
                id: body
                x: root.padding
                y: root.padding
                width: root.docked ? surface.width - root.padding * 2 : childrenRect.width
                height: root.docked ? surface.height - root.padding * 2 : childrenRect.height
            }
        }
    }

    component ConcaveCorner: Shape {
        id: corner

        property bool atBottom: false
        readonly property real extent: reveal.corner

        width: extent
        height: extent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.colors.bg
            startX: corner.extent
            startY: corner.atBottom ? 0 : corner.extent

            PathLine {
                x: corner.extent
                y: corner.atBottom ? corner.extent : 0
            }
            PathLine {
                x: 0
                y: corner.atBottom ? corner.extent : 0
            }
            PathArc {
                x: corner.extent
                y: corner.atBottom ? 0 : corner.extent
                radiusX: corner.extent
                radiusY: corner.extent
                direction: corner.atBottom ? PathArc.Counterclockwise : PathArc.Clockwise
            }
        }
    }
}
