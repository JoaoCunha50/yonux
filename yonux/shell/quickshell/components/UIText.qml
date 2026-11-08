import QtQuick
import qs.theme

Text {
    renderType: Text.NativeRendering
    renderTypeQuality: Text.HighRenderTypeQuality

    font.family: Theme.font.family
    font.pixelSize: Theme.font.body.medium
    font.weight: Theme.font.body.weight
    font.hintingPreference: Font.PreferDefaultHinting

    color: Theme.colors.fg

    property bool muted: false
    opacity: muted ? 0.6 : 1.0

    readonly property int capOffset: Math.round(font.pixelSize * 0.35)
}
