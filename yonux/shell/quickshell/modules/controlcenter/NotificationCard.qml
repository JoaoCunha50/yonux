pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import yonux.components
import yonux.services
import yonux.theme

Rectangle {
    id: root

    required property var entry
    required property real now
    readonly property bool fresh: entry.time > Notifications.lastSeen
    readonly property bool clickable: entry.defaultAction !== null

    signal actionTaken

    implicitHeight: content.implicitHeight + Theme.spacing.md * 2
    radius: Theme.radius.lg
    color: fresh ? Theme.colors.controlHoverFill : Theme.colors.field
    border.color: entry.critical ? Theme.colors.alert : "transparent"
    border.width: 1

    function ago(time: real): string {
        let minutes = Math.floor((now - time) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes} min`;

        let hours = Math.floor(minutes / 60);
        if (hours < 24)
            return `${hours} h`;

        let date = new Date(time);
        let yesterday = new Date(now);
        yesterday.setDate(yesterday.getDate() - 1);
        if (date.toDateString() === yesterday.toDateString())
            return "yesterday";

        return Qt.formatDate(date, "d MMM");
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.entry.activate();
            root.actionTaken();
        }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.spacing.md
        spacing: Theme.spacing.md

        ShellImage {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40
            source: root.entry.icon
            fillMode: Image.PreserveAspectCrop
            fallbackIcon.name: Icons.notifications
            fallbackIcon.color: root.entry.critical ? Theme.colors.alert : Theme.colors.fgMuted
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.sm

                UIText {
                    Layout.fillWidth: true
                    text: root.entry.summary
                    font.pixelSize: Theme.font.label.large
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                UIText {
                    text: root.ago(root.entry.time)
                    font.pixelSize: Theme.font.label.small
                    muted: true
                }

                ShellButton {
                    type: ShellButton.Ghost
                    implicitWidth: 22
                    implicitHeight: 22
                    icon.name: Icons.close
                    icon.size: 16
                    onClicked: root.entry.dismiss()
                }
            }

            UIText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                muted: true
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.sm
                visible: root.entry.actions.length > 0
                spacing: Theme.spacing.sm

                Repeater {
                    model: root.entry.actions

                    ShellButton {
                        id: button
                        required property NotificationAction modelData

                        Layout.fillWidth: true
                        type: ShellButton.Tonal
                        text: modelData.text
                        onClicked: {
                            root.entry.invoke(button.modelData);
                            root.actionTaken();
                        }
                    }
                }
            }
        }
    }
}
