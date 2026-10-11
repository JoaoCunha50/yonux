pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.components

Overlay {
    id: root
    name: "launcher"

    onOpened: {
        navigation.reset();
        searchField.forceActiveFocus();
    }

    onHidden: searchField.text = ""

    onFilteredAppsChanged: navigation.reset()

    readonly property var filteredApps: {
        let query = searchField.text.trim().toLowerCase();
        let entries = DesktopEntries.applications.values;

        if (entries.length === 0)
            return [];

        return entries.filter(app => !app.noDisplay).map(app => ({
                    app,
                    rank: matchRank(app, query)
                })).filter(match => match.rank >= 0).sort((a, b) => a.rank - b.rank || a.app.name.localeCompare(b.app.name)).map(match => match.app);
    }

    function matchRank(app: DesktopEntry, query: string): int {
        if (query === "")
            return 0;

        let name = app.name?.toLowerCase() ?? "";
        if (name.startsWith(query))
            return 0;
        if (name.split(/[\s\-_.]+/).some(word => word.startsWith(query)))
            return 1;
        if (name.includes(query))
            return 2;

        let extra = [app.genericName, app.comment, ...(app.keywords ?? []), ...(app.command ?? [])].join(" ").toLowerCase();
        return extra.includes(query) ? 3 : -1;
    }

    // Resolves absolute paths, theme names, or falls back to empty string
    function iconSource(icon: string): string {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true) ?? "";
    }

    function launch(entry: DesktopEntry): void {
        root.close();
        if (entry.runInTerminal) {
            Quickshell.execDetached(["xdg-terminal-exec"].concat(entry.command));
        } else {
            entry.execute();
        }
    }

    KeyboardNavigation {
        id: navigation
        enabled: root.open
        count: root.filteredApps.length
        onActivated: index => root.launch(root.filteredApps[index])
    }

    ColumnLayout {
        width: Screen.width * 0.18
        height: Screen.height * 0.4
        spacing: 14

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            placeholderText: "Search apps..."
            placeholderTextColor: Theme.colors.fgMuted

            renderType: Text.QtRendering
            font.family: Theme.font.family
            font.hintingPreference: Font.PreferFullHinting
            font.pixelSize: Theme.font.body.large

            color: Theme.colors.fg
            leftPadding: 48
            rightPadding: 16

            background: Rectangle {
                radius: Theme.radius.md
                color: Theme.colors.field
                border.color: searchField.activeFocus ? Theme.colors.active : Theme.colors.border
                border.width: 1
            }

            ShellIcon {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                icon.name: Icons.search
                icon.size: 20
                icon.color: searchField.activeFocus ? Theme.colors.active : Theme.colors.fgMuted

                Behavior on icon.color {
                    ColorAnimation {
                        duration: Motion.small
                    }
                }
            }

            Keys.forwardTo: [navigation]
        }

        ListView {
            id: appList
            model: root.filteredApps

            clip: true
            spacing: 5
            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: navigation.currentIndex
            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    positionViewAtIndex(currentIndex, ListView.Contain);
            }

            delegate: ItemDelegate {
                id: delegateRoot
                required property DesktopEntry modelData
                required property int index
                readonly property bool selected: index === navigation.currentIndex
                focusPolicy: Qt.NoFocus

                width: ListView.view.width
                height: 44
                leftPadding: 10
                rightPadding: 10
                topPadding: 0
                bottomPadding: 0

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                contentItem: RowLayout {
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            id: appIcon
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            fillMode: Image.PreserveAspectFit
                            source: root.iconSource(delegateRoot.modelData.icon)
                            asynchronous: true

                            // Graceful fallback when an icon is absent or not yet indexed by Qt
                            ShellIcon {
                                anchors.centerIn: parent
                                visible: appIcon.status !== Image.Ready
                                icon.name: Icons.apps
                                icon.size: 20
                            }
                        }
                    }

                    UIText {
                        renderType: Text.QtRendering
                        font.pixelSize: Theme.font.label.large
                        font.weight: Theme.font.label.weight

                        text: delegateRoot.modelData.name
                        color: delegateRoot.selected || delegateRoot.hovered ? Theme.colors.active : Theme.colors.fg
                        elide: Text.ElideRight

                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                    }
                }

                background: Rectangle {
                    radius: Theme.radius.md
                    color: delegateRoot.selected || delegateRoot.hovered ? Theme.colors.controlHoverFill : "transparent"
                }

                onClicked: root.launch(delegateRoot.modelData)
            }
        }
    }
}
