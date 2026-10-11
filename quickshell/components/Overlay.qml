pragma ComponentBehavior: Bound
import QtQuick
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
        anchors.centerIn: parent
        width: surface.width
        height: surface.height
        shown: root.open

        Keys.onEscapePressed: root.close()

        onActiveChanged: {
            if (active)
                return;
            root.visible = false;
            root.hidden();
        }

        Rectangle {
            id: surface
            width: body.childrenRect.width + root.padding * 2
            height: body.childrenRect.height + root.padding * 2

            color: Theme.colors.surface
            radius: Theme.radius.xl
            border.color: Theme.colors.border
            border.width: 1

            MouseArea {
                anchors.fill: parent
                preventStealing: true
            }

            Item {
                id: body
                x: root.padding
                y: root.padding
                width: childrenRect.width
                height: childrenRect.height
            }
        }
    }
}
