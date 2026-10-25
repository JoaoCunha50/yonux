import QtQuick

Item {
    id: root

    property int count: 0
    property int currentIndex: count > 0 ? 0 : -1
    property int orientation: Qt.Vertical

    property bool wrap: true
    property bool navigationEnabled: true
    property bool spaceActivates: false
    property bool repeatNavigation: true

    readonly property list<int> previousKeys: [Qt.Key_Backtab, orientation === Qt.Vertical ? Qt.Key_Up : Qt.Key_Left]
    readonly property list<int> nextKeys: [Qt.Key_Tab, orientation === Qt.Vertical ? Qt.Key_Down : Qt.Key_Right]
    readonly property list<int> activationKeys: spaceActivates ? [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space] : [Qt.Key_Return, Qt.Key_Enter]

    signal activated(int index)
    signal activationPressed(int index)
    signal activationReleased

    function reset(): void {
        currentIndex = count > 0 ? 0 : -1;
    }

    function step(delta: int): void {
        if (!navigationEnabled || count <= 0)
            return;
        if (currentIndex < 0) {
            currentIndex = delta > 0 ? 0 : count - 1;
            return;
        }
        currentIndex = wrap ? (currentIndex + delta + count) % count : Math.max(0, Math.min(count - 1, currentIndex + delta));
    }

    onCountChanged: {
        if (count <= 0)
            currentIndex = -1;
        else
            currentIndex = Math.max(0, Math.min(count - 1, currentIndex));
    }

    Keys.onPressed: event => {
        // Some backends report Shift+Tab as Tab rather than Backtab.
        let key = event.key;
        if (key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))
            key = Qt.Key_Backtab;

        if (previousKeys.includes(key)) {
            event.accepted = true;
            if (!event.isAutoRepeat || repeatNavigation)
                step(-1);
        } else if (nextKeys.includes(key)) {
            event.accepted = true;
            if (!event.isAutoRepeat || repeatNavigation)
                step(1);
        } else if (activationKeys.includes(key)) {
            event.accepted = true;
            if (!event.isAutoRepeat && currentIndex >= 0 && currentIndex < count) {
                activationPressed(currentIndex);
                activated(currentIndex);
            }
        }
    }

    Keys.onReleased: event => {
        if (activationKeys.includes(event.key)) {
            event.accepted = true;
            if (!event.isAutoRepeat)
                activationReleased();
        }
    }
}
