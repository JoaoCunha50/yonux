pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import yonux.theme
import yonux.services
import yonux.components
import yonux.modules.bar.tray

TrayPopup {
    id: audioPopup

    shadowPadding: 20
    implicitWidth: 360 + shadowPadding * 2
    implicitHeight: 480 + shadowPadding * 2
    dismissOnClickOutside: true

    PwObjectTracker {
        objects: Audio.outputs.concat(Audio.inputs)
    }

    component DeviceRow: Rectangle {
        id: row

        required property PwNode modelData
        readonly property bool selected: Audio.isDefault(modelData)
        readonly property bool muted: modelData.audio?.muted ?? false

        Layout.fillWidth: true
        implicitHeight: 68
        color: Theme.colors.controlNormalFill
        radius: Theme.radius.sm
        border.color: selected ? Theme.colors.active : "transparent"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                UIText {
                    Layout.fillWidth: true
                    text: row.modelData.description || row.modelData.name
                    elide: Text.ElideRight
                }

                ShellButton {
                    type: ShellButton.Ghost
                    icon.name: row.modelData.isSink ? (row.muted ? Icons.volumeOff : Icons.volumeUp) : (row.muted ? Icons.micOff : Icons.mic)
                    enabled: !!row.modelData.audio
                    onClicked: Audio.toggleMute(row.modelData)
                }

                ShellButton {
                    type: ShellButton.Ghost
                    icon.name: Icons.check
                    active: row.selected
                    enabled: !row.selected
                    onClicked: Audio.select(row.modelData)
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: row.modelData.audio?.volume ?? 0
                onMoved: Audio.setVolume(row.modelData, value)
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentLayout.implicitHeight
        clip: true

        ColumnLayout {
            id: contentLayout
            width: parent.width
            spacing: 10

            UIText {
                text: "Output devices"
                font.weight: Font.DemiBold
                color: Theme.colors.active
            }

            Repeater {
                model: Audio.outputs
                delegate: DeviceRow {}
            }

            UIText {
                visible: Audio.outputs.length === 0
                text: "No outputs available"
                muted: true
            }

            UIText {
                text: "Microphone"
                font.weight: Font.DemiBold
                color: Theme.colors.active
            }

            Repeater {
                model: Audio.inputs
                delegate: DeviceRow {}
            }

            UIText {
                visible: Audio.inputs.length === 0
                text: "No microphones available"
                muted: true
            }
        }
    }
}
