import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    required property string file
    property list<Setting> settings: []

    readonly property string dir: config.dir
    readonly property var values: config.values
    readonly property bool ready: config.ready

    readonly property var defaults: {
        let result = {};
        for (let setting of settings)
            if (setting.defaultValue !== undefined)
                result[setting.key] = setting.defaultValue;
        return result;
    }

    signal edited(key: string)

    onSettingsChanged: settings.forEach(setting => setting.store = root)

    function inSection(section: string): var {
        return settings.filter(setting => setting.section === section);
    }

    function value(key: string): var {
        return config.value(key);
    }

    function set(key: string, value: var): void {
        config.set(key, value);
        edited(key);
    }

    function reset(key: string): void {
        config.reset(key);
        edited(key);
    }

    function modified(key: string): bool {
        return !config.isDefault(key);
    }

    JsonConfig {
        id: config
        file: root.file
        defaults: root.defaults
    }
}
