import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    required property string file
    required property var schema

    readonly property string dir: config.dir
    readonly property var values: config.values
    readonly property bool ready: config.ready

    readonly property var defaults: {
        let result = {};
        for (let row of schema)
            if (row.def !== undefined)
                result[row.key] = row.def;
        return result;
    }

    signal edited(key: string)

    function value(key: string): var {
        return config.value(key);
    }

    function set(key: string, value: var): void {
        config.set(key, value);
        edited(key);
    }

    function reset(key: string): void {
        set(key, JSON.parse(JSON.stringify(defaults[key])));
    }

    function modified(key: string): bool {
        return !config.isDefault(key);
    }

    function shown(row: var): bool {
        return !row.when || value(row.when.key) === row.when.value;
    }

    JsonConfig {
        id: config
        file: root.file
        defaults: root.defaults
    }
}
