pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import yonux.theme

StyledTextField {
    id: root

    property var model: []
    property string textRole: "label"
    property string valueRole: "value"
    property var currentValue: ""
    property string query: ""
    property int highlightedIndex: -1

    readonly property bool expanded: choices.visible
    readonly property var matches: model.filter(item => labelFor(item).toLowerCase().includes(query.trim().toLowerCase()))
    readonly property string currentText: {
        const item = model.find(item => valueFor(item) === currentValue);
        return item === undefined ? "" : labelFor(item);
    }

    signal activated(value: var, item: var)

    rightPadding: Theme.spacing.md + 24
    placeholderText: "Search and select…"
    onCurrentTextChanged: if (!choices.visible)
        text = currentText

    onMatchesChanged: highlightedIndex = matches.length ? 0 : -1

    onTextEdited: {
        query = text;
        choices.open();
        highlightedIndex = matches.length ? 0 : -1;
    }

    onPressed: openChoices()

    onActiveFocusChanged: {
        if (activeFocus)
            openChoices();
        else
            choices.close();
    }

    onVisibleChanged: if (!visible)
        resetSearch()

    Component.onCompleted: text = currentText

    function labelFor(item): string {
        return String(typeof item === "object" ? item[textRole] ?? "" : item);
    }

    function valueFor(item): var {
        return typeof item === "object" ? item[valueRole] : item;
    }

    function openChoices(): void {
        if (choices.visible || !visible || !enabled)
            return;
        query = "";
        text = "";
        const selected = matches.findIndex(item => valueFor(item) === currentValue);
        highlightedIndex = selected >= 0 ? selected : matches.length ? 0 : -1;
        choices.open();
        selectAll();
    }

    function resetSearch(): void {
        choices.close();
        query = "";
        text = currentText;
    }

    function choose(index: int): void {
        if (index < 0 || index >= matches.length)
            return;
        const item = matches[index];
        activated(valueFor(item), item);
        choices.close();
        query = "";
        text = currentText;
        selectAll();
    }

    function moveHighlight(delta: int): void {
        if (!choices.visible)
            openChoices();
        if (!matches.length) {
            highlightedIndex = -1;
            return;
        }
        highlightedIndex = Math.max(0, Math.min(matches.length - 1, highlightedIndex + delta));
        list.positionViewAtIndex(highlightedIndex, ListView.Contain);
    }

    Keys.onDownPressed: event => {
        moveHighlight(1);
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        moveHighlight(-1);
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        if (choices.visible) {
            choose(highlightedIndex);
            event.accepted = true;
        }
    }
    Keys.onEnterPressed: event => {
        if (choices.visible) {
            choose(highlightedIndex);
            event.accepted = true;
        }
    }
    Keys.onEscapePressed: event => {
        if (choices.visible) {
            resetSearch();
            event.accepted = true;
        }
    }

    ShellIcon {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        icon.name: Icons.expand
        icon.size: 18
        icon.color: Theme.colors.fgMuted
        rotation: choices.visible ? 180 : 0
    }

    MouseArea {
        anchors.right: parent.right
        width: 30
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (choices.visible)
                root.resetSearch();
            else {
                root.forceActiveFocus();
                root.openChoices();
            }
        }
    }

    Controls.Popup {
        id: choices
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(260, Math.max(40, list.contentHeight) + padding * 2)
        padding: Theme.spacing.xs
        focus: false
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutsideParent
        onClosed: {
            root.query = "";
            root.text = root.currentText;
        }

        background: Rectangle {
            color: Theme.colors.surface
            radius: Theme.radius.md
            border.width: 1
            border.color: Theme.colors.border
        }

        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: root.matches
            currentIndex: root.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            delegate: ShellButton {
                id: option
                required property var modelData
                required property int index
                width: list.width
                implicitHeight: 34
                showDefaultContent: false
                color: root.highlightedIndex === index ? Theme.colors.controlHoverFill : "transparent"
                onHoveredChanged: if (hovered)
                    root.highlightedIndex = index
                onClicked: root.choose(index)

                UIText {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.md
                    anchors.rightMargin: Theme.spacing.md
                    text: root.labelFor(option.modelData)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: root.valueFor(option.modelData) === root.currentValue ? Theme.colors.active : Theme.colors.fg
                }
            }

            UIText {
                anchors.centerIn: parent
                visible: root.matches.length === 0
                text: "No results"
                muted: true
            }
        }
    }
}
