pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Hyprland
import yonux.theme
import yonux.config
import yonux.services
import yonux.components

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
            name: "Shortcuts",
            icon: Icons.keyboard
        },
        {
            name: "Bar",
            icon: Icons.bar
        },
        {
            name: "Notifications",
            icon: Icons.notifications
        }
    ]

    title: "yonux settings"
    visible: false
    color: Theme.colors.bg

    MouseArea {
        id: cursorRefresh
        anchors.fill: parent
        z: 1000
        visible: cursorFrames.running
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        // Hyprland 0.56 caches cursor images by shape across theme changes.
        // Send distinct shapes, then restore the hovered control's cursor.
        function refresh(): void {
            cursorShape = Qt.ArrowCursor;
            cursorFrames.step = 0;
            cursorFrames.running = true;
        }

        FrameAnimation {
            id: cursorFrames
            property int step: 0
            onTriggered: {
                if (step++ === 0) {
                    cursorRefresh.cursorShape = Qt.PointingHandCursor;
                } else {
                    running = false;
                }
            }
        }
    }

    Connections {
        target: HyprSettings
        function onCursorApplied(): void {
            if (root.visible)
                cursorRefresh.refresh();
        }
    }

    onSectionChanged: {
        settingsScroll.cancelFlick();
        settingsScroll.contentY = 0;
        if (section === "About") SystemInfo.refresh();
    }

    onVisibleChanged: if (visible) settingsScroll.contentY = 0

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

    onClosed: visible = false

    Loader {
        id: facePicker
        active: root.visible
        sourceComponent: ImagePicker {
            title: "Choose a profile picture"
            currentFolder: `file://${Quickshell.env("HOME")}/Pictures`
            onAccepted: UserInfo.setFace(decodeURIComponent(selectedFile.toString().replace("file://", "")))
        }
    }

    GlobalShortcut { // qmllint disable unresolved-type
        appid: "yonux"
        name: "settings"
        onPressed: root.visible = !root.visible
    }

    Connections {
        target: OverlayManager
        function onSettingsRequested(): void {
            root.visible = true;
        }
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

                    ShellImage {
                        id: avatar
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: Theme.spacing.sm
                        implicitWidth: 72
                        implicitHeight: 72
                        circle: true
                        color: Theme.colors.field
                        source: root.visible ? UserInfo.face : ""
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        fallbackIcon.name: Icons.person

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
                                icon.name: Icons.edit
                                icon.size: 24
                            }
                        }

                        MouseArea {
                            id: avatarArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (facePicker.item as ImagePicker)?.open()
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
            id: settingsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: page.implicitHeight + Theme.spacing.lg * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: pageScrollBar
                policy: Controls.ScrollBar.AsNeeded
                visible: settingsScroll.contentHeight > settingsScroll.height
                width: 10
                padding: 2
                minimumSize: 0.05
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: pageScrollBar.pressed ? Theme.colors.active : Theme.colors.fgMuted
                    opacity: pageScrollBar.active ? 0.9 : 0.45
                }
                background: null
            }

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

                SettingRow {
                    visible: root.section === "Theme"
                    label: "Wallpaper"
                    desc: "The colour palette is generated from it"
                    control: wallpaperControl
                }

                Repeater {
                    model: [...ShellSettings.inSection(root.section), ...HyprSettings.inSection(root.section)]
                    delegate: SettingRow {
                        required property Setting modelData
                        setting: modelData
                    }
                }

                BarEditor {
                    Layout.fillWidth: true
                    visible: root.section === "Bar"
                }

                AboutPage {
                    Layout.fillWidth: true
                    visible: root.section === "About"
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.visible && root.section === "Shortcuts"
                    visible: active
                    sourceComponent: KeybindingsPage {}
                }
            }
        }
    }

    Component {
        id: wallpaperControl

        RowLayout {
            spacing: Theme.spacing.md

            UIText {
                Layout.maximumWidth: 180
                text: Wallpaper.path.split("/").pop()
                muted: true
                elide: Text.ElideMiddle
            }

            ShellButton {
                implicitHeight: 34
                text: "Choose…"
                onClicked: wallpaperPicker.open()
            }

            FileDialog {
                id: wallpaperPicker
                title: "Choose a wallpaper"
                currentFolder: Wallpaper.path !== "" ? `file://${Wallpaper.path.slice(0, Wallpaper.path.lastIndexOf("/"))}` : `file://${Quickshell.env("HOME")}/Pictures`
                nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
                onAccepted: Wallpaper.set(decodeURIComponent(selectedFile.toString().replace("file://", "")))
            }
        }
    }
}
