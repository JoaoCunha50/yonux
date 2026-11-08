pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool _dirty: false
    function sync(): void {
        if (syncProc.running) {
            root._dirty = true;
            return;
        }
        syncProc.running = true;
    }

    Process {
        id: syncProc
        command: ["yonux-ipc", "appimages"]

        onRunningChanged: {
            if (!running && root._dirty) {
                root._dirty = false;
                root.sync();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "")
                    console.warn("yonux-ipc appimages:", this.text.trim());
            }
        }
    }
}
