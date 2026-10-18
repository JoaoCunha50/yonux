pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

Singleton {
    id: root

    property bool active: false
    property bool ready: false

    function toggle(): void {
        toggler.running = true;
    }

    Process {
        id: toggler
        command: [`${Paths.hypr}/scripts/night-light`, "toggle"]
        stderr: StdioCollector {
            id: toggleError
        }
        onExited: code => {
            if (code !== 0)
                Alerts.error("Could not toggle the night light", toggleError.text.trim() || "Is hyprsunset running?");
        }
    }

    FileView {
        path: `${Paths.runtime}/yonux-night-light`
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
