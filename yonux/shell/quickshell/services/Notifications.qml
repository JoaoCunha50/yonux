pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import yonux.config
import yonux.services

Singleton {
    id: root

    readonly property int maxToasts: 3
    readonly property int maxHistory: 100
    readonly property string imageDir: `${Paths.state}/notification-images`

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

    readonly property bool dnd: savedState.value("dnd")
    readonly property real lastSeen: savedState.value("lastSeen")
    readonly property bool unread: history.some(entry => entry.time > lastSeen)

    property alias toastIds: persist.toastIds

    onViewingChanged: {
        if (viewing)
            toastIds = [];
        else
            savedState.set("lastSeen", Date.now());
    }

    function saveHistory(): void {
        historyFile.save(history.map(entry => entry.toJSON()));
    }

    function restore(saved: var): void {
        let restored = [];
        for (let data of saved.slice(0, maxHistory)) {
            let live = entries.find(entry => entry.notificationId === data.notificationId && entry.summary === data.summary);
            if (live) {
                live.time = data.time;
                if (data.image)
                    live.image = data.image;
            } else {
                restored.push(entryComponent.createObject(root, data));
            }
        }
        entries = [...entries, ...restored].sort((a, b) => b.time - a.time);
    }

    function setDnd(value: bool): void {
        savedState.set("dnd", value);
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
        root.saveHistory();
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
        return dnd && silenced;
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
        root.saveHistory();

        if (!notification.lastGeneration && !isQuiet(notification))
            showToast(entry);
    }

    function syncGameMode(): void {
        if (!GameMode.ready || !savedState.ready || GameMode.active === savedState.value("gameMode"))
            return;
        savedState.set("gameMode", GameMode.active);
        if (GameMode.active) {
            savedState.set("dndBeforeGameMode", dnd);
            savedState.set("dnd", true);
        } else {
            savedState.set("dnd", savedState.value("dndBeforeGameMode"));
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
                                    root.saveHistory();
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

    JsonConfig {
        id: savedState
        path: `${Paths.state}/state.json`
        defaults: ({
                dnd: false,
                dndBeforeGameMode: false,
                gameMode: false,
                lastSeen: 0
            })
    }

    JsonFile {
        id: historyFile
        path: `${Paths.state}/notifications.json`
        saveDelay: 1000

        onDocumentLoaded: if (Array.isArray(document))
            root.restore(document)
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
