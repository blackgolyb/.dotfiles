import QtQuick
import QtQuick.Layouts
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
            searchInput.forceInputFocus();
    }

    function connectOrPrompt(network): void {
        if (network.active)
            return;
        if (network.remembered || network.security.length === 0 || network.security === "--") {
            service.connect(network.ssid, "");
        } else {
            service.showPasswordPrompt(network.ssid);
            passwordPrompt.forceInputFocus();
        }
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
            NumberAnimation {
                duration: 120
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.service.closePasswordPrompt()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Ui.UiText {
                    text: root.service.wifiEnabled ? "Wi-Fi" : "Wi-Fi Off"
                    font.pixelSize: 17
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 26
                    radius: Ui.Theme.radiusSm
                    visible: root.service.wifiEnabled
                    color: refreshMouse.containsMouse ? Ui.Theme.primitive.polarNight2 : Ui.Theme.surfaceActive

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
                    Layout.preferredHeight: 26
                    radius: 13
                    color: root.service.wifiEnabled ? Ui.Theme.accent : Ui.Theme.border

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        y: 3
                        x: root.service.wifiEnabled ? parent.width - width - 3 : 3
                        color: Ui.Theme.textPrimary

                        Behavior on x {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
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
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
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
                textPixelSize: 13
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
                        id: passwordPrompt
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
}
