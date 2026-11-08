pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.theme

Controls.Popup {
    id: root

    property string title: "Choose a profile picture"
    property url currentFolder
    property url selectedFile: ""

    signal accepted

    anchors.centerIn: Controls.Overlay.overlay
    width: Math.min(680, (Controls.Overlay.overlay?.width ?? 720) - Theme.spacing.lg * 2)
    height: Math.min(520, (Controls.Overlay.overlay?.height ?? 560) - Theme.spacing.lg * 2)
    padding: Theme.overlay.padding
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    onOpened: selectedFile = ""
    onCurrentFolderChanged: selectedFile = ""

    background: Rectangle {
        color: Theme.colors.surface
        radius: Theme.radius.xl
        border.width: 1
        border.color: Theme.colors.border
    }

    Controls.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    FolderListModel {
        id: files
        folder: root.currentFolder
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        showDirsFirst: true
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing.md

        RowLayout {
            Layout.fillWidth: true

            UIText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Theme.font.title.medium
                font.weight: Font.DemiBold
            }

            ShellButton {
                type: ShellButton.Ghost
                icon.name: Icons.close
                onClicked: root.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.sm

            ShellButton {
                type: ShellButton.Ghost
                icon.name: Icons.arrowUp
                enabled: files.parentFolder.toString() !== root.currentFolder.toString()
                onClicked: root.currentFolder = files.parentFolder
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius.sm
                color: Theme.colors.field
                border.color: path.activeFocus ? Theme.colors.active : Theme.colors.border

                TextInput {
                    id: path
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.sm
                    text: decodeURIComponent(root.currentFolder.toString().replace("file://", ""))
                    color: Theme.colors.fg
                    selectionColor: Theme.colors.active
                    selectedTextColor: Theme.colors.onActive
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.body.medium
                    clip: true
                    selectByMouse: true
                    onAccepted: {
                        const folder = text.trim();
                        if (folder.startsWith("/"))
                            root.currentFolder = "file://" + folder;
                    }
                }
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / Math.max(1, Math.floor(width / 112))
            cellHeight: 124
            boundsBehavior: Flickable.StopAtBounds
            model: files

            delegate: ShellButton {
                id: entry

                required property string fileName
                required property url fileUrl
                required property bool fileIsDir

                width: grid.cellWidth - Theme.spacing.sm
                height: grid.cellHeight - Theme.spacing.sm
                showDefaultContent: false
                radius: Theme.radius.md
                color: root.selectedFile === fileUrl ? Theme.colors.field : hovered ? Theme.colors.controlHoverFill : "transparent"
                border.width: root.selectedFile === fileUrl ? 1 : 0
                border.color: Theme.colors.active

                ShellImage {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.spacing.sm
                    height: 76
                    radius: Theme.radius.sm
                    source: entry.fileIsDir ? "" : entry.fileUrl.toString()
                    fillMode: Image.PreserveAspectCrop
                    fallbackIcon.name: entry.fileIsDir ? Icons.folder : Icons.person
                }

                UIText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.spacing.sm
                    text: entry.fileName
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.font.label.medium
                }

                onClicked: {
                    if (fileIsDir)
                        root.currentFolder = fileUrl;
                    else
                        root.selectedFile = fileUrl;
                }
            }

            UIText {
                anchors.centerIn: parent
                visible: files.count === 0
                text: "No images in this folder"
                muted: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.sm

            UIText {
                Layout.fillWidth: true
                text: root.selectedFile ? decodeURIComponent(root.selectedFile.toString().split("/").pop()) : "Select an image"
                elide: Text.ElideMiddle
                muted: true
                font.pixelSize: Theme.font.label.medium
            }

            ShellButton {
                type: ShellButton.Ghost
                text: "Cancel"
                onClicked: root.close()
            }

            ShellButton {
                text: "Choose"
                active: true
                enabled: root.selectedFile.toString() !== ""
                onClicked: {
                    root.accepted();
                    root.close();
                }
            }
        }
    }
}
