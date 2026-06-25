import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    property var visibleNotifications: []
    property var notificationsById: ({})
    property var notificationsByStackTag: ({})
    readonly property var ignoredOsdAppNames: ["changevolume", "changebrightness"]
    readonly property var ignoredOsdStackTags: []
    readonly property bool hasExpiringNotifications: visibleNotifications.some(entry => entry.expiresAt > 0)
    readonly property int defaultTimeoutMs: 5000

    visible: false

    function hintValue(hints, key): string {
        if (hints == null)
            return "";

        const value = hints[key];
        if (value === undefined || value === null)
            return "";

        const unwrapped = value.value !== undefined ? value.value : value;
        const text = String(unwrapped);
        return text.length > 0 ? text : "";
    }

    function stackTagFor(notification): string {
        const hints = notification.hints;
        return root.hintValue(hints, "x-quickshell-stack-tag") || root.hintValue(hints, "x-dunst-stack-tag") || root.hintValue(hints, "x-canonical-private-synchronous");
    }

    function timeoutMsFor(notification): int {
        if (notification.expireTimeout === 0)
            return 0;
        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        return root.defaultTimeoutMs;
    }

    function shouldAutoExpire(notification): bool {
        return root.timeoutMsFor(notification) > 0 && !notification.resident && notification.urgency !== NotificationUrgency.Critical;
    }

    function normalizedText(value): string {
        return String(value ?? "").toLowerCase();
    }

    function shouldIgnore(notification, stackTag): bool {
        const appName = root.normalizedText(notification.appName);
        const tag = root.normalizedText(stackTag);

        return root.ignoredOsdAppNames.includes(appName) || root.ignoredOsdStackTags.includes(tag);
    }

    function entryFor(notification, stackTag): var {
        const timeoutMs = root.timeoutMsFor(notification);
        const expiresAt = root.shouldAutoExpire(notification) ? Date.now() + timeoutMs : 0;
        return {
            notification,
            stackTag,
            serial: `${notification.id}:${Date.now()}`,
            expiresAt,
            timeoutMs
        };
    }

    function expireDueNotifications(): void {
        const now = Date.now();
        const dueNotifications = root.visibleNotifications.filter(entry => entry.expiresAt > 0 && entry.expiresAt <= now).map(entry => entry.notification);

        for (const notification of dueNotifications)
            root.expire(notification);
    }

    function trackNotification(notification): void {
        const stackTag = root.stackTagFor(notification);
        if (root.shouldIgnore(notification, stackTag)) {
            notification.tracked = true;
            notification.dismiss();
            return;
        }

        notification.tracked = true;
        notification.closed.connect(() => root.removeNotification(notification));

        if (stackTag.length > 0 && root.notificationsByStackTag[stackTag] !== undefined) {
            const oldNotification = root.notificationsByStackTag[stackTag];
            const replaced = root.replaceNotification(oldNotification, notification, stackTag);
            if (replaced)
                return;
        }

        const idKey = String(notification.id);
        if (root.notificationsById[idKey] !== undefined) {
            const oldNotification = root.notificationsById[idKey];
            const replaced = root.replaceNotification(oldNotification, notification, stackTag);
            if (replaced)
                return;
        }

        root.addNotification(notification, stackTag);
    }

    function addNotification(notification, stackTag): void {
        root.visibleNotifications = root.visibleNotifications.concat([root.entryFor(notification, stackTag)]);

        const nextIdMap = Object.assign({}, root.notificationsById);
        nextIdMap[String(notification.id)] = notification;
        root.notificationsById = nextIdMap;

        if (stackTag.length > 0) {
            const nextMap = Object.assign({}, root.notificationsByStackTag);
            nextMap[stackTag] = notification;
            root.notificationsByStackTag = nextMap;
        }
    }

    function replaceNotification(oldNotification, notification, stackTag): bool {
        const nextNotifications = root.visibleNotifications.slice();
        const index = nextNotifications.findIndex(entry => entry.notification === oldNotification);

        if (index === -1) {
            root.removeStackTag(stackTag, oldNotification);
            return false;
        }

        nextNotifications[index] = root.entryFor(notification, stackTag);
        root.visibleNotifications = nextNotifications;

        const nextIdMap = Object.assign({}, root.notificationsById);
        for (const id in nextIdMap) {
            if (nextIdMap[id] === oldNotification)
                delete nextIdMap[id];
        }
        nextIdMap[String(notification.id)] = notification;
        root.notificationsById = nextIdMap;

        const nextMap = Object.assign({}, root.notificationsByStackTag);
        for (const existingStackTag in nextMap) {
            if (nextMap[existingStackTag] === oldNotification)
                delete nextMap[existingStackTag];
        }
        if (stackTag.length > 0)
            nextMap[stackTag] = notification;
        root.notificationsByStackTag = nextMap;

        if (oldNotification !== notification)
            oldNotification.tracked = false;

        return true;
    }

    function removeNotification(notification): void {
        const nextNotifications = root.visibleNotifications.filter(entry => entry.notification !== notification);
        if (nextNotifications.length !== root.visibleNotifications.length)
            root.visibleNotifications = nextNotifications;

        const nextIdMap = Object.assign({}, root.notificationsById);
        for (const id in nextIdMap) {
            if (nextIdMap[id] === notification)
                delete nextIdMap[id];
        }
        root.notificationsById = nextIdMap;

        const nextMap = Object.assign({}, root.notificationsByStackTag);
        for (const stackTag in nextMap) {
            if (nextMap[stackTag] === notification)
                delete nextMap[stackTag];
        }
        root.notificationsByStackTag = nextMap;
    }

    function removeStackTag(stackTag, notification): void {
        const nextMap = Object.assign({}, root.notificationsByStackTag);
        if (nextMap[stackTag] === notification)
            delete nextMap[stackTag];
        root.notificationsByStackTag = nextMap;
    }

    function dismiss(notification): void {
        notification.dismiss();
    }

    function expire(notification): void {
        notification.expire();
    }

    function invokeAction(action): void {
        action.invoke();
    }

    Timer {
        id: expiryTimer
        interval: 250
        repeat: true
        running: root.hasExpiringNotifications
        onTriggered: root.expireDueNotifications()
    }

    NotificationServer {
        id: notificationServer
        actionsSupported: true
        bodyMarkupSupported: true
        extraHints: ["x-quickshell-stack-tag", "x-dunst-stack-tag", "x-canonical-private-synchronous"]
        imageSupported: true
        keepOnReload: false

        onNotification: notification => {
            root.trackNotification(notification);
        }
    }
}
