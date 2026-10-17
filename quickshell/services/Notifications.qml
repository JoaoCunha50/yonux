pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.components
import qs.services

Singleton {
    id: root

    readonly property int maxPopups: 3
    readonly property int maxHistory: 100
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/yonux`
    readonly property string imageDir: `${stateDir}/notification-images`

    readonly property var model: server.trackedNotifications
    property alias popupIds: persist.popupIds

    property list<Entry> history: []
    readonly property var groups: {
        let map = new Map();
        for (let entry of history) {
            if (!map.has(entry.appName))
                map.set(entry.appName, []);
            map.get(entry.appName).push(entry);
        }
        return [...map].map(([appName, entries]) => ({
                    appName,
                    entries
                }));
    }

    readonly property bool panelOpen: OverlayManager.current === "controlcenter"
    readonly property bool dnd: saved.dnd
    readonly property real lastSeen: saved.lastSeen
    readonly property bool unread: history.some(entry => entry.time > lastSeen)

    onPanelOpenChanged: {
        if (panelOpen)
            popupIds = [];
        else
            saved.lastSeen = Date.now();
    }

    function setDnd(value: bool): void {
        saved.dnd = value;
    }

    function iconSource(icon: string): string {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("image://icon/"))
            return iconSource(icon.slice(13).split("?")[0]);
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true) ?? "";
    }

    function isPopup(notification: Notification): bool {
        return popupIds.includes(notification.id);
    }

    function hidePopup(notification: Notification): void {
        popupIds = popupIds.filter(id => id !== notification.id);
    }

    function defaultAction(notification: Notification): NotificationAction {
        return notification.actions.find(action => action.identifier === "default") ?? null;
    }

    function activate(entry: Entry): void {
        let action = entry.notification ? defaultAction(entry.notification) : null;
        if (!action)
            return;
        OverlayManager.close();
        action.invoke();
    }

    function dismiss(entry: Entry): void {
        let notification = entry.notification;
        remove([entry]);
        notification?.dismiss();
    }

    function dismissGroup(appName: string): void {
        let entries = history.filter(entry => entry.appName === appName);
        let live = entries.map(entry => entry.notification).filter(notification => notification);
        remove(entries);
        live.forEach(notification => notification.dismiss());
    }

    function clear(): void {
        let live = history.map(entry => entry.notification).filter(notification => notification);
        remove([...history]);
        live.forEach(notification => notification.dismiss());
    }

    function remove(entries: var): void {
        if (entries.length === 0)
            return;
        history = history.filter(entry => !entries.includes(entry));
        for (let entry of entries) {
            if (entry.image.startsWith(imageDir))
                Quickshell.execDetached(["rm", "-f", entry.image]);
            entry.destroy();
        }
        saveTimer.restart();
    }

    function add(notification: Notification): void {
        if (notification.transient)
            return;

        if (notification.lastGeneration) {
            let restored = history.find(entry => !entry.notification && entry.notificationId === notification.id && entry.summary === notification.summary);
            if (restored) {
                restored.attach(notification);
                return;
            }
        }

        let entry = entryComponent.createObject(root, {
            time: Date.now()
        });
        entry.attach(notification);
        history = [entry, ...history];
        remove(history.slice(maxHistory));
        entry.cacheImage();
        saveTimer.restart();
    }

    function syncGameMode(): void {
        if (!GameMode.ready || GameMode.active === saved.gameMode)
            return;
        saved.gameMode = GameMode.active;
        if (GameMode.active) {
            saved.dndBeforeGameMode = saved.dnd;
            saved.dnd = true;
        } else {
            saved.dnd = saved.dndBeforeGameMode;
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

    component Entry: QtObject {
        id: entry

        property Notification notification: null
        property int notificationId
        property string appName
        property string appIcon
        property string summary
        property string body
        property string image
        property int urgency: NotificationUrgency.Normal
        property real time

        readonly property bool critical: urgency === NotificationUrgency.Critical

        function attach(notification: Notification): void {
            this.notification = notification;
            notificationId = notification.id;
            appName = Qt.binding(() => notification.appName);
            appIcon = Qt.binding(() => notification.appIcon);
            summary = Qt.binding(() => notification.summary);
            body = Qt.binding(() => notification.body);
            urgency = Qt.binding(() => notification.urgency);
            if (!image.startsWith(root.imageDir))
                image = Qt.binding(() => notification.image);
            notification.closed.connect(() => root.remove(root.history.filter(other => other === entry)));
        }

        function cacheImage(): void {
            if (image !== "" && (!image.startsWith("image://icon/") || image.startsWith("image://icon//")))
                cacher.active = true;
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

        readonly property LazyLoader cacher: LazyLoader {
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
                            entry.cacher.active = false;
                    }

                    Timer {
                        id: grab
                        interval: 50
                        repeat: true
                        onTriggered: {
                            let sha = Qt.md5(entry.time + entry.appName + entry.summary + entry.image);
                            let path = `${root.imageDir}/${sha}.png`;

                            let started = picture.grabToImage(result => {
                                if (result.saveToFile(path)) {
                                    entry.image = path;
                                    saveTimer.restart();
                                }
                                entry.cacher.active = false;
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
        Entry {}
    }

    PersistentProperties {
        id: persist
        reloadableId: "notifications"

        property list<int> popupIds: []
    }

    FileView {
        id: stateFile
        path: `${root.stateDir}/state.json`
        blockLoading: true
        printErrors: false

        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: saved

            property bool dnd: false
            property bool dndBeforeGameMode: false
            property bool gameMode: false
            property real lastSeen: 0
        }
    }

    FileView {
        id: historyFile
        path: `${root.stateDir}/notifications.json`
        blockLoading: true
        printErrors: false

        onLoaded: {
            let saved;
            try {
                saved = JSON.parse(text());
            } catch (e) {
                return;
            }
            if (!Array.isArray(saved))
                return;
            root.history = saved.slice(0, root.maxHistory).map(data => entryComponent.createObject(root, data));
        }
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: historyFile.setText(JSON.stringify(root.history.map(entry => entry.toJSON()), null, 2) + "\n")
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.add(notification);
            // Re-emitted on reload because of keepOnReload; popupIds already says which were on screen
            if (notification.lastGeneration)
                return;
            let quiet = root.panelOpen || (saved.dnd && notification.urgency !== NotificationUrgency.Critical && notification.appName !== "yonux");
            if (!quiet)
                root.popupIds = [...root.popupIds.filter(id => id !== notification.id), notification.id].slice(-root.maxPopups);
        }
    }
}
