import QtQuick
import yonux.config

QtObject {
    id: root

    enum Control {
        Switch,
        Slider,
        Segmented,
        Select
    }

    required property string key
    property string section
    property string label
    property string desc
    property int control: Setting.Switch
    property var options: []
    property var defaultValue
    property real min: 0
    property real max: 1
    property real step: 1
    property bool percent: false
    property bool resettable: false
    property bool shown: true
    property bool hyprOption: true

    property SettingsStore store: null
    readonly property var value: store ? store.value(key) : defaultValue
    readonly property bool modified: store ? store.modified(key) : false
    readonly property bool adjusting: commit.running

    function set(value: var): void {
        commit.stop();
        store.set(key, value);
    }

    function adjust(value: real): void {
        commit.pending = value;
        commit.restart();
    }

    function reset(): void {
        commit.stop();
        store.reset(key);
    }

    function format(value: real): string {
        if (percent)
            return `${Math.round(value * 100)}%`;
        return step < 1 ? value.toFixed(2) : `${Math.round(value)}`;
    }

    readonly property Timer commit: Timer {
        property real pending

        interval: 200
        onTriggered: root.store.set(root.key, Number(pending.toFixed(4)))
    }
}
