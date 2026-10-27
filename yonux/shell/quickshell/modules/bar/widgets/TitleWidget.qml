import QtQuick
import Quickshell.Hyprland
import yonux.theme
import yonux.components
import yonux.modules.bar.tray

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
