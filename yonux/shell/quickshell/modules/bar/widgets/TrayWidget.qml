import QtQuick
import Quickshell.Services.SystemTray
import qs.modules.bar.tray
import qs.modules.bar.systray

TrayItem {
    shown: SystemTray.items.values.length > 0

    contentItem: SysTray {}
}
