pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.components

Rectangle {
    id: root

    property Setting setting: null
    property string label: setting?.label ?? ""
    property string desc: setting?.desc ?? ""
    property Component control: setting ? controls[setting.control] : null

    readonly property var controls: ({
            [Setting.Switch]: toggle,
            [Setting.Slider]: slider,
            [Setting.Segmented]: segmented,
            [Setting.Select]: select
        })
    readonly property bool modified: setting?.modified ?? false
    readonly property bool resettable: setting?.resettable ?? false

    property bool editing: false
    property bool revealed: false

    Component.onCompleted: revealed = modified

    onModifiedChanged: if (!editing && !revealDelay.running)
        revealed = modified
    onEditingChanged: editing ? revealDelay.stop() : revealDelay.restart()

    Timer {
        id: revealDelay
        interval: 200
        onTriggered: root.revealed = root.modified
    }

    Layout.fillWidth: true

    implicitHeight: content.implicitHeight + Theme.spacing.lg * 2
    radius: Theme.radius.md
    color: Theme.colors.controlNormalFill

    visible: setting?.shown ?? true

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.spacing.lg

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: Theme.spacing.lg
            spacing: 2

            UIText {
                text: root.label
            }

            UIText {
                Layout.fillWidth: true
                text: root.desc
                muted: true
                font.pixelSize: Theme.font.body.small
                wrapMode: Text.WordWrap
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: root.control
        }

        Reveal {
            id: reset

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: resetButton.implicitWidth * progress
            Layout.leftMargin: -content.spacing * (1 - progress)

            implicitHeight: resetButton.implicitHeight
            visible: root.resettable
            shown: root.revealed

            IconButton {
                id: resetButton
                anchors.centerIn: parent
                icon.name: Icons.reset
                tooltip: "Reset to default"
                enabled: root.modified
                onClicked: root.setting.reset()
            }
        }
    }

    Component {
        id: segmented

        Row {
            spacing: Theme.spacing.xs

            Repeater {
                model: root.setting.options

                delegate: Rectangle {
                    id: option

                    required property var modelData
                    readonly property bool selected: root.setting.value === modelData.value

                    implicitWidth: label.implicitWidth + Theme.spacing.lg * 2
                    implicitHeight: 32
                    radius: Theme.radius.sm
                    color: selected ? Theme.colors.active : optionArea.containsMouse ? Theme.colors.controlHoverFill : Theme.colors.field

                    UIText {
                        id: label
                        anchors.centerIn: parent
                        text: option.modelData.label
                        color: option.selected ? Theme.colors.onActive : Theme.colors.fg
                    }

                    MouseArea {
                        id: optionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setting.set(option.modelData.value)
                    }
                }
            }
        }
    }

    Component {
        id: slider

        RowLayout {
            spacing: Theme.spacing.sm

            StyledSlider {
                id: control
                Layout.preferredWidth: 220
                from: root.setting.min
                to: root.setting.max
                stepSize: root.setting.step
                snapMode: T.Slider.SnapAlways
                onMoved: root.setting.adjust(value)

                Binding {
                    target: root
                    property: "editing"
                    value: control.pressed || root.setting.adjusting
                }

                Binding on value {
                    value: root.setting.value
                    when: !control.pressed && !root.setting.adjusting
                    restoreMode: Binding.RestoreNone
                }
            }

            UIText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: root.setting.format(control.value)
            }
        }
    }

    Component {
        id: toggle

        StyledSwitch {
            checked: root.setting.value
            onToggled: root.setting.set(checked)
        }
    }

    Component {
        id: select

        StyledSelect {
            implicitWidth: 220
            model: root.setting.options.map(option => option.label)
            currentIndex: root.setting.options.findIndex(option => option.value === root.setting.value)
            onActivated: index => root.setting.set(root.setting.options[index].value)
        }
    }
}
