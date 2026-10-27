pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import yonux.components
import yonux.theme

Item {
    id: root

    property Item target: parent
    property Component popup: null
    property Component hover: null
    property string hoverText: ""
    property bool hovered: false

    property TrayPopup _popup: null
    property TrayPopup _hover: null

    property string key: ""
    readonly property string screenName: (QsWindow.window as QsWindow)?.screen?.name ?? ""
    readonly property bool popupOpen: key !== "" && OverlayManager.isOpen(key, screenName)

    visible: false

    Component.onCompleted: key = OverlayManager.token("tray")

    onHoveredChanged: hovered ? hoverTimer.restart() : hideHover()

    onPopupOpenChanged: if (_popup)
        _popup.open = popupOpen

    function togglePopup(): void {
        if (!popup)
            return;
        if (!_popup)
            _popup = popup.createObject(target, {
                anchorItem: target
            });
        hideHover();
        OverlayManager.toggle(key, screenName);
    }

    Connections {
        target: root._popup
        function onOpenChanged(): void {
            if (!root._popup.open && root.popupOpen)
                OverlayManager.close(root.screenName);
        }
    }

    function showHover(): void {
        if (popupOpen)
            return;
        if (!_hover) {
            let component = hover ?? (hoverText !== "" ? defaultHover : null);
            if (!component)
                return;
            _hover = component.createObject(target, {
                anchorItem: target
            });
        }
        _hover.open = true;
    }

    function hideHover(): void {
        hoverTimer.stop();
        if (_hover)
            _hover.open = false;
    }

    Component {
        id: defaultHover
        TrayHover {
            text: root.hoverText
        }
    }

    Timer {
        id: hoverTimer
        interval: Motion.hoverDelay
        onTriggered: root.showHover()
    }
}
