pragma ComponentBehavior: Bound
import QtQuick
import qs.components
import qs.theme

Item {
    id: root

    property Item target: parent
    property Component popup: null
    property Component hover: null
    property string hoverText: ""
    property bool hovered: false

    property TrayPopup _popup: null
    property TrayPopup _hover: null

    readonly property bool popupOpen: _popup ? _popup.open : false

    visible: false

    onHoveredChanged: hovered ? hoverTimer.restart() : hideHover()

    function togglePopup(): void {
        if (!popup)
            return;
        if (!_popup)
            _popup = popup.createObject(target, {
                anchorItem: target
            });
        hideHover();
        if (!_popup.open)
            OverlayManager.close();
        _popup.open = !_popup.open;
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
