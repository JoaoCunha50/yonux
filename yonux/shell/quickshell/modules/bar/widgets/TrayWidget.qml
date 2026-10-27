import QtQuick
import Quickshell.Services.SystemTray
import yonux.modules.bar.tray
import yonux.modules.bar.systray

TrayItem {
    shown: SystemTray.items.values.length > 0

    contentItem: SysTray {}
}
