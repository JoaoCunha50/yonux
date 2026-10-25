import QtQuick
import qs.theme
import qs.services
import qs.modules.bar.tray

TrayItem {
    alert: Network.limited
    hoverText: Network.limited ? `${Network.label} · no internet` : Network.label
    icon.name: {
        if (Network.limited)
            return Icons.wifiBad;
        if (Network.ethernet)
            return Icons.ethernet;
        if (!Network.connected)
            return Icons.wifiOff;
        if (Network.signal >= 0.75)
            return Icons.wifi;
        if (Network.signal >= 0.5)
            return Icons.wifi3;
        if (Network.signal >= 0.25)
            return Icons.wifi2;
        return Icons.wifi1;
    }
}
