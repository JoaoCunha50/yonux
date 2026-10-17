pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

ColumnLayout {
    id: root

    required property string appName
    required property var entries
    required property real now
    property bool expanded: false
    readonly property int hidden: expanded ? 0 : entries.length - 1

    signal toggled

    spacing: Theme.spacing.xs

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.xs
        spacing: Theme.spacing.sm

        UIText {
            Layout.fillWidth: true
            text: root.appName || "Other"
            font.pixelSize: Theme.font.label.medium
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            muted: true
        }

        IconButton {
            visible: root.entries.length > 1
            implicitWidth: 22
            implicitHeight: 22
            icon.name: Icons.expand
            icon.size: 18
            rotation: root.expanded ? 180 : 0
            onClicked: root.toggled()

            Behavior on rotation {
                NumberAnimation {
                    duration: Motion.small
                }
            }
        }

        IconButton {
            implicitWidth: 22
            implicitHeight: 22
            icon.name: Icons.close
            icon.size: 16
            onClicked: Notifications.dismissGroup(root.appName)
        }
    }

    Repeater {
        model: root.expanded ? root.entries : root.entries.slice(0, 1)

        NotificationCard {
            required property var modelData
            Layout.fillWidth: true
            entry: modelData
            now: root.now
        }
    }

    UIText {
        Layout.leftMargin: Theme.spacing.xs
        visible: root.hidden > 0
        text: `+${root.hidden} more`
        font.pixelSize: Theme.font.label.small
        muted: true

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}
