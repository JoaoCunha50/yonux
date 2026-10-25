import QtQuick
import qs.theme
import qs.components
import qs.modules.bar.tray

TrayItem {
    icon.name: Icons.power
    icon.weight: 600
    clickable: true
    active: OverlayManager.current === "power"
    hoverText: "Power"
    onClicked: OverlayManager.toggle("power")
}
