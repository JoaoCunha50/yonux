import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.services
import qs.modules.bar.tray

TrayItem {
    readonly property int pct: SystemStats.batteryPercent
    readonly property bool charging: SystemStats.batteryState === UPowerDeviceState.Charging

    shown: pct >= 0
    alert: pct >= 0 && pct <= 15
    text: `${pct}%`
    icon.name: {
        if (charging)
            return Icons.batteryCharging;
        if (pct <= 10)
            return Icons.batteryAlert;
        if (pct <= 20)
            return Icons.battery1;
        if (pct <= 40)
            return Icons.battery2;
        if (pct <= 60)
            return Icons.battery3;
        if (pct <= 80)
            return Icons.battery4;
        return Icons.batteryFull;
    }
    hoverText: {
        switch (SystemStats.batteryState) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        case UPowerDeviceState.FullyCharged:
            return "Full";
        case UPowerDeviceState.PendingCharge:
            return "Plugged in, not charging";
        default:
            return "";
        }
    }
}
