import QtQuick
import yonux.theme

Item {
    id: root

    property bool shown: false
    property QtObject window: null
    property real hiddenScale: Motion.revealScale
    property real hiddenOffset: Motion.revealOffset
    property real hiddenOffsetX: 0
    property real hiddenOpacity: 0
    property bool overshoot: true
    property real progress: shown ? 1 : 0
    property real fade: shown ? 1 : 0
    readonly property bool active: shown || progress > 0 || fade > 0

    signal aboutToShow
    signal hidden

    opacity: hiddenOpacity + (1 - hiddenOpacity) * fade
    scale: hiddenScale + (1 - hiddenScale) * Math.min(progress, 1)

    transform: Translate {
        x: root.hiddenOffsetX * (1 - root.progress)
        y: root.hiddenOffset * (1 - root.progress)
    }

    onShownChanged: {
        if (!shown)
            return;
        aboutToShow();
        if (window)
            window.visible = true;
    }

    onActiveChanged: {
        if (active)
            return;
        if (window)
            window.visible = false;
        hidden();
    }

    Behavior on progress {
        NumberAnimation {
            duration: root.shown ? Motion.enter : Motion.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: !root.shown ? Motion.emphasizedAccelerate : root.overshoot ? Motion.spatial : Motion.emphasizedDecelerate
        }
    }

    Behavior on fade {
        NumberAnimation {
            duration: root.shown ? Motion.fadeIn : Motion.fadeOut
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.effects
        }
    }
}
