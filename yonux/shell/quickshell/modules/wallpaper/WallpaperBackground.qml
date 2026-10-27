pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import yonux.theme
import yonux.services

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.exclusiveZone: -1

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: Theme.colors.bg

        Image {
            anchors.fill: parent
            source: Wallpaper.path !== "" ? "file://" + Wallpaper.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }
}
