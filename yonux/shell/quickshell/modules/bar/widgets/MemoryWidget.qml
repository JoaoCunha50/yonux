import QtQuick
import qs.theme
import qs.services
import qs.modules.bar.tray

TrayItem {
    icon.name: Icons.memory
    text: `${SystemStats.memoryPercent}%`
    alert: SystemStats.memoryPercent > 85
    hoverText: `${SystemStats.memoryUsedGiB.toFixed(1)} / ${SystemStats.memoryTotalGiB.toFixed(1)} GiB used`
}
