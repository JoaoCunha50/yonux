import QtQuick
import yonux.theme
import yonux.services
import yonux.modules.bar.tray

TrayItem {
    icon.name: Icons.cpu
    text: `${SystemStats.cpuPercent}%`
    alert: SystemStats.cpuPercent > 80
    hoverText: `Load average: ${SystemStats.loadAverage}`
}
