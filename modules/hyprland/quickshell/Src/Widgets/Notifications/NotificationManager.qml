import QtQuick
import QtQuick.Layouts
import Quickshell
import Src.Services as Services
import Src.Ui as Ui

Item {
    id: root

    Services.NotificationService {
        id: notificationService
    }

    Ui.UiOverlay {
        id: notificationWindow

        readonly property int notificationCount: notificationService.visibleNotifications.length

        implicitWidth: 360
        implicitHeight: Math.min(620, Math.max(1, notificationColumn.implicitHeight))
        visible: notificationCount > 0
        namespaceName: "notifications"
        enableBlur: true
        exclusiveZone: 0

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
                model: notificationService.visibleNotifications

                NotificationBubble {
                    required property var modelData

                    entry: modelData
                    onDismissRequested: notification => notificationService.dismiss(notification)
                    onActionRequested: action => notificationService.invokeAction(action)
                }
            }
        }
    }
}
