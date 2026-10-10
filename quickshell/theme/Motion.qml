pragma Singleton
import QtQuick
import qs.services

QtObject {
    id: root

    readonly property real speed: HyprSettings.value("animations.enabled") ? HyprSettings.value("animations.speed") : 0

    function scaled(ms: int): int {
        return speed > 0 ? Math.round(ms / speed) : 0;
    }

    readonly property int enter: scaled(350)
    readonly property int exit: scaled(200)
    readonly property int small: scaled(200)
    readonly property int extraSmall: scaled(100)
    readonly property int hoverDelay: 300

    readonly property real revealScale: 0.94
    readonly property real revealOffset: -8

    readonly property list<real> emphasizedDecelerate: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> emphasizedAccelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
}
