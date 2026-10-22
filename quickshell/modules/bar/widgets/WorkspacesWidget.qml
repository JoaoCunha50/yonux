pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.modules.bar.tray

TrayItem {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen ?? null) // qmllint disable missing-property
    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor === root.monitor).sort((a, b) => a.id - b.id)

    contentItem: RowLayout {
        spacing: 0

        Repeater {
            model: ScriptModel {
                values: root.workspaces
            }

            delegate: ShellButton {
                id: button

                required property HyprlandWorkspace modelData
                active: root.monitor?.activeWorkspace === modelData
                showDefaultContent: false

                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: Theme.radius.sm
                color: "transparent"

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: Motion.small
                }

                UIText {
                    anchors.centerIn: parent
                    text: button.modelData.name
                    font.pixelSize: Theme.font.label.large
                    font.weight: button.active ? Font.DemiBold : Font.Normal
                    color: button.active ? Theme.colors.active : Theme.colors.fg
                }

                onClicked: button.modelData.activate()
            }
        }
    }
}
