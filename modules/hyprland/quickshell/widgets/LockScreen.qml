import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../ui" as Ui

Item {
    id: root

    property string password: ""
    property string statusText: ""
    property bool authenticating: false

    visible: false

    function open(): void {
        password = "";
        statusText = "";
        authenticating = false;
        sessionLock.locked = true;
    }

    function authenticate(passwordText): void {
        if (authenticating || passwordText.length === 0)
            return;

        password = passwordText;
        statusText = "Checking password...";
        authenticating = true;

        if (pam.active)
            pam.abort();
        if (!pam.start()) {
            authenticating = false;
            statusText = "Could not start authentication";
        }
    }

    function unlockSession(): void {
        password = "";
        statusText = "";
        authenticating = false;
        sessionLock.locked = false;
    }

    function fail(message): void {
        password = "";
        authenticating = false;
        statusText = message;
    }

    function runPower(command): void {
        Quickshell.execDetached(command);
    }

    IpcHandler {
        target: "lock"

        function open(): void {
            root.open();
        }
    }

    PamContext {
        id: pam
        config: "quickshell-lock"
        user: Quickshell.env("USER") ?? ""

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.password);
        }

        onCompleted: result => {
            if (result == PamResult.Success)
                root.unlockSession();
            else if (result == PamResult.MaxTries)
                root.fail("Too many attempts");
            else
                root.fail("Wrong password");
        }

        onError: error => root.fail(PamError.toString(error))
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            id: surface
            color: Ui.Theme.background

            readonly property var powerActions: [
                {
                    label: "Suspend",
                    icon: "󰒲",
                    command: ["systemctl", "suspend"]
                },
                {
                    label: "Reboot",
                    icon: "󰜉",
                    command: ["systemctl", "reboot"]
                },
                {
                    label: "Power off",
                    icon: "⏻",
                    command: ["systemctl", "poweroff"]
                },
            ]

            onVisibleChanged: {
                if (visible) {
                    passwordInput.text = "";
                    passwordInput.forceInputFocus();
                }
            }

            function submit(): void {
                root.authenticate(passwordInput.text);
                passwordInput.text = "";
            }

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
            }

            Image {
                anchors.fill: parent
                source: `file://${Quickshell.env("HOME")}/.config/hypr/wallpapers/9.png`
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                color: Ui.Theme.overlay
                opacity: 0.42
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Ui.Theme.transparent
                    }
                    GradientStop {
                        position: 1
                        color: Ui.Theme.background
                    }
                }
                opacity: 0.76
            }

            ColumnLayout {
                width: Math.min(surface.width - 48, 460)
                anchors.centerIn: parent
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Ui.UiText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "hh:mm")
                        color: Ui.Theme.textPrimary
                        font.pixelSize: 72
                        font.bold: true
                    }

                    Ui.UiText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "dddd, dd MMMM")
                        color: Ui.Theme.textSecondary
                        font.pixelSize: Ui.Theme.textLg
                    }
                }

                Ui.UiCard {
                    Layout.fillWidth: true
                    implicitHeight: unlockContent.implicitHeight + 32

                    ColumnLayout {
                        id: unlockContent
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Ui.UiText {
                            Layout.fillWidth: true
                            text: Quickshell.env("USER") ?? ""
                            color: Ui.Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Ui.Theme.textLg
                            font.bold: true
                        }

                        Ui.UiTextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            implicitHeight: 44
                            inputEnabled: !root.authenticating
                            echoMode: TextInput.Password
                            placeholderText: "Password"
                            textPixelSize: Ui.Theme.textLg
                            onAccepted: surface.submit()
                        }

                        Ui.UiText {
                            Layout.fillWidth: true
                            text: root.statusText
                            visible: text.length > 0
                            color: root.authenticating ? Ui.Theme.textSubtle : Ui.Theme.danger
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Ui.Theme.textSm
                        }

                        Ui.UiButton {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.authenticating ? "Checking..." : "Login"
                            implicitWidth: 140
                            normalColor: Ui.Theme.accent
                            hoverColor: Ui.Theme.accentHover
                            textColor: Ui.Theme.textInverse
                            onClicked: surface.submit()
                        }
                    }
                }
            }

            RowLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                spacing: 10

                Repeater {
                    model: surface.powerActions

                    Ui.UiButton {
                        required property var modelData

                        text: `${modelData.icon} ${modelData.label}`
                        implicitWidth: 124
                        normalColor: Ui.Theme.surfaceSunken
                        hoverColor: Ui.Theme.surfaceActive
                        textColor: Ui.Theme.textSecondary
                        onClicked: root.runPower(modelData.command)
                    }
                }
            }
        }
    }
}
