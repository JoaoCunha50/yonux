import QtQuick
import qs.theme
import qs.services
import qs.modules.bar.tray

TrayItem {
    icon.name: Icons.disk
    text: `${SystemStats.diskPercent}%`
    alert: SystemStats.diskPercent > 90
    hoverText: `${SystemStats.diskUsedGiB.toFixed(0)} / ${SystemStats.diskTotalGiB.toFixed(0)} GiB used on /`
}
