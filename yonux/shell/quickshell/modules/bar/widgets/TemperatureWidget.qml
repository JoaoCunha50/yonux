import QtQuick
import yonux.theme
import yonux.services
import yonux.modules.bar.tray

TrayItem {
    shown: SystemStats.temperature >= 0
    icon.name: Icons.temperature
    text: `${SystemStats.temperature}°C`
    alert: SystemStats.temperature > 80
}
