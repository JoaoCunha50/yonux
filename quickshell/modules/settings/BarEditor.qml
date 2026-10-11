pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.modules.bar

RowLayout {
    id: root

    readonly property var available: Object.keys(BarModel.items).filter(id => !BarLayout.used.includes(id)).sort()

    spacing: Theme.spacing.md

    Repeater {
        model: [
            {
                key: "left",
                label: "Left"
            },
            {
                key: "center",
                label: "Center"
            },
            {
                key: "right",
                label: "Right"
            }
        ]

        delegate: Rectangle {
            id: column

            required property var modelData
            readonly property var ids: BarLayout[modelData.key]

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 1
            implicitHeight: list.implicitHeight + Theme.spacing.lg * 2
            radius: Theme.radius.md
            color: Theme.colors.controlNormalFill

            ColumnLayout {
                id: list
                anchors.fill: parent
                anchors.margins: Theme.spacing.lg
                spacing: Theme.spacing.xs

                UIText {
                    text: column.modelData.label
                    color: Theme.colors.active
                }

                Repeater {
                    model: column.ids

                    delegate: RowLayout {
                        id: entry

                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        spacing: 2

                        UIText {
                            Layout.fillWidth: true
                            text: entry.modelData
                            elide: Text.ElideRight
                        }

                        IconButton {
                            icon.name: Icons.arrowUp
                            enabled: entry.index > 0
                            onClicked: BarLayout.move(column.modelData.key, entry.index, -1)
                        }

                        IconButton {
                            icon.name: Icons.arrowDown
                            enabled: entry.index < column.ids.length - 1
                            onClicked: BarLayout.move(column.modelData.key, entry.index, 1)
                        }

                        IconButton {
                            icon.name: Icons.close
                            onClicked: BarLayout.remove(column.modelData.key, entry.index)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.sm
                    visible: root.available.length > 0
                    spacing: Theme.spacing.xs

                    StyledSelect {
                        id: picker
                        Layout.fillWidth: true
                        model: root.available
                    }

                    IconButton {
                        icon.name: Icons.add
                        onClicked: BarLayout.add(column.modelData.key, picker.currentText)
                    }
                }
            }
        }
    }
}
