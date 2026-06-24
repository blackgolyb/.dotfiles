import QtQuick
import Quickshell.Hyprland
import Src.Ui as Ui

Item {
    id: root

    required property var anchorWindow

    readonly property string buttonText: wifiService.wifiEnabled ? "󰤨" : "󰤭"
    property bool menuOpen: false

    implicitWidth: wifiText.implicitWidth
    implicitHeight: wifiText.implicitHeight

    WifiService {
        id: wifiService
    }

    Ui.UiIcon {
        id: wifiText
        text: root.buttonText
        color: root.menuOpen ? Ui.Theme.textPrimary : Ui.Theme.textSecondary
        font.pixelSize: Ui.Theme.textXl

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.menuOpen = !root.menuOpen;
            if (root.menuOpen)
                wifiService.refresh(false);
        }
    }

    WifiPopup {
        id: popup
        anchorWindow: root.anchorWindow
        service: wifiService
        visible: root.menuOpen
        onVisibleChanged: {
            root.menuOpen = visible;
            wifiFocusGrab.active = visible;
        }
    }

    HyprlandFocusGrab {
        id: wifiFocusGrab
        windows: [popup]
        onCleared: root.menuOpen = false
    }
}
