pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool active: false
    property bool ready: false

    function toggle(): void {
        Quickshell.execDetached([`${Paths.hypr}/scripts/game-mode`, "toggle", "--quiet"]);
    }

    FileView {
        path: `${Paths.runtime}/yonux-game-mode`
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
