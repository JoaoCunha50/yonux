pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.modules.bar

RowLayout {
    id: root

    readonly property var config: BarLayout.config
    readonly property var used: [...config.values.left, ...config.values.center, ...config.values.right]
    readonly property var available: Object.keys(BarModel.items).filter(id => !used.includes(id)).sort()

    spacing: Theme.spacing.md

    function move(section: string, index: int, delta: int): void {
        let ids = [...config.values[section]];
        let target = index + delta;
        if (target < 0 || target >= ids.length)
            return;
        [ids[index], ids[target]] = [ids[target], ids[index]];
        config.set(section, ids);
    }

    function remove(section: string, index: int): void {
        let ids = [...config.values[section]];
        ids.splice(index, 1);
        config.set(section, ids);
    }

    function add(section: string, id: string): void {
        config.set(section, [...config.values[section], id]);
    }

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
            readonly property var ids: root.config.values[modelData.key]

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
                            onClicked: root.move(column.modelData.key, entry.index, -1)
                        }

                        IconButton {
                            icon.name: Icons.arrowDown
                            enabled: entry.index < column.ids.length - 1
                            onClicked: root.move(column.modelData.key, entry.index, 1)
                        }

                        IconButton {
                            icon.name: Icons.close
                            onClicked: root.remove(column.modelData.key, entry.index)
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
                        onClicked: root.add(column.modelData.key, picker.currentText)
                    }
                }
            }
        }
    }
}
