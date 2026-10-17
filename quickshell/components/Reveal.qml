import QtQuick
import qs.theme

Item {
    id: root

    property bool shown: false
    property real hiddenScale: Motion.revealScale
    property real hiddenOffset: Motion.revealOffset
    property real hiddenOffsetX: 0
    property real hiddenOpacity: 0
    property real progress: shown ? 1 : 0
    readonly property bool active: shown || progress > 0

    opacity: hiddenOpacity + (1 - hiddenOpacity) * progress
    scale: hiddenScale + (1 - hiddenScale) * progress
    transform: Translate {
        x: root.hiddenOffsetX * (1 - root.progress)
        y: root.hiddenOffset * (1 - root.progress)
    }

    Behavior on progress {
        NumberAnimation {
            duration: root.shown ? Motion.enter : Motion.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown ? Motion.emphasizedDecelerate : Motion.emphasizedAccelerate
        }
    }
}
