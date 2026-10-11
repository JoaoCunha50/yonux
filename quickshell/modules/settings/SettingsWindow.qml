pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.theme
import qs.config
import qs.services
import qs.components

FloatingWindow { // qmllint disable uncreatable-type
    id: root

    property string section: "Theme"

    readonly property var sections: [
        {
            name: "Theme",
            icon: Icons.appearance
        },
        {
            name: "Windows",
            icon: Icons.windows
        },
        {
            name: "Layout",
            icon: Icons.layout
        },
        {
            name: "Effects",
            icon: Icons.effects
        },
        {
            name: "Input",
            icon: Icons.input
        },
        {
            name: "Bar",
            icon: Icons.bar
        }
    ]

    title: "yonux settings"
    visible: false
    color: Theme.colors.bg

    onSectionChanged: if (section === "About")
        SystemInfo.refresh()

    component SectionButton: Rectangle {
        id: item

        required property var modelData
        readonly property bool selected: root.section === modelData.name

        Layout.fillWidth: true
        implicitHeight: 38
        radius: Theme.radius.sm
        color: selected ? Theme.colors.active : itemArea.containsMouse ? Theme.colors.controlHoverFill : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.md
            spacing: Theme.spacing.md

            ShellIcon {
                icon.name: item.modelData.icon
                icon.color: item.selected ? Theme.colors.onActive : Theme.colors.fg
            }

            UIText {
                Layout.fillWidth: true
                text: item.modelData.name
                color: item.selected ? Theme.colors.onActive : Theme.colors.fg
            }
        }

        MouseArea {
            id: itemArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.section = item.modelData.name
        }
    }

    // Super+Q closes the window behind our back; keep `visible` in sync so the shortcut reopens it
    onClosed: visible = false

    FileDialog {
        id: facePicker
        title: "Choose a profile picture"
        currentFolder: `file://${Quickshell.env("HOME")}/Pictures`
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: UserInfo.setFace(decodeURIComponent(selectedFile.toString().replace("file://", "")))
    }

    GlobalShortcut { // qmllint disable unresolved-type
        appid: "yonux"
        name: "settings"
        onPressed: root.visible = !root.visible
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        focus: true

        Keys.onEscapePressed: root.visible = false

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: Theme.colors.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.md
                spacing: Theme.spacing.xs

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.md
                    Layout.bottomMargin: Theme.spacing.lg
                    spacing: Theme.spacing.xs

                    ClippingRectangle {
                        id: avatar
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: Theme.spacing.sm
                        implicitWidth: 72
                        implicitHeight: 72
                        radius: avatar.width / 2
                        color: Theme.colors.field

                        ShellIcon {
                            anchors.centerIn: parent
                            visible: face.status !== Image.Ready
                            icon.name: Icons.person
                            icon.size: 40
                            icon.color: Theme.colors.fgMuted
                        }

                        Image {
                            id: face
                            anchors.fill: parent
                            // Re-read on every open so a new ~/.face shows up without a reload
                            source: root.visible ? UserInfo.face : ""
                            sourceSize: Qt.size(144, 144)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.alpha(Theme.colors.bg, 0.6)
                            opacity: avatarArea.containsMouse ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Motion.small
                                }
                            }

                            ShellIcon {
                                anchors.centerIn: parent
                                icon.name: Icons.editPhoto
                                icon.size: 24
                            }
                        }

                        MouseArea {
                            id: avatarArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: facePicker.open()
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.xs

                        TapHandler {
                            cursorShape: Qt.PointingHandCursor
                            onTapped: root.section = "About"
                        }

                        UIText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: UserInfo.username
                            font.pixelSize: Theme.font.title.small
                            font.weight: Theme.font.title.weight
                            elide: Text.ElideRight
                        }

                        UIText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: SystemInfo.distro
                            muted: true
                            font.pixelSize: Theme.font.body.small
                            elide: Text.ElideRight
                        }
                    }
                }

                Repeater {
                    model: root.sections
                    delegate: SectionButton {}
                }

                Item {
                    Layout.fillHeight: true
                }

                SectionButton {
                    modelData: ({
                            name: "About",
                            icon: Icons.info
                        })
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: page.implicitHeight + Theme.spacing.lg * 2
            clip: true

            ColumnLayout {
                id: page
                x: Theme.spacing.lg
                y: Theme.spacing.lg
                width: parent.width - Theme.spacing.lg * 2
                spacing: Theme.spacing.sm

                UIText {
                    Layout.bottomMargin: Theme.spacing.sm
                    visible: root.section !== "About"
                    text: root.section
                    font.pixelSize: Theme.font.title.medium
                    font.weight: Theme.font.title.weight
                }

                Repeater {
                    model: ShellSettings.schema.filter(row => row.section === root.section)
                    delegate: SettingRow {
                        store: ShellSettings
                    }
                }

                Repeater {
                    model: HyprSettings.schema.filter(row => row.section === root.section)
                    delegate: SettingRow {}
                }

                BarEditor {
                    Layout.fillWidth: true
                    visible: root.section === "Bar"
                }

                AboutPage {
                    Layout.fillWidth: true
                    visible: root.section === "About"
                }
            }
        }
    }
}
