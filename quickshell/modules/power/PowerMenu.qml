pragma ComponentBehavior: Bound
import QtQuick
import qs.theme
import qs.components
import qs.modules.power

Overlay {
    id: root

    name: "power"
    dim: true

    property alias selected: navigation.currentIndex
    property int holding: -1
    property real progress: 0
    readonly property int holdDuration: 1000

    onOpened: {
        navigation.reset();
        navigation.forceActiveFocus();
    }
    onOpenChanged: if (!open)
        reset()

    function press(index: int): void {
        selected = index;
        if (!Power.actions[index].confirm)
            return;
        if (holding !== index)
            progress = 0;

        holding = index;
        drain.stop();
        charge.duration = holdDuration * (1 - progress);
        charge.restart();
    }

    function release(): void {
        if (holding < 0 || !charge.running)
            return;

        charge.stop();
        drain.restart();
    }

    function trigger(index: int): void {
        let action = Power.actions[index];
        if (!action.confirm)
            run(action);
    }

    function run(action: var): void {
        OverlayManager.close();
        Power.run(action);
    }

    function reset(): void {
        charge.stop();
        drain.stop();
        progress = 0;
        holding = -1;
    }

    NumberAnimation {
        id: charge
        target: root
        property: "progress"
        to: 1
        onFinished: {
            let action = Power.actions[root.holding];
            root.reset();
            root.run(action);
        }
    }

    NumberAnimation {
        id: drain
        target: root
        property: "progress"
        to: 0
        duration: Motion.exit
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standard
        onFinished: root.holding = -1
    }

    KeyboardNavigation {
        id: navigation
        enabled: root.open
        count: Power.actions.length
        orientation: Qt.Horizontal
        spaceActivates: true
        repeatNavigation: false
        navigationEnabled: !charge.running
        onActivationPressed: index => root.press(index)
        onActivated: index => root.trigger(index)
        onActivationReleased: root.release()

        Keys.onEscapePressed: event => {
            if (charge.running)
                root.release();
            else
                event.accepted = false;
        }
    }

    Column {
        spacing: Theme.spacing.lg

        Row {
            spacing: Theme.spacing.md

            Repeater {
                model: Power.actions

                delegate: Rectangle {
                    id: button
                    required property var modelData
                    required property int index
                    readonly property bool isHolding: root.holding === index
                    readonly property bool isSelected: root.selected === index

                    width: 120
                    height: 120
                    radius: Theme.radius.lg
                    color: Theme.colors.controlNormalFill

                    Item {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: button.height * (button.isHolding ? root.progress : 0)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: button.height
                            radius: button.radius
                            color: Qt.rgba(Theme.colors.active.r, Theme.colors.active.g, Theme.colors.active.b, 0.35)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: button.radius
                        color: "transparent"
                        border.width: 2
                        border.color: {
                            if (button.isHolding || button.isSelected)
                                return Theme.colors.active;
                            return "transparent";
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Motion.small
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacing.sm

                        ShellIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            icon.name: button.modelData.icon
                            icon.size: 40
                            icon.color: button.isSelected ? Theme.colors.active : Theme.colors.fg
                        }

                        UIText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: button.modelData.label

                            renderType: Text.QtRendering
                            renderTypeQuality: Text.HighRenderTypeQuality
                            font.pixelSize: Theme.font.body.medium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (!charge.running)
                            root.selected = button.index
                        onPressed: root.press(button.index)
                        onReleased: root.release()
                        onCanceled: root.release()
                        onClicked: root.trigger(button.index)
                    }
                }
            }
        }

        UIText {
            anchors.horizontalCenter: parent.horizontalCenter
            muted: true
            text: Power.actions[root.selected]?.confirm ? `Hold to ${Power.actions[root.selected].label.toLowerCase()}` : "← → to choose · Enter to confirm"
        }
    }
}
