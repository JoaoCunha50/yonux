import QtQuick
import yonux.theme
import yonux.services
import yonux.modules.bar.tray

TrayItem {
    icon.name: Icons.disk
    text: `${SystemStats.diskPercent}%`
    alert: SystemStats.diskPercent > 90
    hoverText: `${SystemStats.diskUsedGiB.toFixed(0)} / ${SystemStats.diskTotalGiB.toFixed(0)} GiB used on /`
}
