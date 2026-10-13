pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.components
import qs.modules.bar.tray

TrayPopup {
    id: root

    property var handle: null
    property var stack: []

    padding: 6
    implicitWidth: 240
    implicitHeight: column.implicitHeight + padding * 2
    grabFocus: true

    onVisibleChanged: if (!visible)
        stack = []

    QsMenuOpener {
        id: opener
        menu: root.stack.length > 0 ? root.stack[root.stack.length - 1] : root.handle
    }

    component MenuRow: Rectangle {
        id: row

        property string icon: ""
        property string image: ""
        property string text: ""
        property string trailing: ""
        property bool interactive: true

        signal activated

        width: parent.width
        height: 30
        radius: Theme.radius.sm
        color: interactive && area.containsMouse ? Theme.colors.controlHoverFill : "transparent"
        opacity: interactive ? 1 : 0.5

        Item {
            id: leading
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            visible: row.icon !== "" || row.image !== ""

            ShellIcon {
                anchors.centerIn: parent
                visible: row.image === ""
                icon.name: row.icon
            }

            IconImage {
                anchors.centerIn: parent
                visible: row.image !== ""
                implicitSize: 16
                source: row.image
            }
        }

        UIText {
            anchors.left: leading.visible ? leading.right : parent.left
            anchors.leftMargin: 8
            anchors.right: trailingIcon.left
            anchors.rightMargin: 8
            anchors.baseline: parent.verticalCenter
            anchors.baselineOffset: capOffset
            elide: Text.ElideRight
            text: row.text
            font.weight: 550
        }

        ShellIcon {
            id: trailingIcon
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            icon.name: row.trailing
        }

        MouseArea {
            id: area
            anchors.fill: parent
            enabled: row.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.activated()
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: 2

        MenuRow {
            visible: root.stack.length > 0
            icon: Icons.chevronLeft
            text: "Back"
            onActivated: root.stack = root.stack.slice(0, -1)
        }

        Repeater {
            model: opener.children

            delegate: Item {
                id: entry
                required property QsMenuEntry modelData

                width: column.width
                height: modelData.isSeparator ? 9 : 30

                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 16
                    height: 1
                    color: Theme.colors.border
                }

                MenuRow {
                    visible: !entry.modelData.isSeparator
                    interactive: entry.modelData.enabled
                    text: entry.modelData.text
                    image: entry.modelData.icon
                    trailing: {
                        let item = entry.modelData;
                        if (item.hasChildren)
                            return Icons.chevronRight;
                        if (item.buttonType === QsMenuButtonType.RadioButton)
                            return item.checkState === Qt.Checked ? Icons.radioOn : Icons.radioOff;
                        if (item.buttonType === QsMenuButtonType.CheckBox && item.checkState === Qt.Checked)
                            return Icons.check;
                        return "";
                    }
                    onActivated: {
                        if (entry.modelData.hasChildren) {
                            root.stack = root.stack.concat([entry.modelData]);
                            return;
                        }
                        entry.modelData.triggered();
                        root.open = false;
                    }
                }
            }
        }
    }
}
