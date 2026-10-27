pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import yonux.theme
import yonux.components
import yonux.modules.bar

RowLayout {
    id: root

    readonly property var available: BarModel.widgets.filter(widget => !BarLayout.used.includes(widget.key)).sort((a, b) => a.label.localeCompare(b.label))

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
                        readonly property var widget: BarModel.find(modelData)

                        Layout.fillWidth: true
                        spacing: 2

                        ShellIcon {
                            icon.name: entry.widget?.icon ?? Icons.info
                            icon.size: 16
                            icon.color: Theme.colors.fgMuted
                        }

                        UIText {
                            Layout.fillWidth: true
                            Layout.leftMargin: Theme.spacing.xs
                            text: entry.widget?.label ?? entry.modelData
                            elide: Text.ElideRight
                        }

                        ShellButton {
                            type: ShellButton.Ghost
                            icon.name: Icons.arrowUp
                            enabled: entry.index > 0
                            onClicked: BarLayout.move(column.modelData.key, entry.index, -1)
                        }

                        ShellButton {
                            type: ShellButton.Ghost
                            icon.name: Icons.arrowDown
                            enabled: entry.index < column.ids.length - 1
                            onClicked: BarLayout.move(column.modelData.key, entry.index, 1)
                        }

                        ShellButton {
                            type: ShellButton.Ghost
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
                        model: root.available.map(widget => widget.label)
                    }

                    ShellButton {
                        type: ShellButton.Ghost
                        icon.name: Icons.add
                        enabled: picker.currentIndex >= 0
                        onClicked: BarLayout.add(column.modelData.key, root.available[picker.currentIndex].key)
                    }
                }
            }
        }
    }
}
