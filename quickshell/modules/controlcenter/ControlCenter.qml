pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Overlay {
    id: root

    name: "controlcenter"
    docked: true

    property real now: Date.now()
    property var expandedApps: ({})

    Binding {
        target: Notifications
        property: "viewing"
        value: root.open
    }

    onOpened: {
        now = Date.now();
        expandedApps = {};
        list.positionViewAtBeginning();
        list.forceActiveFocus();
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.open
        onTriggered: root.now = Date.now()
    }

    ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: Theme.spacing.lg

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.md

            ShellImage {
                implicitWidth: 44
                implicitHeight: 44
                circle: true
                color: Theme.colors.field
                source: root.open ? UserInfo.face : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                fallbackIcon.name: Icons.person
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                UIText {
                    Layout.fillWidth: true
                    text: UserInfo.username
                    font.pixelSize: Theme.font.title.small
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                UIText {
                    Layout.fillWidth: true
                    text: `up ${SystemInfo.uptime}`
                    font.pixelSize: Theme.font.label.medium
                    muted: true
                }
            }

            IconButton {
                icon.name: Icons.settings
                onClicked: {
                    OverlayManager.close();
                    OverlayManager.settingsRequested();
                }
            }

            IconButton {
                icon.name: Icons.power
                onClicked: OverlayManager.open("power")
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.spacing.sm
            rowSpacing: Theme.spacing.sm

            QuickTile {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                icon: Network.wifiEnabled ? Icons.wifi : Icons.wifiOff
                label: "Wi-Fi"
                detail: Network.wifiEnabled ? (Network.wifiNetwork?.name ?? "Not connected") : "Off"
                active: Network.wifiEnabled
                onClicked: Network.toggleWifi()
            }

            QuickTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Icons.dnd
                label: "Do not disturb"
                active: Notifications.dnd
                onClicked: Notifications.setDnd(!Notifications.dnd)
            }

            QuickTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Icons.gameMode
                label: "Game mode"
                active: GameMode.active
                onClicked: GameMode.toggle()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.sm

            IconButton {
                icon.name: Audio.muted ? Icons.volumeOff : Audio.volume < 0.5 ? Icons.volumeDown : Icons.volumeUp
                enabled: Audio.defaultOutput !== null
                onClicked: Audio.toggleMute(Audio.defaultOutput)
            }

            StyledSlider {
                Layout.fillWidth: true
                enabled: Audio.defaultOutput !== null
                from: 0
                to: 1
                value: Audio.volume
                onMoved: Audio.setVolume(Audio.defaultOutput, value)
            }

            UIText {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(Audio.volume * 100)}%`
                font.pixelSize: Theme.font.label.medium
                muted: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.colors.border
        }

        RowLayout {
            Layout.fillWidth: true

            UIText {
                Layout.fillWidth: true
                text: "Notifications"
                font.pixelSize: Theme.font.title.small
                font.weight: Font.DemiBold
            }

            ShellButton {
                visible: Notifications.history.length > 0
                muted: true
                text: "Clear all"
                icon.name: Icons.clearAll
                onClicked: Notifications.clear()
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacing.md
            boundsBehavior: Flickable.StopAtBounds
            model: Notifications.groups

            delegate: NotificationGroup {
                required property var modelData
                width: ListView.view.width
                appName: modelData.appName
                entries: modelData.entries
                now: root.now
                expanded: root.expandedApps[appName] === true
                onActionTaken: root.close()
                onToggled: {
                    let next = Object.assign({}, root.expandedApps);
                    next[appName] = !expanded;
                    root.expandedApps = next;
                }
            }

            Column {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: Theme.spacing.sm

                ShellIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon.name: Notifications.dnd ? Icons.notificationsOff : Icons.notifications
                    icon.size: 40
                    icon.color: Theme.colors.fgMuted
                }

                UIText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notifications"
                    muted: true
                }
            }
        }
    }
}
