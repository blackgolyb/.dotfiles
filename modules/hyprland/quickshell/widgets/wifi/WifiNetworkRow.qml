import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui

Rectangle {
    id: root

    required property var network
    required property var service

    signal connectRequested(var network)

    width: ListView.view.width
    height: service.actionSsid === network.ssid ? 76 : 42
    radius: Ui.Theme.radiusMd
    color: networkMouse.containsMouse ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken

    Behavior on height {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }

    RowLayout {
        z: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        height: 42
        spacing: 8

        Ui.UiIcon {
            text: service.signalIcon(root.network.signal)
            color: Ui.Theme.textPrimary
            font.pixelSize: Ui.Theme.textXl
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Ui.UiText {
                Layout.fillWidth: true
                text: root.network.ssid
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Ui.UiText {
                Layout.fillWidth: true
                text: `${root.network.signal}% ${service.securityIcon(root.network.security)} ${root.network.remembered ? "remembered" : root.network.security}`
                color: Ui.Theme.textDisabled
                font.pixelSize: Ui.Theme.textXs
                elide: Text.ElideRight
            }
        }

        Ui.UiText {
            text: root.network.active ? "●" : ""
            color: Ui.Theme.accent
            font.pixelSize: Ui.Theme.textMd
        }

        WifiSmallButton {
            subtle: true
            label: "⋮"
            onClicked: service.toggleActions(root.network.ssid)
        }
    }

    RowLayout {
        z: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 42
        anchors.leftMargin: 38
        anchors.rightMargin: 8
        height: 30
        spacing: 8
        visible: service.actionSsid === root.network.ssid
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Item {
            Layout.fillWidth: true
        }

        WifiSmallButton {
            visible: !root.network.active
            label: "Connect"
            onClicked: {
                service.actionSsid = "";
                service.closePasswordPrompt();
                root.connectRequested(root.network);
            }
        }

        WifiSmallButton {
            visible: root.network.active
            label: "QR"
            onClicked: {
                service.closePasswordPrompt();
                service.showQrCode();
            }
        }

        WifiSmallButton {
            visible: root.network.active
            label: "Copy password"
            onClicked: {
                service.closePasswordPrompt();
                service.copyPassword();
            }
        }

        WifiSmallButton {
            visible: root.network.active
            label: "Disconnect"
            onClicked: {
                service.actionSsid = "";
                service.closePasswordPrompt();
                service.disconnect();
            }
        }

        WifiSmallButton {
            visible: root.network.remembered
            label: "Forget"
            onClicked: {
                service.actionSsid = "";
                service.closePasswordPrompt();
                service.forget(root.network.ssid);
            }
        }
    }

    MouseArea {
        id: networkMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            service.closePasswordPrompt();
            root.connectRequested(root.network);
        }
    }
}
