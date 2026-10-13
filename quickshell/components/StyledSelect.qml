pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import qs.theme

T.ComboBox {
    id: root


    implicitWidth: 180
    implicitHeight: 34
    leftPadding: Theme.spacing.md
    rightPadding: Theme.spacing.md + 20

    background: Rectangle {
        radius: Theme.radius.sm
        color: root.hovered ? Theme.colors.controlHoverFill : Theme.colors.field
        border.color: root.popup.visible ? Theme.colors.active : Theme.colors.border
        border.width: 1
    }

    contentItem: UIText {
        text: root.displayText
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: ShellIcon {
        x: root.width - width - Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        icon.name: Icons.expand
        icon.color: Theme.colors.fgMuted
        rotation: root.popup.visible ? 180 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: Motion.small
            }
        }
    }

    delegate: T.ItemDelegate {
        id: option

        required property var modelData
        required property int index

        width: ListView.view.width
        implicitHeight: 32
        leftPadding: Theme.spacing.md
        highlighted: root.highlightedIndex === index

        background: Rectangle {
            radius: Theme.radius.sm
            color: option.highlighted ? Theme.colors.controlHoverFill : "transparent"
        }

        contentItem: UIText {
            text: option.modelData
            verticalAlignment: Text.AlignVCenter
            color: root.currentIndex === option.index ? Theme.colors.active : Theme.colors.fg
        }
    }

    popup: T.Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(list.contentHeight + padding * 2, 240)
        padding: 4

        background: Rectangle {
            radius: Theme.radius.md
            color: Theme.colors.surface
            border.color: Theme.colors.border
            border.width: 1
        }

        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }
    }
}
