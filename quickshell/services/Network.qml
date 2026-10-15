pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property NetworkDevice wired: devices.find(device => device.type === DeviceType.Wired && device.connected) ?? null
    readonly property WifiDevice wifi: devices.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property WifiNetwork wifiNetwork: wifi?.networks.values.find(network => network.connected) ?? null

    readonly property bool ethernet: wired !== null
    readonly property bool connected: ethernet || wifiNetwork !== null
    readonly property bool limited: connected && (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal)
    readonly property real signal: wifiNetwork?.signalStrength ?? 0
    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property string label: {
        if (ethernet)
            return `Ethernet · ${wired.name}`;
        if (wifiNetwork)
            return `${wifiNetwork.name} · ${Math.round(signal * 100)}%`;
        if (wifi && !Networking.wifiEnabled)
            return "Wi-Fi off";
        return "Disconnected";
    }

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
