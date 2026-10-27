pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import yonux.components
import yonux.config
import yonux.theme

ColumnLayout {
    id: root
    spacing: Theme.spacing.sm
    property string error: ""
    readonly property var matching: Keybindings.entries.filter(entry => {
        const query = search.text.trim().toLowerCase();
        return (entry.title + " " + entry.keys + " " + Keybindings.actionLabel(entry)).toLowerCase().includes(query);
    })

    Component.onCompleted: Keybindings.refresh()

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Theme.spacing.sm
        UIText {
            Layout.fillWidth: true
            text: "Choose what your keys do. Changes apply immediately."
            muted: true
            wrapMode: Text.WordWrap
        }
        ShellButton {
            text: "Add shortcut"
            icon.name: Icons.add
            onClicked: editor.edit(null)
        }
    }

    StyledTextField {
        id: search
        Layout.fillWidth: true
        Layout.bottomMargin: Theme.spacing.sm
        placeholderText: "Search shortcuts…"
    }

    UIText {
        Layout.fillWidth: true
        visible: root.error !== ""
        text: root.error
        color: Theme.colors.alert
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.matching
        delegate: Rectangle {
            id: row
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 76
            radius: Theme.radius.md
            color: Theme.colors.controlNormalFill

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.md
                spacing: Theme.spacing.sm

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    UIText {
                        Layout.fillWidth: true
                        text: row.modelData.title
                        elide: Text.ElideRight
                        opacity: row.modelData.enabled ? 1 : 0.5
                    }
                    UIText {
                        Layout.fillWidth: true
                        text: Keybindings.actionLabel(row.modelData)
                        muted: true
                        font.pixelSize: Theme.font.body.small
                        elide: Text.ElideRight
                    }
                }

                ShellButton {
                    type: ShellButton.Tonal
                    text: row.modelData.keys
                    onClicked: editor.edit(row.modelData)
                }
                StyledSwitch {
                    checked: row.modelData.enabled
                    onToggled: root.error = Keybindings.save(Object.assign({}, row.modelData, { enabled: checked }))
                }
                ShellButton {
                    type: ShellButton.Ghost
                    visible: !row.modelData.builtin
                    icon.name: Icons.close
                    onClicked: Keybindings.remove(row.modelData.id)
                }
            }
        }
    }

    UIText {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.lg
        visible: root.matching.length === 0
        text: search.text ? "No matching shortcuts" : "Add your first shortcut"
        muted: true
        horizontalAlignment: Text.AlignHCenter
    }

    KeybindingEditor { id: editor }
}
