import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var anchorWindow
    readonly property var flow: agent.flow

    screen: root.anchorWindow.screen
    visible: agent.isActive
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-polkit-auth"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible) {
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
        }
    }

    function cancel(): void {
        if (root.flow !== null)
            root.flow.cancelAuthenticationRequest();
    }

    function submit(): void {
        if (root.flow !== null && root.flow.isResponseRequired)
            root.flow.submit(passwordInput.text);
    }

    PolkitAgent {
        id: agent
        path: "/org/quickshell/Polkit"
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.34

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }
    }

    Rectangle {
        width: Math.min(root.width - 40, 480)
        implicitHeight: content.implicitHeight + 32
        anchors.centerIn: parent
        radius: 18
        color: "#2e3440"
        border.width: 1
        border.color: "#4c566a"

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                IconImage {
                    implicitSize: 36
                    source: root.flow !== null && root.flow.iconName.length > 0 ? Quickshell.iconPath(root.flow.iconName, "dialog-password") : Quickshell.iconPath("dialog-password")
                    asynchronous: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        color: "#eceff4"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.flow !== null ? root.flow.actionId : ""
                        color: "#7f889b"
                        elide: Text.ElideRight
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.flow !== null ? root.flow.message : ""
                color: "#d8dee9"
                wrapMode: Text.WordWrap
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 12
            }

            Text {
                Layout.fillWidth: true
                text: root.flow !== null ? root.flow.supplementaryMessage : ""
                visible: text.length > 0
                color: root.flow !== null && root.flow.supplementaryIsError ? "#bf616a" : "#a9b1c1"
                wrapMode: Text.WordWrap
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 11
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 10
                color: "#252b35"
                border.width: passwordInput.activeFocus ? 1 : 0
                border.color: "#88c0d0"

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    enabled: root.flow !== null && root.flow.isResponseRequired
                    echoMode: root.flow !== null && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "*"
                    color: "#eceff4"
                    selectedTextColor: "#2e3440"
                    selectionColor: "#88c0d0"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 14
                    Keys.onEscapePressed: root.cancel()
                    Keys.onReturnPressed: root.submit()
                    Keys.onEnterPressed: root.submit()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 96
                    implicitHeight: 34
                    radius: 9
                    color: cancelMouse.containsMouse ? "#3b4252" : "#252b35"

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.cancel()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#d8dee9"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    implicitWidth: 112
                    implicitHeight: 34
                    radius: 9
                    color: authMouse.containsMouse ? "#8fbcbb" : "#88c0d0"

                    MouseArea {
                        id: authMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.submit()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Authenticate"
                        color: "#2e3440"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }
}
