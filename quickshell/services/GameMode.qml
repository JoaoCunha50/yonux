pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool ready: false

    function toggle(): void {
        let config = Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`;
        Quickshell.execDetached([`${config}/hypr/scripts/game-mode`, "toggle", "--quiet"]);
    }

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/yonux-game-mode`
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            root.active = true;
            root.ready = true;
        }
        onLoadFailed: {
            root.active = false;
            root.ready = true;
        }
    }
}
