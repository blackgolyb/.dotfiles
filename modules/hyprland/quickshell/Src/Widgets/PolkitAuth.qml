import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Quickshell.Widgets
import Src.Ui as Ui

PanelWindow {
    id: root

    required property var anchorWindow
    readonly property var flow: agent.flow

    screen: root.anchorWindow.screen
    visible: agent.isActive
    color: Ui.Theme.transparent
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-overlay-polkit-auth"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible) {
            passwordInput.text = "";
            passwordInput.forceInputFocus();
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

    Ui.UiOverlay {
        anchors.fill: parent
        dimOpacity: 0.34
        onDismissed: root.cancel()
    }

    Ui.UiCard {
        width: Math.min(root.width - 40, 480)
        implicitHeight: content.implicitHeight + 32
        anchors.centerIn: parent

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

                    Ui.UiText {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Ui.UiText {
                        Layout.fillWidth: true
                        text: root.flow !== null ? root.flow.actionId : ""
                        color: Ui.Theme.textMuted
                        elide: Text.ElideRight
                        font.pixelSize: Ui.Theme.textXs
                    }
                }
            }

            Ui.UiText {
                Layout.fillWidth: true
                text: root.flow !== null ? root.flow.message : ""
                color: Ui.Theme.textSecondary
                wrapMode: Text.WordWrap
                font.pixelSize: Ui.Theme.textMd
            }

            Ui.UiText {
                Layout.fillWidth: true
                text: root.flow !== null ? root.flow.supplementaryMessage : ""
                visible: text.length > 0
                color: root.flow !== null && root.flow.supplementaryIsError ? Ui.Theme.danger : Ui.Theme.textSubtle
                wrapMode: Text.WordWrap
                font.pixelSize: Ui.Theme.textSm
            }

            Ui.UiTextInput {
                id: passwordInput
                Layout.fillWidth: true
                implicitHeight: 42
                inputEnabled: root.flow !== null && root.flow.isResponseRequired
                echoMode: root.flow !== null && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                textPixelSize: Ui.Theme.textLg
                onEscaped: root.cancel()
                onAccepted: root.submit()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Ui.UiButton {
                    text: "Cancel"
                    textColor: Ui.Theme.textSecondary
                    onClicked: root.cancel()
                }

                Ui.UiButton {
                    text: "Authenticate"
                    implicitWidth: 112
                    normalColor: Ui.Theme.accent
                    hoverColor: Ui.Theme.accentHover
                    textColor: Ui.Theme.textInverse
                    onClicked: root.submit()
                }
            }
        }
    }
}
