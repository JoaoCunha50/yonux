import QtQuick
import yonux.theme
import yonux.services
import yonux.modules.bar.tray

TrayItem {
    icon.name: Icons.memory
    text: `${SystemStats.memoryPercent}%`
    alert: SystemStats.memoryPercent > 85
    hoverText: `${SystemStats.memoryUsedGiB.toFixed(1)} / ${SystemStats.memoryTotalGiB.toFixed(1)} GiB used`
}
