import QtQuick
import Src.Ui as Ui

Ui.UiPopup {
    id: root

    required property var service

    anchor.rect.x: root.anchorWindow != null ? root.anchorWindow.width - root.implicitWidth - 84 : 0
    anchor.rect.y: root.anchorWindow != null ? root.anchorWindow.height + 8 : 0
    implicitWidth: 420
    implicitHeight: 500
    grabFocus: true

    onVisibleChanged: {
        if (visible)
            wifiScreen.focusSearch();
        else
            root.service.closePasswordPrompt();
    }

    Ui.UiCard {
        anchors.fill: parent
        scale: root.visible ? 1 : 0.96
        opacity: root.visible ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        WifiScreen {
            id: wifiScreen

            anchors.fill: parent
            service: root.service
            showBackButton: false
            margins: 14
            qrSize: 120
        }
    }
}
