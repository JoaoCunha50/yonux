pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme
import qs.components

PanelWindow { // qmllint disable uncreatable-type
    id: root

    enum Placement {
        Center,
        Right
    }

    required property string name
    property int placement: Overlay.Center
    property bool dim: false
    property int padding: Theme.overlay.padding
    property int panelWidth: 400
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

    onVisibleChanged: if (visible)
        opened()

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

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: card.width
        height: card.height

        shown: root.open
        window: root

        Keys.onEscapePressed: root.close()
        onAboutToShow: root.screen = root.focusedScreen()
        onHidden: root.hidden()

        Rectangle {
            id: card
            width: body.childrenRect.width + root.padding * 2
            height: body.childrenRect.height + root.padding * 2
            color: Theme.colors.surface
            radius: Theme.radius.xl
            border.color: Theme.colors.border
            border.width: 1
        }

        DockedSurface {
            id: docked
            anchors.fill: parent
            visible: false
        }

        MouseArea {
            anchors.fill: body
            anchors.margins: -root.padding
            preventStealing: true
        }

        Item {
            id: body
            x: root.padding
            y: root.padding
            width: childrenRect.width
            height: childrenRect.height
        }

        states: State {
            name: "right"
            when: root.placement === Overlay.Right

            AnchorChanges {
                target: reveal
                anchors.horizontalCenter: undefined
                anchors.verticalCenter: undefined
                anchors.top: reveal.parent.top
                anchors.right: reveal.parent.right
                anchors.bottom: reveal.parent.bottom
            }

            PropertyChanges {
                reveal.width: root.panelWidth + docked.corner
                reveal.hiddenScale: 1
                reveal.hiddenOffset: 0
                reveal.hiddenOffsetX: reveal.width
                reveal.hiddenOpacity: 1

                card.visible: false
                docked.visible: true
                body.x: docked.corner + root.padding
                body.width: root.panelWidth - root.padding * 2
                body.height: reveal.height - root.padding * 2
            }
        }
    }
}
