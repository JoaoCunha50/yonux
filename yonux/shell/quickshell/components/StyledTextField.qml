import QtQuick
import QtQuick.Controls as Controls
import qs.theme

Controls.TextField {
    id: root
    implicitHeight: 36
    leftPadding: Theme.spacing.md
    rightPadding: Theme.spacing.md
    font.family: Theme.font.family
    font.pixelSize: Theme.font.body.medium
    color: Theme.colors.fg
    placeholderTextColor: Theme.colors.placeholder
    selectionColor: Theme.colors.active
    selectedTextColor: Theme.colors.onActive
    selectByMouse: true

    background: Rectangle {
        radius: Theme.radius.sm
        color: Theme.colors.field
        border.width: 1
        border.color: root.activeFocus ? Theme.colors.active : Theme.colors.border
    }
}
