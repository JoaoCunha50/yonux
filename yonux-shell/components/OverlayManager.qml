pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string current: ""

    readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
    readonly property HyprlandWorkspace workspace: special ? Hyprland.workspaces.values.find(ws => ws.name === special) ?? null : monitor?.activeWorkspace ?? null

    readonly property string special: monitor?.lastIpcObject.specialWorkspace?.name ?? ""
    readonly property bool fullscreen: workspace?.toplevels.values.some(toplevel => toplevel.lastIpcObject?.fullscreen > 1) === true

    signal settingsRequested

    onFullscreenChanged: if (fullscreen)
        close()

    function open(name: string): void {
        if (!fullscreen)
            current = name;
    }

    function close(): void {
        current = "";
    }

    function toggle(name: string): void {
        current = current === name || fullscreen ? "" : name;
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
