import QtQuick
import qs.theme
import qs.services
import qs.modules.bar.tray

TrayItem {
    icon.name: Icons.cpu
    text: `${SystemStats.cpuPercent}%`
    alert: SystemStats.cpuPercent > 80
    hoverText: `Load average: ${SystemStats.loadAverage}`
}
