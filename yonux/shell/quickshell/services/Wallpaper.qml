pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import yonux.config
import yonux.services

Singleton {
    id: root

    readonly property string stateFile: `${Paths.state}/wallpaper`
    readonly property string legacyStateFile: `${Paths.stateHome}/current_wallpaper`
    property string path: ""

    function set(path: string): void {
        validator.candidate = path;
        validator.running = true;
    }

    Process {
        running: true
        command: ["sh", "-c", "[ -f \"$1\" ] && [ ! -f \"$2\" ] && mkdir -p \"${2%/*}\" && mv \"$1\" \"$2\"; exit 0", "sh", root.legacyStateFile, root.stateFile]
    }

    FileView {
        id: stateView
        path: root.stateFile
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onTextChanged: root.path = text().trim()
    }

    Process {
        id: validator
        property string candidate: ""

        command: ["sh", "-c", "test -f \"$1\" && echo ok", "sh", candidate]

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "ok") {
                    stateView.setText(validator.candidate + "\n");
                    return;
                }
                Alerts.error("Wallpaper not found", validator.candidate);
            }
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.set(path);
        }

        function get(): string {
            return root.path;
        }
    }
}
