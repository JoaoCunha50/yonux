pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property string configPath: Quickshell.shellPath("matugen/config.toml")
    readonly property string wallpaperPath: Wallpaper.path
    readonly property string scheme: ShellSettings.value("theme.scheme")
    property var colors: null
    property bool _dirty: false

    onWallpaperPathChanged: generate()
    onSchemeChanged: generate()
    Component.onCompleted: generate()

    function generate(): void {
        if (root.wallpaperPath === "")
            return;
        if (matugenProc.running) {
            root._dirty = true;
            return;
        }

        matugenProc.command = ["matugen", "image", root.wallpaperPath, "-c", root.configPath, "-j", "hex", "--prefer", "darkness", "-m", "dark", "-t", root.scheme];
        matugenProc.running = true;
    }

    Process {
        id: matugenProc

        onRunningChanged: {
            if (!running && root._dirty) {
                root._dirty = false;
                root.generate();
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.colors = JSON.parse(this.text).colors;
                } catch (err) {
                    console.error("matugen output is not valid JSON:", err);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "")
                    console.warn("matugen stderr:", this.text);
            }
        }
    }
}
