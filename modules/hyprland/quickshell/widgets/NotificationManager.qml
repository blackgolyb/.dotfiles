import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

Item {
    id: root

    property var visibleNotifications: []
    property var notificationsById: ({})
    property var notificationsByStackTag: ({})
    readonly property int defaultTimeoutMs: 5000

    function hintValue(hints, key) {
        if (hints == null)
            return "";

        const value = hints[key];
        if (value === undefined || value === null)
            return "";

        const unwrapped = value.value !== undefined ? value.value : value;
        const text = String(unwrapped);
        return text.length > 0 ? text : "";
    }

    function stackTagFor(notification) {
        const hints = notification.hints;
        return root.hintValue(hints, "x-quickshell-stack-tag") || root.hintValue(hints, "x-dunst-stack-tag") || root.hintValue(hints, "x-canonical-private-synchronous");
    }

    function timeoutMsFor(notification) {
        if (notification.expireTimeout === 0)
            return 0;
        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        return root.defaultTimeoutMs;
    }

    function trackNotification(notification) {
        const stackTag = root.stackTagFor(notification);
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

    function addNotification(notification, stackTag) {
        root.visibleNotifications = root.visibleNotifications.concat([
            {
                notification,
                stackTag,
                serial: `${notification.id}:${Date.now()}`
            }
        ]);

        const nextIdMap = Object.assign({}, root.notificationsById);
        nextIdMap[String(notification.id)] = notification;
        root.notificationsById = nextIdMap;

        if (stackTag.length > 0) {
            const nextMap = Object.assign({}, root.notificationsByStackTag);
            nextMap[stackTag] = notification;
            root.notificationsByStackTag = nextMap;
        }
    }

    function replaceNotification(oldNotification, notification, stackTag) {
        const nextNotifications = root.visibleNotifications.slice();
        const index = nextNotifications.findIndex(entry => entry.notification === oldNotification);

        if (index === -1) {
            root.removeStackTag(stackTag, oldNotification);
            return false;
        }

        nextNotifications[index] = {
            notification,
            stackTag,
            serial: `${notification.id}:${Date.now()}`
        };
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

    function removeNotification(notification) {
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

    function removeStackTag(stackTag, notification) {
        const nextMap = Object.assign({}, root.notificationsByStackTag);
        if (nextMap[stackTag] === notification)
            delete nextMap[stackTag];
        root.notificationsByStackTag = nextMap;
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

    PanelWindow {
        id: notificationWindow

        readonly property int notificationCount: root.visibleNotifications.length

        width: 360
        height: Math.min(620, Math.max(1, notificationColumn.implicitHeight))
        visible: notificationCount > 0
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        anchors {
            top: true
            right: true
        }

        margins {
            top: 38
            right: 12
        }

        ColumnLayout {
            id: notificationColumn
            anchors.fill: parent
            spacing: 8

            Repeater {
                model: root.visibleNotifications

                Rectangle {
                    id: card

                    required property var modelData

                    readonly property var notification: modelData.notification
                    readonly property string serial: modelData.serial
                    readonly property int autoExpireMs: root.timeoutMsFor(notification)
                    readonly property bool shouldAutoExpire: autoExpireMs > 0 && !notification.resident && notification.urgency !== NotificationUrgency.Critical

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(84, cardContent.implicitHeight + 24)
                    radius: 14
                    color: "#2e3440"
                    border.width: 1
                    border.color: urgencyColor(card.notification.urgency)
                    opacity: 0
                    x: 24

                    Component.onCompleted: {
                        opacity = 1;
                        x = 0;
                        restartExpireTimer();
                    }

                    onSerialChanged: restartExpireTimer()
                    onAutoExpireMsChanged: restartExpireTimer()
                    onShouldAutoExpireChanged: restartExpireTimer()

                    function restartExpireTimer() {
                        expireTimer.stop();
                        if (card.shouldAutoExpire)
                            expireTimer.start();
                    }

                    function urgencyColor(urgency) {
                        if (urgency === NotificationUrgency.Critical)
                            return "#bf616a";
                        if (urgency === NotificationUrgency.Low)
                            return "#4c566a";
                        return "#88c0d0";
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                        }
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Timer {
                        id: expireTimer
                        interval: Math.max(1, card.autoExpireMs)
                        running: false
                        repeat: false
                        onTriggered: card.notification.expire()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: card.notification.dismiss()
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 9
                                color: "#252b35"
                                visible: card.notification.image.length === 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 17
                                }
                            }

                            Image {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                visible: card.notification.image.length > 0
                                source: card.notification.image
                                fillMode: Image.PreserveAspectCrop
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: card.notification.summary
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: card.notification.appName
                                    color: "#8f98aa"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    visible: card.notification.appName.length > 0
                                }
                            }

                            Text {
                                text: "×"
                                color: closeMouse.containsMouse ? "#ffffff" : "#8f98aa"
                                font.pixelSize: 18

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: card.notification.dismiss()
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.notification.body
                            textFormat: Text.RichText
                            color: "#c3c3c3"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            visible: card.notification.body.length > 0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: card.notification.actions.length > 0
                            spacing: 6

                            Item {
                                Layout.fillWidth: true
                            }

                            Repeater {
                                model: card.notification.actions

                                Rectangle {
                                    required property var modelData

                                    Layout.preferredWidth: Math.max(actionText.implicitWidth + 18, 52)
                                    Layout.preferredHeight: 26
                                    radius: 8
                                    color: actionMouse.containsMouse ? "#4c566a" : "#3b4252"

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        color: "#ffffff"
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: parent.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
