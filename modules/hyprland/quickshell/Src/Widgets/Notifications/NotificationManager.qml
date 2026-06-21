import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Src.Services as Services
import Src.Ui as Ui

Item {
    id: root

    Services.NotificationService {
        id: notificationService
    }

    PanelWindow {
        id: notificationWindow

        readonly property int notificationCount: notificationService.visibleNotifications.length

        width: 360
        height: Math.min(620, Math.max(1, notificationColumn.implicitHeight))
        visible: notificationCount > 0
        color: Ui.Theme.transparent
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-overlay-notifications"

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
