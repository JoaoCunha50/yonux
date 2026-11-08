import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme

ClippingRectangle {
    id: root

    property string source
    property bool circle: false
    property alias fallbackIcon: fallback.icon
    property alias fillMode: image.fillMode
    property alias cache: image.cache
    readonly property bool loaded: image.status === Image.Ready

    radius: circle ? Math.min(width, height) / 2 : 0
    color: "transparent"

    function resolve(source: string): string {
        if (!source)
            return "";
        if (source.startsWith("/"))
            return `file://${source}`;
        if (source.startsWith("image://icon/"))
            return resolve(source.slice("image://icon/".length).split("?")[0]);
        if (source.includes("://"))
            return source;
        return Quickshell.iconPath(source, true) ?? "";
    }

    Image {
        id: image
        anchors.fill: parent
        source: root.resolve(root.source)
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    ShellIcon {
        id: fallback
        anchors.centerIn: parent
        visible: !root.loaded
        icon.size: Math.round(Math.min(root.width, root.height) * 0.6)
        icon.color: Theme.colors.fgMuted
    }
}
