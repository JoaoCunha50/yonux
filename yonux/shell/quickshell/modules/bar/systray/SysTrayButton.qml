pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import yonux.theme
import yonux.components
import yonux.modules.bar.tray

ShellButton {
    id: root

    required property SystemTrayItem modelData

    implicitWidth: 26
    implicitHeight: 26
    radius: width / 1.5
    showDefaultContent: false
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    color: {
        let c = Theme.colors.active;
        if (pressed)
            return Qt.rgba(c.r, c.g, c.b, 0.35);
        if (anchor.popupOpen || hovered)
            return Qt.rgba(c.r, c.g, c.b, 0.25);
        return "transparent";
    }

    TrayAnchor {
        id: anchor
        hovered: root.hovered
        hoverText: root.modelData.tooltipTitle || root.modelData.title || root.modelData.id
        popup: root.modelData.hasMenu ? menuComponent : null
    }

    Component {
        id: menuComponent
        TrayMenu {
            handle: root.modelData.menu // qmllint disable unresolved-type
        }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 20
        source: root.modelData.icon
    }

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            root.modelData.secondaryActivate();
        else if (mouse.button === Qt.LeftButton || root.modelData.onlyMenu)
            anchor.togglePopup();
        else
            root.modelData.activate();
    }
}
