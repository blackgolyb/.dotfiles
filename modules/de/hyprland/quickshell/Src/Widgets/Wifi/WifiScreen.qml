import QtQuick
import QtQuick.Layouts
import Src.Ui as Ui

Item {
    id: root

    required property var service
    property var view: null
    property int margins: 16
    property int qrSize: 96

    function focusSearch(): void {
        searchInput.forceInputFocus();
    }

    function connectOrPrompt(network): void {
        if (network.active)
            return;
        if (network.remembered || network.security.length === 0 || network.security === "--") {
            service.connect(network.ssid, "");
        } else {
            service.showPasswordPrompt(network.ssid);
            passwordInput.forceInputFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.service.closePasswordPrompt()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.margins
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Ui.UiNavigateBack {
                view: root.view
            }

            Ui.UiText {
                text: root.service.wifiEnabled ? "Wi-Fi" : "Wi-Fi Off"
                color: Ui.Theme.textPrimary
                font.pixelSize: Ui.Theme.textLg
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 28
                radius: Ui.Theme.radiusSm
                visible: root.service.wifiEnabled
                color: refreshMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive

                Ui.UiIcon {
                    anchors.centerIn: parent
                    text: "󰑓"
                    font.pixelSize: 15
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.service.closePasswordPrompt();
                        root.service.refresh(true);
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 28
                radius: 14
                color: root.service.wifiEnabled ? Ui.Theme.accent : Ui.Theme.border

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    y: 3
                    x: root.service.wifiEnabled ? parent.width - width - 3 : 3
                    color: Ui.Theme.textPrimary

                    Behavior on x {
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.service.closePasswordPrompt();
                        root.service.toggleWifi();
                    }
                }
            }
        }

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.qrSize
            Layout.preferredHeight: root.qrSize
            visible: root.service.qrVersion > 0
            cache: false
            source: root.service.qrVersion > 0 ? `file://${root.service.qrPath}?v=${root.service.qrVersion}` : ""
            fillMode: Image.PreserveAspectFit
        }

        Ui.UiTextInput {
            id: searchInput
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            text: root.service.searchText
            placeholderText: "Search networks"
            textPixelSize: Ui.Theme.textSm
            selectionTextColor: Ui.Theme.textPrimary
            onInputActiveFocusChanged: {
                if (inputActiveFocus)
                    root.service.closePasswordPrompt();
            }
            onTextChanged: root.service.searchText = text
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Ui.Theme.radiusSm
            color: Ui.Theme.surfaceSunken
            visible: root.service.selectedSsid.length > 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 7
                spacing: 8

                Ui.UiText {
                    text: root.service.selectedSsid
                    color: Ui.Theme.textPrimary
                    font.pixelSize: Ui.Theme.textMd
                    elide: Text.ElideRight
                    Layout.preferredWidth: 110
                }

                Ui.UiTextInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    text: root.service.selectedPassword
                    echoMode: TextInput.Password
                    implicitHeight: 28
                    textPixelSize: Ui.Theme.textMd
                    selectionTextColor: Ui.Theme.textPrimary
                    onTextChanged: root.service.selectedPassword = text
                    onAccepted: root.service.connect(root.service.selectedSsid, root.service.selectedPassword)
                    onEscaped: root.service.closePasswordPrompt()
                }

                WifiSmallButton {
                    label: "Connect"
                    onClicked: root.service.connect(root.service.selectedSsid, root.service.selectedPassword)
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.service.filteredNetworks

            delegate: WifiNetworkRow {
                required property var modelData

                network: modelData
                service: root.service
                onConnectRequested: network => root.connectOrPrompt(network)
            }
        }

        Ui.UiText {
            Layout.fillWidth: true
            text: root.service.statusText
            color: Ui.Theme.textDisabled
            font.pixelSize: Ui.Theme.textSm
            elide: Text.ElideRight
        }
    }
}
