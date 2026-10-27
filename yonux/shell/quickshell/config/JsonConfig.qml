import QtQuick
import Quickshell
import yonux.config
import yonux.services

Scope {
    id: root

    required property string path
    required property var defaults

    property var values: defaults
    readonly property bool ready: file.loaded

    function value(key: string): var {
        return values[key] ?? defaults[key];
    }

    function set(key: string, value: var): void {
        let next = Object.assign({}, values);
        next[key] = value;
        values = next;
        file.save(values);
    }

    function reset(key: string): void {
        set(key, JSON.parse(JSON.stringify(defaults[key])));
    }

    function isDefault(key: string): bool {
        return JSON.stringify(value(key)) === JSON.stringify(defaults[key]);
    }

    function apply(document: var): void {
        if (document === null) {
            file.save(values);
            return;
        }

        let next = {};
        for (let key in defaults) {
            let fallback = defaults[key];
            let candidate = document[key];
            let valid = Array.isArray(fallback) ? Array.isArray(candidate) : typeof candidate === typeof fallback;
            if (candidate !== undefined && !valid)
                Alerts.error(`${file.name} has an invalid value`, key);
            next[key] = candidate !== undefined && valid ? candidate : fallback;
        }
        values = next;
    }

    JsonFile {
        id: file
        path: root.path
        watch: true
        onDocumentLoaded: if (!invalid)
            root.apply(document)
    }
}
