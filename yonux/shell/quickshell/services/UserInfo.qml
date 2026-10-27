pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import yonux.services

Singleton {
    id: root

    readonly property string username: Quickshell.env("USER") ?? ""
    readonly property string facePath: `${Quickshell.env("HOME")}/.face`
    property string face: `file://${facePath}`

    function setFace(path: string): void {
        copyFace.command = ["cp", "--remove-destination", "--", path, facePath];
        copyFace.running = true;
    }

    Process {
        id: copyFace

        onExited: code => {
            if (code !== 0) {
                Alerts.error("Could not set the profile picture", copyFace.command[3]);
                return;
            }

            // Clearing first forces the uncached Image to read the file again
            const url = root.face;
            root.face = "";
            root.face = url;
        }
    }
}
