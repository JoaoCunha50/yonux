pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import qs.config

QtObject {
    id: root

    readonly property var colors: Colors

    component FontRole: QtObject {
        required property int large
        required property int medium
        required property int small
        required property int weight
    }

    component FontTokens: QtObject {
        id: tokens

        readonly property string family: ShellSettings.value("font.family")
        readonly property string mono: ShellSettings.value("font.mono")
        readonly property real scale: ShellSettings.value("font.scale")

        function px(size: int): int {
            return Math.round(size * scale);
        }

        readonly property FontRole title: FontRole {
            large: tokens.px(40)
            medium: tokens.px(20)
            small: tokens.px(15)
            weight: Font.Medium
        }

        readonly property FontRole body: FontRole {
            large: tokens.px(15)
            medium: tokens.px(13)
            small: tokens.px(12)
            weight: Font.Normal
        }

        readonly property FontRole label: FontRole {
            large: tokens.px(14)
            medium: tokens.px(12)
            small: tokens.px(11)
            weight: Font.Medium
        }
    }

    readonly property FontTokens font: FontTokens {}

    component SpacingTokens: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
    }

    readonly property SpacingTokens spacing: SpacingTokens {}

    component RadiusTokens: QtObject {
        readonly property real scale: ShellSettings.value("theme.radius")

        readonly property int sm: Math.round(6 * scale)
        readonly property int md: Math.round(8 * scale)
        readonly property int lg: Math.round(10 * scale)
        readonly property int xl: Math.round(12 * scale)
    }

    readonly property RadiusTokens radius: RadiusTokens {}

    component BarTokens: QtObject {
        readonly property int height: ShellSettings.value("bar.height")
    }

    readonly property BarTokens bar: BarTokens {}

    component OverlayTokens: QtObject {
        readonly property int padding: 22
    }

    readonly property OverlayTokens overlay: OverlayTokens {}
}
