pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import yonux.config
import yonux.services

Singleton {
    id: root

    readonly property string configPath: Quickshell.shellPath("matugen/config.toml")
    readonly property string wallpaperPath: Wallpaper.path

    readonly property string scheme: ShellSettings.value("theme.scheme")

    property var _generated: null
    property bool _dirty: false

    readonly property color active: role("primary", "#89b4fa")
    readonly property color bg: role("surface_container_low", "#1e1e2e")
    readonly property color fg: role("on_surface", "#cdd6f4")
    readonly property color placeholder: Qt.alpha(fgMuted, 0.55)
    readonly property color fgMuted: role("on_surface_variant", "#a6adc8")
    readonly property color onActive: role("on_primary", "#11111b")
    readonly property color alert: role("error", "#f38ba8")
    readonly property color surface: role("surface_container", "#181825")
    readonly property color field: role("surface_container_highest", "#313244")
    readonly property color border: role("outline_variant", "#313244")
    readonly property color controlNormalFill: role("surface_container", "#313244")
    readonly property color controlHoverFill: role("surface_container_high", "#45475a")
    readonly property color controlPressedFill: role("surface_bright", "#585b70")
    readonly property color controlDisabledFill: role("surface_container_lowest", "#2a2b3d")

    function role(name: string, fallback: color): color {
        return _generated?.[name]?.dark?.color ?? fallback;
    }

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
                    root._generated = JSON.parse(this.text).colors;
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
