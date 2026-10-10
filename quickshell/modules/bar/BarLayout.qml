pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property alias config: config

    readonly property list<string> left: config.values.left
    readonly property list<string> center: config.values.center
    readonly property list<string> right: config.values.right

    JsonConfig {
        id: config
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/yonux/bar.json"
        defaults: ({
                left: ["workspaces", "separator"],
                center: ["clock"],
                right: ["tray", "cpu", "memory", "disk", "temperature", "battery", "network", "audio", "power"]
            })
    }
}
