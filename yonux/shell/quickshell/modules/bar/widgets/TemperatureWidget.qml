import QtQuick
import qs.theme
import qs.services
import qs.modules.bar.tray

TrayItem {
    shown: SystemStats.temperature >= 0
    icon.name: Icons.temperature
    text: `${SystemStats.temperature}°C`
    alert: SystemStats.temperature > 80
}
