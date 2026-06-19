import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../ui" as Ui

PanelWindow {
    id: root

    required property var anchorWindow
    readonly property var actions: [
        {
            label: "Lock",
            icon: "",
            command: ["qs", "ipc", "call", "lock", "open"]
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

    screen: root.anchorWindow.screen
    visible: false
    color: Ui.Theme.transparent
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-overlay-power-menu"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

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

    Ui.UiOverlay {
        anchors.fill: parent
        dimOpacity: 0.22
        onDismissed: root.visible = false
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
