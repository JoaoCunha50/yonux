import QtQuick
import QtQuick.Templates as T
import yonux.theme

T.Slider {
    id: root

    implicitWidth: 200
    implicitHeight: 24

    background: Item {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: 6

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.colors.field
        }

        Rectangle {
            width: root.handle.x - root.leftPadding + root.handle.width / 2
            height: parent.height
            radius: height / 2
            color: root.enabled ? Theme.colors.active : Theme.colors.fgMuted
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: root.pressed ? 20 : 16
        implicitHeight: implicitWidth
        radius: width / 2
        color: root.enabled ? Theme.colors.active : Theme.colors.fgMuted
        border.color: Theme.colors.bg
        border.width: 2

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Motion.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
