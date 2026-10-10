pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import qs.services

QtObject {
    id: root

    readonly property var palette: Matugen.colors

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

    component ColorTokens: QtObject {
        readonly property color active: root.palette?.primary?.dark?.color ?? "#89b4fa"
        readonly property color bg: root.palette?.surface_container_low?.dark?.color ?? "#1e1e2e"
        readonly property color fg: root.palette?.on_surface?.dark?.color ?? "#cdd6f4"
        readonly property color fgMuted: root.palette?.on_surface_variant?.dark?.color ?? "#a6adc8"
        readonly property color onActive: root.palette?.on_primary?.dark?.color ?? "#11111b"
        readonly property color alert: root.palette?.error?.dark?.color ?? "#f38ba8"
        readonly property color surface: root.palette?.surface_container?.dark?.color ?? "#181825"
        readonly property color field: root.palette?.surface_container_highest?.dark?.color ?? "#313244"
        readonly property color border: root.palette?.outline_variant?.dark?.color ?? "#313244"
        readonly property color controlNormalFill: root.palette?.surface_container?.dark?.color ?? "#313244"
        readonly property color controlHoverFill: root.palette?.surface_container_high?.dark?.color ?? "#45475a"
        readonly property color controlPressedFill: root.palette?.surface_bright?.dark?.color ?? "#585b70"
        readonly property color controlDisabledFill: root.palette?.surface_container_lowest?.dark?.color ?? "#2a2b3d"
    }

    readonly property ColorTokens colors: ColorTokens {}

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
