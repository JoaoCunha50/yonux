pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.theme
import qs.services
import qs.components

Rectangle {
    id: root

    required property var modelData
    property var store: HyprSettings
    readonly property var row: modelData
    readonly property var current: root.store.value(row.key)
    readonly property bool modified: root.store.config.values && !root.store.config.isDefault(row.key)
    readonly property bool resettable: row.resettable ?? false

    property bool editing: false
    property bool revealed: modified

    onModifiedChanged: if (!editing)
        revealed = modified
    onEditingChanged: editing ? revealDelay.stop() : revealDelay.restart()

    Timer {
        id: revealDelay
        interval: Motion.small
        onTriggered: root.revealed = root.modified
    }

    Layout.fillWidth: true

    implicitHeight: content.implicitHeight + Theme.spacing.lg * 2
    radius: Theme.radius.md
    color: Theme.colors.controlNormalFill

    visible: root.store.shown(row)

    function format(value: real): string {
        if (row.pct)
            return `${Math.round(value * 100)}%`;
        return row.step < 1 ? value.toFixed(2) : `${Math.round(value)}`;
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.spacing.lg

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: Theme.spacing.lg
            spacing: 2

            UIText {
                text: root.row.label
            }

            UIText {
                Layout.fillWidth: true
                text: root.row.desc
                muted: true
                font.pixelSize: Theme.font.body.small
                wrapMode: Text.WordWrap
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: ({
                    seg: segmented,
                    slider: slider,
                    font: fontPicker,
                    select: select,
                    wallpaper: wallpaper
                })[root.row.ctl] ?? toggle
        }

        Reveal {
            id: reset

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: shown ? resetButton.implicitWidth : 0
            Layout.leftMargin: shown ? 0 : -content.spacing

            implicitHeight: resetButton.implicitHeight
            visible: root.resettable
            shown: root.revealed

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Motion.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standard
                }
            }

            Behavior on Layout.leftMargin {
                NumberAnimation {
                    duration: Motion.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standard
                }
            }

            IconButton {
                id: resetButton
                anchors.centerIn: parent
                icon.name: Icons.reset
                tooltip: "Reset to default"
                enabled: root.modified
                onClicked: root.store.reset(root.row.key)
            }
        }
    }

    Component {
        id: segmented

        Row {
            spacing: Theme.spacing.xs

            Repeater {
                model: root.row.opts

                delegate: Rectangle {
                    id: option

                    required property var modelData
                    readonly property bool selected: root.current === modelData.value

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
                        onClicked: root.store.set(root.row.key, option.modelData.value)
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
                from: root.row.lo
                to: root.row.hi
                stepSize: root.row.step
                snapMode: T.Slider.SnapAlways
                onMoved: commit.restart()
                onPressedChanged: root.editing = pressed || commit.running

                Layout.preferredWidth: 220

                Binding on value {
                    value: root.current
                    when: !control.pressed && !commit.running
                    restoreMode: Binding.RestoreNone
                }

                Timer {
                    id: commit
                    interval: 200
                    onTriggered: {
                        root.store.set(root.row.key, Number(control.value.toFixed(4)));
                        root.editing = control.pressed;
                    }
                }
            }

            UIText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: root.format(control.value)
            }
        }
    }

    Component {
        id: toggle

        StyledSwitch {
            checked: root.current
            onToggled: root.store.set(root.row.key, checked)
        }
    }

    Component {
        id: fontPicker

        StyledSelect {
            readonly property var families: root.row.mono ? ShellSettings.monoFamilies : ShellSettings.fontFamilies

            implicitWidth: 260
            previewFont: true
            model: families
            currentIndex: families.indexOf(root.current)
            displayText: root.current
            onActivated: index => root.store.set(root.row.key, families[index])
        }
    }

    Component {
        id: select

        StyledSelect {
            implicitWidth: 220
            model: root.row.opts.map(opt => opt.label)
            currentIndex: root.row.opts.findIndex(opt => opt.value === root.current)
            onActivated: index => root.store.set(root.row.key, root.row.opts[index].value)
        }
    }

    Component {
        id: wallpaper

        RowLayout {
            spacing: Theme.spacing.md

            UIText {
                Layout.maximumWidth: 180
                text: Wallpaper.path.split("/").pop()
                muted: true
                elide: Text.ElideMiddle
            }

            Rectangle {
                implicitWidth: chooseLabel.implicitWidth + Theme.spacing.lg * 2
                implicitHeight: 34
                radius: Theme.radius.sm
                color: chooseArea.pressed ? Theme.colors.controlPressedFill : chooseArea.containsMouse ? Theme.colors.controlHoverFill : Theme.colors.field

                UIText {
                    id: chooseLabel
                    anchors.centerIn: parent
                    text: "Choose…"
                }

                MouseArea {
                    id: chooseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.open()
                }
            }

            FileDialog {
                id: picker
                title: "Choose a wallpaper"
                currentFolder: Wallpaper.path !== "" ? `file://${Wallpaper.path.slice(0, Wallpaper.path.lastIndexOf("/"))}` : `file://${Quickshell.env("HOME")}/Pictures`
                nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
                onAccepted: Wallpaper.set(decodeURIComponent(selectedFile.toString().replace("file://", "")))
            }
        }
    }
}
