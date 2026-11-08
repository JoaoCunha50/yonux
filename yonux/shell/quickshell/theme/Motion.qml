pragma Singleton
import QtQuick
import qs.config

QtObject {
    id: root

    readonly property real speed: HyprSettings.value("animations.enabled") ? HyprSettings.value("animations.speed") : 0

    function scaled(ms: int): int {
        return speed > 0 ? Math.round(ms / speed) : 0;
    }

    readonly property int enter: scaled(400)
    readonly property int exit: scaled(200)
    readonly property int fadeIn: scaled(200)
    readonly property int fadeOut: scaled(150)
    readonly property int small: scaled(200)
    readonly property int extraSmall: scaled(100)
    readonly property int hoverDelay: 300

    readonly property real revealScale: 0.96
    readonly property real revealOffset: -8

    readonly property list<real> emphasizedDecelerate: [0.2, 0, 0.3, 1, 1, 1]
    readonly property list<real> emphasizedAccelerate: [0.3, 0, 0.6, 1, 1, 1]
    readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]

    readonly property list<real> spatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property list<real> effects: [0.34, 0.8, 0.34, 1, 1, 1]
}
