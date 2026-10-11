pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int maxPopups: 3
    readonly property var model: server.trackedNotifications
    readonly property var list: model.values
    property alias popupIds: persist.popupIds

    function isPopup(notification: Notification): bool {
        return popupIds.includes(notification.id);
    }

    function hidePopup(notification: Notification): void {
        popupIds = popupIds.filter(id => id !== notification.id);
    }

    function defaultAction(notification: Notification): NotificationAction {
        return notification.actions.find(action => action.identifier === "default") ?? null;
    }

    PersistentProperties {
        id: persist
        reloadableId: "notifications"

        property list<int> popupIds: []
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
            // Re-emitted on reload because of keepOnReload; popupIds already says which were on screen
            if (notification.lastGeneration)
                return;
            root.popupIds = [...root.popupIds.filter(id => id !== notification.id), notification.id].slice(-root.maxPopups);
        }
    }
}
