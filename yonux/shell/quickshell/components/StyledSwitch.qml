import QtQuick
import QtQuick.Templates as T
import qs.theme

T.Switch {
    id: root

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        radius: height / 2
        color: root.checked ? Theme.colors.active : Theme.colors.field

        Behavior on color {
            ColorAnimation {
                duration: Motion.small
            }
        }

        Rectangle {
            readonly property real inset: (parent.height - height) / 2

            x: root.checked ? parent.width - width - inset : inset
            width: 18
            height: 18
            radius: height / 2
            color: root.checked ? Theme.colors.onActive : Theme.colors.fgMuted

            anchors.verticalCenter: parent.verticalCenter

            Behavior on x {
                NumberAnimation {
                    duration: Motion.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standard
                }
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
