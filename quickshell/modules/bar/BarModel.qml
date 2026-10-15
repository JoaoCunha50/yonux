pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.theme
import qs.services
import qs.components
import qs.modules.bar
import qs.modules.bar.tray
import qs.modules.bar.widgets
import qs.modules.bar.systray

Singleton {
    id: root

    readonly property list<Component> left: resolve(BarLayout.left)
    readonly property list<Component> center: resolve(BarLayout.center)
    readonly property list<Component> right: resolve(BarLayout.right)

    readonly property var items: ({
            workspaces: workspaces,
            tray: tray,
            separator: separator,
            title: title,
            clock: clock,
            audio: audio,
            network: network,
            cpu: cpu,
            memory: memory,
            disk: disk,
            temperature: temperature,
            battery: battery,
            notifications: notifications,
            power: power
        })

    function resolve(ids: var): var {
        return ids.filter(id => {
            if (items[id])
                return true;
            Alerts.error("bar.json has an unknown item", id);
            return false;
        }).map(id => items[id]);
    }

    Component {
        id: workspaces
        WorkspacesWidget {}
    }

    Component {
        id: tray
        TrayItem {
            shown: SystemTray.items.values.length > 0

            contentItem: SysTray {}
        }
    }

    Component {
        id: separator
        TrayItem {
            contentItem: Rectangle {
                implicitWidth: 2
                implicitHeight: 18
                color: Theme.colors.active
            }
        }
    }

    Component {
        id: title
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
    }

    Component {
        id: clock
        ClockWidget {}
    }

    Component {
        id: audio
        AudioWidget {}
    }

    Component {
        id: network
        NetworkWidget {}
    }

    Component {
        id: cpu
        TrayItem {
            icon.name: Icons.cpu
            text: `${SystemStats.cpuPercent}%`
            alert: SystemStats.cpuPercent > 80
            hoverText: `Load average: ${SystemStats.loadAverage}`
        }
    }

    Component {
        id: memory
        TrayItem {
            icon.name: Icons.memory
            text: `${SystemStats.memoryPercent}%`
            alert: SystemStats.memoryPercent > 85
            hoverText: `${SystemStats.memoryUsedGiB.toFixed(1)} / ${SystemStats.memoryTotalGiB.toFixed(1)} GiB used`
        }
    }

    Component {
        id: disk
        TrayItem {
            icon.name: Icons.disk
            text: `${SystemStats.diskPercent}%`
            alert: SystemStats.diskPercent > 90
            hoverText: `${SystemStats.diskUsedGiB.toFixed(0)} / ${SystemStats.diskTotalGiB.toFixed(0)} GiB used on /`
        }
    }

    Component {
        id: temperature
        TrayItem {
            shown: SystemStats.temperature >= 0
            icon.name: Icons.temperature
            text: `${SystemStats.temperature}°C`
            alert: SystemStats.temperature > 80
        }
    }

    Component {
        id: battery
        BatteryWidget {}
    }

    Component {
        id: notifications
        NotificationsWidget {}
    }

    Component {
        id: power
        TrayItem {
            icon.name: Icons.power
            icon.weight: 600
            clickable: true
            hoverText: "Power"
            onClicked: OverlayManager.toggle("power")
        }
    }
}
