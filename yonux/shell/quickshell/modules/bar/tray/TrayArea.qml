import QtQuick
import QtQuick.Layouts
import qs.theme

RowLayout {
    id: root

    property list<Component> items
    property bool alignEnd: false

    spacing: Theme.spacing.md

    Item {
        visible: root.alignEnd
        Layout.fillWidth: true
    }

    Repeater {
        model: root.items

        delegate: Loader {
            required property Component modelData
            readonly property TrayItem entry: item as TrayItem

            sourceComponent: modelData
            visible: entry ? entry.shown : false
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: entry ? entry.fillWidth : false
        }
    }
}
