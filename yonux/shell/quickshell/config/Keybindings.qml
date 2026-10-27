pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import yonux.config
import yonux.services
import "KeybindingUtils.js" as Utils

Singleton {
    id: root

    readonly property string luaPath: `${Paths.config}/keybindings.lua`
    readonly property bool ready: config.ready
    readonly property var applications: DesktopEntries.applications.values.filter(app => !app.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var overrides: config.value("overrides").filter(validEntry)
    readonly property var custom: config.value("custom").filter(validEntry)
    property var defaults: []
    property var external: []
    readonly property var entries: custom.map(entry => Object.assign({ builtin: false }, entry)).concat(defaults.map(original => {
        const override = overrides.find(entry => entry.id === original.id);
        return Object.assign({}, original, override ?? {}, { builtin: true });
    }))

    onOverridesChanged: if (ready) writeLua.restart()
    onCustomChanged: if (ready) writeLua.restart()
    onApplicationsChanged: if (ready) writeLua.restart()
    onReadyChanged: if (ready) {
        refresh();
        writeLua.restart();
    }

    function validEntry(entry): bool {
        return entry && typeof entry.id === "string" && typeof entry.keys === "string"
            && typeof entry.title === "string" && ["default", "app", "command"].includes(entry.kind)
            && typeof entry.command === "string" && typeof entry.enabled === "boolean"
            && (entry.kind !== "app" || typeof entry.appId === "string");
    }

    function refresh(): void {
        if (!catalog.running) catalog.running = true;
    }

    function actionLabel(entry): string {
        if (entry.kind === "app")
            return applications.find(app => app.id === entry.appId)?.name ?? "Application not installed";
        if (entry.kind === "command")
            return (entry.terminal ? "Terminal · " : "") + entry.command;
        return "Desktop action";
    }

    function validate(entry): string {
        if (!entry.title.trim()) return "Give this shortcut a name.";
        const parts = entry.keys.split("+").map(part => part.trim());
        const key = parts.pop();
        if (!key || !/^(?:[a-z0-9_]+|code:[0-9]+|mouse:[0-9]+)$/i.test(key)
            || parts.some(part => !["SUPER", "CTRL", "CONTROL", "ALT", "SHIFT", "META"].includes(part.toUpperCase())))
            return "Choose a shortcut, for example SUPER + Return.";
        if (entry.enabled) {
            const collision = entries.find(other => other.id !== entry.id && other.enabled && Utils.canonical(other.keys) === Utils.canonical(entry.keys));
            if (collision) return "Already used by “" + collision.title + "”.";
            if (external.some(bind => Utils.canonical(Utils.keysFromBind(bind)) === Utils.canonical(entry.keys)))
                return "This shortcut is already defined elsewhere in your Hyprland configuration.";
        }
        if (entry.kind === "app" && !applications.some(app => app.id === entry.appId))
            return "Choose an installed application.";
        if (entry.kind === "command" && (!entry.command.trim() || entry.command.includes("\0")))
            return "Enter a command to run.";
        const original = defaults.find(original => original.id === entry.id);
        if (entry.kind === "default" && original?.mouse && !key.startsWith("mouse:"))
            return "This action needs a mouse button, for example SUPER + mouse:272.";
        return "";
    }

    function save(draft): string {
        const entry = {
            id: draft.id || "custom-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8),
            title: draft.title.trim(), keys: draft.keys.trim(), kind: draft.kind,
            appId: draft.appId ?? "", command: draft.command ?? "", terminal: draft.terminal === true,
            enabled: draft.enabled !== false
        };
        const error = validate(entry);
        if (error) return error;
        const builtin = defaults.some(original => original.id === entry.id);
        const key = builtin ? "overrides" : "custom";
        const next = (builtin ? overrides : custom).filter(other => other.id !== entry.id).concat(entry);
        config.set(key, next);
        return "";
    }

    function remove(id: string): void {
        config.set("custom", custom.filter(entry => entry.id !== id));
    }

    JsonConfig {
        id: config
        path: `${Paths.config}/keybindings.json`
        defaults: ({ overrides: [], custom: [] })
    }

    Process {
        id: catalog
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const binds = JSON.parse(text);
                    root.external = binds.filter(bind => !bind.submap && !bind.description?.startsWith("yonux-"));
                } catch (error) {
                    Alerts.error("Could not read keyboard shortcuts", String(error));
                }
            }
        }
    }

    FileView {
        id: defaultsFile
        path: `${Paths.config}/keybindings-catalog.json`
        printErrors: false
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.defaults = JSON.parse(text()).map(entry => Object.assign({
                    kind: "default", command: "", appId: "", terminal: false, enabled: true
                }, entry));
            } catch (error) {
                Alerts.error("Could not read default shortcuts", String(error));
            }
        }
    }

    Timer {
        id: writeLua
        interval: 100
        onTriggered: {
            const text = Utils.render(root.overrides, root.custom, root.applications);
            if (luaFile.text() !== text) luaFile.setText(text);
        }
    }

    FileView {
        id: luaFile
        path: root.luaPath
        blockLoading: true
        printErrors: false
        onSaved: reloadConfig.restart()
        onSaveFailed: error => Alerts.error("Could not save keyboard shortcuts", FileViewError.toString(error))
    }

    Timer {
        id: reloadConfig
        interval: 100
        onTriggered: {
            if (apply.running) restart();
            else apply.running = true;
        }
    }

    Process {
        id: apply
        command: ["hyprctl", "reload"]
        stderr: StdioCollector { id: applyError }
        onExited: code => {
            if (code !== 0) Alerts.error("Could not apply keyboard shortcuts", applyError.text.trim());
            root.refresh();
        }
    }
}
