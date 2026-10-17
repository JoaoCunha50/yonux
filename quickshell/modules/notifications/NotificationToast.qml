pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.components
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    required property Notification modelData
    readonly property Notification notification: modelData
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property bool shown: Notifications.isPopup(notification)
    readonly property var buttons: notification.actions.filter(action => action.identifier !== "default")
    readonly property string iconSource: Notifications.iconSource(notification.image) || Notifications.iconSource(notification.appIcon)
    property var pending: null

    implicitHeight: shown ? surface.height + Theme.spacing.sm : 0
    visible: reveal.active || height > 0


    Behavior on implicitHeight {
        NumberAnimation {
            duration: Motion.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standard
        }
    }

    function closeThen(callback: var): void {
        pending = callback;
        Notifications.hidePopup(notification);
        closeTimer.restart();
    }

    function activate(): void {
        let action = Notifications.defaultAction(notification);
        if (action)
            closeThen(() => action.invoke());
        else
            Notifications.hidePopup(notification);
    }

    Timer {
        id: closeTimer
        interval: Math.max(Motion.exit, Motion.small)
        onTriggered: root.pending?.()
    }

    onShownChanged: if (shown)
        timer.restart()

    Connections {
        target: root.notification
        function onClosed(): void {
            Notifications.hidePopup(root.notification);
        }
    }

    Timer {
        id: timer
        interval: root.notification.expireTimeout > 0 ? root.notification.expireTimeout : ShellSettings.value("notifications.timeout") * 1000
        running: root.shown && !root.critical && !hover.hovered
        onTriggered: Notifications.hidePopup(root.notification)
    }

    Reveal {
        id: reveal
        width: parent.width
        height: surface.height
        shown: root.shown

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
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate()
            }

            RowLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.spacing.lg
                spacing: Theme.spacing.md

                Item {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 40
                    implicitHeight: 40

                    Image {
                        id: appImage
                        anchors.fill: parent
                        source: root.iconSource
                        sourceSize.width: 80
                        sourceSize.height: 80
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    ShellIcon {
                        anchors.centerIn: parent
                        visible: appImage.status !== Image.Ready
                        icon.name: Icons.notifications
                        icon.size: 28
                        icon.color: root.critical ? Theme.colors.alert : Theme.colors.fgMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        UIText {
                            Layout.fillWidth: true
                            text: root.notification.summary
                            font.pixelSize: Theme.font.label.large
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        IconButton {
                            implicitWidth: 22
                            implicitHeight: 22
                            icon.name: Icons.close
                            icon.size: 16
                            onClicked: Notifications.hidePopup(root.notification)
                        }
                    }

                    UIText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.notification.body
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        muted: true
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }

                    UIText {
                        Layout.topMargin: 2
                        text: root.notification.appName
                        font.pixelSize: Theme.font.label.small
                        muted: true
                        visible: text !== ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.spacing.sm
                        visible: root.buttons.length > 0
                        spacing: Theme.spacing.sm

                        Repeater {
                            model: root.buttons

                            Rectangle {
                                id: button
                                required property NotificationAction modelData

                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: Theme.radius.sm
                                color: buttonArea.pressed ? Theme.colors.controlPressedFill : buttonArea.containsMouse ? Theme.colors.controlHoverFill : Theme.colors.field

                                UIText {
                                    anchors.centerIn: parent
                                    width: parent.width - Theme.spacing.md * 2
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: button.modelData.text
                                }

                                MouseArea {
                                    id: buttonArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.closeThen(() => button.modelData.invoke())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
