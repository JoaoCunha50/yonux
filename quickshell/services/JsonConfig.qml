import QtQuick
import Quickshell.Io
import qs.services

Item {
    id: root

    required property string path
    required property var defaults

    property var values: defaults
    property bool ready: false

    readonly property string fileName: path.split("/").pop()

    visible: false

    function value(key: string): var {
        return values[key] ?? defaults[key];
    }

    function set(key: string, value: var): void {
        let next = Object.assign({}, values);
        next[key] = value;
        values = next;
        save();
    }

    function reset(key: string): void {
        set(key, JSON.parse(JSON.stringify(defaults[key])));
    }

    function isDefault(key: string): bool {
        return JSON.stringify(value(key)) === JSON.stringify(defaults[key]);
    }

    function save(): void {
        file.setText(JSON.stringify(values, null, 2) + "\n");
    }

    function apply(json: string): void {
        let parsed;
        try {
            parsed = JSON.parse(json);
        } catch (e) {
            Alerts.error(`${fileName} is invalid`, `${e}`);
            return;
        }

        let next = {};
        for (let key in defaults) {
            let fallback = defaults[key];
            let candidate = parsed?.[key];
            let valid = Array.isArray(fallback) ? Array.isArray(candidate) : typeof candidate === typeof fallback;
            if (candidate !== undefined && !valid)
                Alerts.error(`${fileName} has an invalid value`, key);
            next[key] = candidate !== undefined && valid ? candidate : fallback;
        }
        values = next;
        ready = true;
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.apply(text())
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            root.ready = true;
            root.save();
        }
    }
}
