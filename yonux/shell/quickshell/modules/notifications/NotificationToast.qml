pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import yonux.components
import yonux.config
import yonux.theme

Item {
    id: root

    required property var modelData
    readonly property var entry: modelData

    property string summary: entry.summary
    property string body: entry.body
    property string appName: entry.appName
    property string icon: entry.icon
    property bool critical: entry.critical
    property var actions: entry.actions

    property bool entered: false
    property bool leaving: false
    readonly property bool shown: entered && !leaving

    implicitHeight: shown ? surface.height + Theme.spacing.sm : 0

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Motion.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standard
        }
    }

    Component.onCompleted: entered = true

    // The entry can be destroyed while the toast animates out, so keep what is on screen
    function keepContent(): void {
        summary = summary;
        body = body;
        appName = appName;
        icon = icon;
        critical = critical;
        actions = [];
    }

    ListView.onRemove: {
        keepContent();
        leaving = true;
        ListView.delayRemove = true;
    }

    Timer {
        interval: (root.entry?.timeout ?? 0) > 0 ? root.entry.timeout : ShellSettings.value("notifications.timeout") * 1000
        running: root.shown && !root.critical && !hover.hovered
        onTriggered: root.entry.hideToast()
    }

    Reveal {
        width: parent.width
        height: surface.height
        shown: root.shown
        onHidden: if (root.leaving)
            root.ListView.delayRemove = false

        Rectangle {
            id: surface
            width: parent.width
            height: content.implicitHeight + Theme.spacing.lg * 2

            color: Theme.colors.surface
            radius: Theme.radius.xl
            border.color: root.critical ? Theme.colors.alert : Theme.colors.border
            border.width: 1

            HoverHandler {
                id: hover
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.leaving
                cursorShape: Qt.PointingHandCursor
                onClicked: root.entry.activate()
            }

            RowLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.spacing.lg
                spacing: Theme.spacing.md

                ShellImage {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 40
                    implicitHeight: 40
                    source: root.icon
                    fallbackIcon.name: Icons.notifications
                    fallbackIcon.color: root.critical ? Theme.colors.alert : Theme.colors.fgMuted
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        UIText {
                            Layout.fillWidth: true
                            text: root.summary
                            font.pixelSize: Theme.font.label.large
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        ShellButton {
                            type: ShellButton.Ghost
                            implicitWidth: 22
                            implicitHeight: 22
                            enabled: !root.leaving
                            icon.name: Icons.close
                            icon.size: 16
                            onClicked: root.entry.hideToast()
                        }
                    }

                    UIText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.body
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        muted: true
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }

                    UIText {
                        Layout.topMargin: 2
                        visible: text !== ""
                        text: root.appName
                        font.pixelSize: Theme.font.label.small
                        muted: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.spacing.sm
                        visible: root.actions.length > 0
                        spacing: Theme.spacing.sm

                        Repeater {
                            model: root.actions

                            ShellButton {
                                id: button
                                required property NotificationAction modelData

                                Layout.fillWidth: true
                                text: modelData.text
                                onClicked: root.entry.invoke(button.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
