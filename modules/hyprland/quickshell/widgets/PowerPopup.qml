import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    readonly property var actions: [
        {
            label: "Lock",
            icon: "",
            command: ["swaylock", "-f"]
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
    color: "transparent"
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

    Rectangle {
        id: dimLayer
        anchors.fill: parent
        color: "#000000"
        opacity: 0.22

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    Rectangle {
        width: 420
        height: 132
        anchors.centerIn: parent
        radius: 16
        color: "#2e3440"
        border.width: 1
        border.color: "#4c566a"

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
                    radius: 10
                    color: powerMouse.containsMouse ? "#3b4252" : "#252b35"

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.runPowerAction(parent.modelData)
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.parent.modelData.icon
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 22
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.parent.modelData.label
                            color: "#c3c3c3"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
