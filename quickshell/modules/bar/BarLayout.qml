pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property list<string> left: config.values.left
    readonly property list<string> center: config.values.center
    readonly property list<string> right: config.values.right
    readonly property var used: [...config.values.left, ...config.values.center, ...config.values.right]

    function move(section: string, index: int, delta: int): void {
        let ids = [...config.values[section]];
        let target = index + delta;
        if (target < 0 || target >= ids.length)
            return;
        [ids[index], ids[target]] = [ids[target], ids[index]];
        config.set(section, ids);
    }

    function remove(section: string, index: int): void {
        let ids = [...config.values[section]];
        ids.splice(index, 1);
        config.set(section, ids);
    }

    function add(section: string, id: string): void {
        config.set(section, [...config.values[section], id]);
    }

    JsonConfig {
        id: config
        file: "bar.json"
        defaults: ({
                left: ["workspaces", "separator"],
                center: ["clock"],
                right: ["tray", "cpu", "memory", "disk", "temperature", "battery", "network", "audio", "power"]
            })
    }
}
