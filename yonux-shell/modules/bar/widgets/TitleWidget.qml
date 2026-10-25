import QtQuick
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.modules.bar.tray

TrayItem {
    fillWidth: true

    contentItem: UIText {
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        padding: 5
        font.pixelSize: Theme.font.body.small
        text: Hyprland.activeToplevel?.title ?? `Workspace ${Hyprland.focusedWorkspace?.name ?? "?"}`
    }
}
