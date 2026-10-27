pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var current: ({})
    property int _tokens: 0

    readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
    readonly property HyprlandWorkspace workspace: special ? Hyprland.workspaces.values.find(ws => ws.name === special) ?? null : monitor?.activeWorkspace ?? null

    readonly property string special: monitor?.lastIpcObject.specialWorkspace?.name ?? ""
    readonly property bool fullscreen: workspace?.toplevels.values.some(toplevel => toplevel.lastIpcObject?.fullscreen > 1) === true

    signal settingsRequested

    onFullscreenChanged: if (fullscreen)
        close(monitor?.name ?? "")

    function token(prefix: string): string {
        _tokens += 1;
        return `${prefix}:${_tokens}`;
    }

    function currentOn(screen: string): string {
        return current[screen] ?? "";
    }

    function isOpen(name: string, screen: string): bool {
        return currentOn(screen) === name;
    }

    function isOpenAnywhere(name: string): bool {
        return Object.values(current).includes(name);
    }

    function set(screen: string, name: string): void {
        let next = Object.assign({}, current);
        if (name === "")
            delete next[screen];
        else
            next[screen] = name;
        current = next;
    }

    function open(name: string, screen: string): void {
        screen = screen || (monitor?.name ?? "");
        const isMonitorFullscreen = fullscreen && screen === monitor?.name;
        if (!isMonitorFullscreen)
            set(screen, name);
    }

    function close(screen: string): void {
        const nameToClose = screen || (monitor?.name ?? "");
        set(nameToClose, "");
    }

    function toggle(name: string, screen: string): void {
        screen = screen || (monitor?.name ?? "");
        if (isOpen(name, screen))
            close(screen);
        else
            open(name, screen);
    }

    Component.onCompleted: {
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (["fullscreen", "openwindow", "closewindow", "movewindow"].includes(event.name))
                Hyprland.refreshToplevels();
            else if (["activespecial", "focusedmon", "workspace"].includes(event.name))
                Hyprland.refreshMonitors();
        }
    }
}
