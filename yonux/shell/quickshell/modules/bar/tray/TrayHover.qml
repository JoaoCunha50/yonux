import QtQuick
import yonux.theme
import yonux.components

TrayPopup {
    id: root

    property string text: ""

    padding: 8
    implicitWidth: body.childrenRect.width + padding * 2
    implicitHeight: body.childrenRect.height + padding * 2

    UIText {
        visible: root.text !== ""
        text: root.text
        font.pixelSize: Theme.font.label.medium
        font.weight: Theme.font.label.weight
    }
}
