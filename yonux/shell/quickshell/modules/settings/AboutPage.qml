pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.theme
import qs.services
import qs.components

ColumnLayout {
    id: root

    readonly property var shellPalette: [["active", Theme.colors.active], ["onActive", Theme.colors.onActive], ["bg", Theme.colors.bg], ["surface", Theme.colors.surface], ["field", Theme.colors.field], ["border", Theme.colors.border], ["fg", Theme.colors.fg], ["fgMuted", Theme.colors.fgMuted], ["alert", Theme.colors.alert]]

    readonly property var credits: [
        {
            name: "Hyprland",
            role: "compositor",
            url: "https://hyprland.org"
        },
        {
            name: "Quickshell",
            role: "shell toolkit",
            url: "https://quickshell.org"
        },
        {
            name: "matugen",
            role: "wallpaper palettes",
            url: "https://github.com/InioX/matugen"
        },
        {
            name: "Material Symbols",
            role: "icons",
            url: "https://fonts.google.com/icons"
        },
        {
            name: "Ryoku",
            role: "inspiration",
            url: ""
        },
        {
            name: "caelestia",
            role: "inspiration",
            url: "https://github.com/caelestia-dots/shell"
        },
        {
            name: "noctalia",
            role: "inspiration",
            url: "https://github.com/noctalia-dev/noctalia-shell"
        }
    ]

    spacing: Theme.spacing.lg

    component Card: Rectangle {
        id: card

        default property alias content: body.data
        property string title: ""

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Theme.spacing.lg * 2
        radius: Theme.radius.md
        color: Theme.colors.controlNormalFill

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.spacing.lg
            spacing: Theme.spacing.sm

            UIText {
                Layout.bottomMargin: Theme.spacing.xs
                text: card.title
                color: Theme.colors.active
            }
        }
    }

    component Ring: ColumnLayout {
        id: ring

        property real value: 0
        property string label: ""
        property string text: ""
        property bool alert: false
        property real shown: Math.max(0, Math.min(1, value))

        spacing: Theme.spacing.xs

        Behavior on shown {
            NumberAnimation {
                duration: Motion.enter
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedDecelerate
            }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 84
            implicitHeight: 84

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Theme.colors.field
                    strokeWidth: 8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 42
                        centerY: 42
                        radiusX: 36
                        radiusY: 36
                        startAngle: -90
                        sweepAngle: 360
                    }
                }

                ShapePath {
                    strokeColor: ring.alert ? Theme.colors.alert : Theme.colors.active
                    strokeWidth: 8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 42
                        centerY: 42
                        radiusX: 36
                        radiusY: 36
                        startAngle: -90
                        sweepAngle: 360 * ring.shown
                    }
                }
            }

            UIText {
                anchors.centerIn: parent
                text: ring.text
                font.pixelSize: Theme.font.title.small
                font.weight: Theme.font.title.weight
            }
        }

        UIText {
            Layout.alignment: Qt.AlignHCenter
            text: ring.label
            muted: true
            font.pixelSize: Theme.font.label.medium
            font.weight: Theme.font.label.weight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: Theme.spacing.sm
        Layout.bottomMargin: Theme.spacing.sm

        spacing: Theme.spacing.lg * 2

        Item {
            implicitWidth: 88
            implicitHeight: 88

            Image {
                id: distroLogo
                anchors.fill: parent
                source: Quickshell.iconPath(SystemInfo.logo, true)
                sourceSize: Qt.size(176, 176)
                fillMode: Image.PreserveAspectFit
            }

            ShellIcon {
                anchors.centerIn: parent
                visible: distroLogo.status !== Image.Ready
                icon.name: Icons.computer
                icon.size: 64
                icon.color: Theme.colors.active
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.md
            spacing: 2

            UIText {
                text: "yonux-shell"
                font.pixelSize: Theme.font.title.large
                font.weight: Font.Bold
                color: Theme.colors.active
            }

            UIText {
                Layout.fillWidth: true
                text: [SystemInfo.facts.yonux, `on ${SystemInfo.distro}`].filter(part => part).join(" · ")
                muted: true
                elide: Text.ElideRight
            }

            Row {
                Layout.topMargin: Theme.spacing.sm
                spacing: 4

                Repeater {
                    model: root.shellPalette

                    delegate: Rectangle {
                        id: swatch

                        required property var modelData

                        width: 28
                        height: 14
                        radius: 4
                        color: modelData[1]
                        border.color: Theme.colors.border
                        border.width: 1
                    }
                }
            }
        }
    }

    Card {
        title: "System"

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.spacing.lg
            rowSpacing: Theme.spacing.xs

            Repeater {
                model: SystemInfo.rows

                delegate: UIText {
                    required property var modelData
                    required property int index

                    Layout.row: index
                    Layout.column: 0
                    text: modelData[0]
                    muted: true
                }
            }

            Repeater {
                model: SystemInfo.rows

                delegate: UIText {
                    required property var modelData
                    required property int index

                    Layout.row: index
                    Layout.column: 1
                    Layout.fillWidth: true
                    text: modelData[1]
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    Card {
        title: "Vitals"

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.lg

            Ring {
                Layout.fillWidth: true
                label: "CPU"
                value: SystemStats.cpuPercent / 100
                text: `${SystemStats.cpuPercent}%`
                alert: SystemStats.cpuPercent > 80
            }

            Ring {
                Layout.fillWidth: true
                label: "Memory"
                value: SystemStats.memoryPercent / 100
                text: `${SystemStats.memoryPercent}%`
                alert: SystemStats.memoryPercent > 85
            }

            Ring {
                Layout.fillWidth: true
                label: "Disk"
                value: SystemStats.diskPercent / 100
                text: `${SystemStats.diskPercent}%`
                alert: SystemStats.diskPercent > 90
            }

            Ring {
                Layout.fillWidth: true
                visible: SystemStats.temperature >= 0
                label: "Temperature"
                value: SystemStats.temperature / 100
                text: `${SystemStats.temperature}°`
                alert: SystemStats.temperature > 80
            }
        }
    }

    Card {
        title: "Credits"

        Repeater {
            model: root.credits

            delegate: Rectangle {
                id: credit

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius.sm
                color: creditArea.containsMouse && modelData.url ? Theme.colors.controlHoverFill : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.sm
                    anchors.rightMargin: Theme.spacing.sm
                    spacing: Theme.spacing.md

                    UIText {
                        text: credit.modelData.name
                    }

                    UIText {
                        Layout.fillWidth: true
                        text: credit.modelData.role
                        muted: true
                    }

                    ShellIcon {
                        visible: credit.modelData.url !== ""
                        icon.name: Icons.openExternal
                        icon.color: Theme.colors.fgMuted
                    }
                }

                MouseArea {
                    id: creditArea
                    anchors.fill: parent
                    enabled: credit.modelData.url !== ""
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(credit.modelData.url)
                }
            }
        }
    }

    RowLayout {
        spacing: Theme.spacing.sm

        ShellButton {
            id: copyAction
            implicitHeight: 36
            iconFirst: true
            icon.name: Icons.copy
            text: copiedTimer.running ? "Copied" : "Copy system info"
            onClicked: {
                Quickshell.clipboardText = SystemInfo.asText();
                copiedTimer.restart();
            }

            Timer {
                id: copiedTimer
                interval: 1500
            }
        }

        ShellButton {
            visible: SystemInfo.repoUrl !== ""
            implicitHeight: 36
            iconFirst: true
            icon.name: Icons.openExternal
            text: "Open repository"
            onClicked: Qt.openUrlExternally(SystemInfo.repoUrl)
        }
    }
}
