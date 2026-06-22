import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Src.Ui as Ui

Ui.UiOverlay {
    id: root

    readonly property var actions: [
        {
            label: "Lock",
            icon: "",
            command: ["lock"]
        },
        {
            label: "Suspend",
            icon: "󰒲",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Logout",
            icon: "󰗽",
            hyprland: "exit"
        },
        {
            label: "Reboot",
            icon: "󰜉",
            command: ["systemctl", "reboot"]
        },
        {
            label: "Shutdown",
            icon: "⏻",
            command: ["systemctl", "poweroff"]
        },
    ]

    namespaceName: "power-menu"
    enableBlur: true
    exclusiveKeyboard: true
    focusableWindow: true
    overlay: true
    dimOpacity: 0.22
    screen: root.anchorWindow.screen
    onDismissed: root.visible = false
    visible: false

    onVisibleChanged: {
        if (visible)
            focusTrap.forceActiveFocus();
    }

    function runDetached(command) {
        detachedProcess.command = command;
        detachedProcess.startDetached();
    }

    function runPowerAction(action) {
        root.visible = false;
        if (action.hyprland !== undefined)
            Hyprland.dispatch(action.hyprland);
        else
            root.runDetached(action.command);
    }

    Process {
        id: detachedProcess
    }

    Item {
        id: focusTrap
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }

    Ui.UiCard {
        width: 420
        height: 132
        anchors.centerIn: parent

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Repeater {
                model: root.actions

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Ui.Theme.radiusMd
                    color: powerMouse.containsMouse ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runPowerAction(parent.modelData)
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Ui.UiIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.parent.modelData.icon
                            font.pixelSize: 22
                        }

                        Ui.UiText {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.parent.modelData.label
                            color: Ui.Theme.textSecondary
                            font.pixelSize: Ui.Theme.textSm
                        }
                    }
                }
            }
        }
    }
}
