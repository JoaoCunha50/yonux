pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.services

Singleton {
    id: root

    readonly property int maxToasts: 3
    readonly property int maxHistory: 100
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/yonux`
    readonly property string imageDir: `${stateDir}/notification-images`

    property bool viewing: false

    property list<NotificationEntry> entries: []
    readonly property list<NotificationEntry> history: entries.filter(entry => !entry.ephemeral)
    readonly property var toasts: toastIds.map(id => entries.find(entry => entry.live && entry.notificationId === id)).filter(entry => entry)

    readonly property var groups: {
        let byApp = new Map();
        for (let entry of history) {
            if (!byApp.has(entry.appName))
                byApp.set(entry.appName, []);
            byApp.get(entry.appName).push(entry);
        }
        return [...byApp].map(([appName, entries]) => ({
                    appName,
                    entries
                }));
    }

    readonly property bool dnd: root.saved.dnd
    readonly property real lastSeen: root.saved.lastSeen
    readonly property bool unread: history.some(entry => entry.time > lastSeen)

    property alias toastIds: persist.toastIds

    readonly property SavedState saved: SavedState {}

    onViewingChanged: {
        if (viewing)
            toastIds = [];
        else
            root.saved.lastSeen = Date.now();
    }

    function setDnd(value: bool): void {
        root.saved.dnd = value;
    }

    function dismissGroup(appName: string): void {
        dismissAll(history.filter(entry => entry.appName === appName));
    }

    function clear(): void {
        dismissAll(history);
    }

    function dismissAll(entries: var): void {
        let live = entries.map(entry => entry.notification).filter(notification => notification);
        remove(entries);
        live.forEach(notification => notification.dismiss());
    }

    function remove(removed: var): void {
        if (removed.length === 0)
            return;
        entries = entries.filter(entry => !removed.includes(entry));
        for (let entry of removed) {
            if (entry.image.startsWith(imageDir))
                Quickshell.execDetached(["rm", "-f", entry.image]);
            entry.destroy();
        }
        saveTimer.restart();
    }

    function showToast(entry: NotificationEntry): void {
        toastIds = [...toastIds.filter(id => id !== entry.notificationId), entry.notificationId].slice(-maxToasts);
    }

    function hideToast(entry: NotificationEntry): void {
        toastIds = toastIds.filter(id => id !== entry.notificationId);
        if (entry.ephemeral) {
            let notification = entry.notification;
            remove([entry]);
            notification?.expire();
        }
    }

    function isQuiet(notification: Notification): bool {
        if (viewing)
            return true;
        let silenced = notification.urgency !== NotificationUrgency.Critical && notification.appName !== "yonux";
        return root.saved.dnd && silenced;
    }

    function receive(notification: Notification): void {
        notification.tracked = true;

        // keepOnReload re-emits every live notification; reattach it to its restored entry instead of adding a duplicate
        if (notification.lastGeneration) {
            let restored = entries.find(entry => !entry.live && entry.notificationId === notification.id && entry.summary === notification.summary);
            if (restored) {
                restored.attach(notification);
                return;
            }
        }

        let entry = entryComponent.createObject(root, {
            time: Date.now()
        });
        entry.attach(notification);
        entries = [entry, ...entries];
        remove(history.slice(maxHistory));
        entry.cacheImage();
        saveTimer.restart();

        if (!notification.lastGeneration && !isQuiet(notification))
            showToast(entry);
    }

    function syncGameMode(): void {
        if (!GameMode.ready || GameMode.active === root.saved.gameMode)
            return;
        root.saved.gameMode = GameMode.active;
        if (GameMode.active) {
            root.saved.dndBeforeGameMode = root.saved.dnd;
            root.saved.dnd = true;
        } else {
            root.saved.dnd = root.saved.dndBeforeGameMode;
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", imageDir])

    Connections {
        target: GameMode
        function onActiveChanged(): void {
            root.syncGameMode();
        }
        function onReadyChanged(): void {
            root.syncGameMode();
        }
    }

    component SavedState: JsonAdapter {
        property bool dnd: false
        property bool dndBeforeGameMode: false
        property bool gameMode: false
        property real lastSeen: 0
    }

    component NotificationEntry: QtObject {
        id: entry

        property Notification notification: null
        property int notificationId
        property bool ephemeral: false
        property string appName
        property string appIcon
        property string summary
        property string body
        property string image
        property int urgency: NotificationUrgency.Normal
        property int timeout: 0
        property real time

        readonly property bool live: notification !== null
        readonly property bool critical: urgency === NotificationUrgency.Critical
        readonly property bool showingToast: root.toastIds.includes(notificationId) && live
        readonly property string icon: image || appIcon
        readonly property NotificationAction defaultAction: notification?.actions.find(action => action.identifier === "default") ?? null
        readonly property var actions: notification?.actions.filter(action => action.identifier !== "default") ?? []

        function activate(): void {
            if (defaultAction)
                invoke(defaultAction);
            else
                root.hideToast(entry);
        }

        function invoke(action: NotificationAction): void {
            root.hideToast(entry);
            action.invoke();
        }

        function dismiss(): void {
            root.dismissAll([entry]);
        }

        function hideToast(): void {
            root.hideToast(entry);
        }

        function attach(notification: Notification): void {
            this.notification = notification;
            notificationId = notification.id;
            ephemeral = notification.transient;

            appName = Qt.binding(() => notification.appName);
            appIcon = Qt.binding(() => notification.appIcon);
            summary = Qt.binding(() => notification.summary);
            body = Qt.binding(() => notification.body);
            urgency = Qt.binding(() => notification.urgency);
            timeout = Qt.binding(() => notification.expireTimeout);

            if (!image.startsWith(root.imageDir))
                image = Qt.binding(() => notification.image);
            notification.closed.connect(() => root.remove(root.entries.filter(other => other === entry)));
        }

        function cacheImage(): void {
            let fromFile = image.startsWith("image://icon//");
            let themeIcon = image.startsWith("image://icon/") && !fromFile;
            if (!ephemeral && image !== "" && !themeIcon)
                imageCache.active = true;
        }

        function toJSON(): var {
            return {
                notificationId,
                appName,
                appIcon,
                summary,
                body,
                image: image.startsWith(root.imageDir) ? image : "",
                urgency,
                time
            };
        }

        readonly property LazyLoader imageCache: LazyLoader {
            active: false

            PanelWindow { // qmllint disable uncreatable-type
                implicitWidth: 40
                implicitHeight: 40
                color: "transparent"
                exclusiveZone: 0
                mask: Region {}

                WlrLayershell.namespace: "yonux-image-cache"

                Image {
                    id: picture
                    anchors.fill: parent
                    source: entry.image.startsWith("/") ? `file://${entry.image}` : entry.image
                    sourceSize: Qt.size(80, 80)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: 0

                    onStatusChanged: {
                        if (status === Image.Ready)
                            grab.start();
                        else if (status === Image.Error)
                            entry.imageCache.active = false;
                    }

                    Timer {
                        id: grab
                        interval: 50
                        repeat: true
                        onTriggered: {
                            let path = `${root.imageDir}/${Qt.md5(entry.time + entry.appName + entry.summary + entry.image)}.png`;
                            let started = picture.grabToImage(result => {
                                if (result.saveToFile(path)) {
                                    entry.image = path;
                                    saveTimer.restart();
                                }
                                entry.imageCache.active = false;
                            }, Qt.size(80, 80));
                            if (started)
                                stop();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: entryComponent
        NotificationEntry {}
    }

    PersistentProperties {
        id: persist
        reloadableId: "notifications"

        property list<int> toastIds: []
    }

    FileView {
        path: `${root.stateDir}/state.json`
        blockLoading: true
        printErrors: false

        adapter: root.saved // qmllint disable
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }
    }

    FileView {
        id: historyFile
        path: `${root.stateDir}/notifications.json`
        blockLoading: true
        printErrors: false

        onLoaded: {
            let restored;
            try {
                restored = JSON.parse(text());
            } catch (e) {
                return;
            }
            if (Array.isArray(restored))
                root.entries = restored.slice(0, root.maxHistory).map(data => entryComponent.createObject(root, data));
        }
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: historyFile.setText(JSON.stringify(root.history.map(entry => entry.toJSON()), null, 2) + "\n")
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => root.receive(notification)
    }
}
