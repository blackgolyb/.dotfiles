import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Item {
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

    implicitWidth: powerText.implicitWidth
    implicitHeight: powerText.implicitHeight

    function runDetached(command) {
        detachedProcess.command = command;
        detachedProcess.startDetached();
    }

    function runPowerAction(action) {
        powerPopup.visible = false;
        if (action.hyprland !== undefined)
            Hyprland.dispatch(action.hyprland);
        else
            root.runDetached(action.command);
    }

    Process {
        id: detachedProcess
    }

    Text {
        id: powerText
        text: "⏻"
        color: powerPopup.visible ? "#ffffff" : "#c3c3c3"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 17
    }

    MouseArea {
        anchors.fill: parent
        onClicked: powerPopup.visible = !powerPopup.visible
    }

    PowerPopup {
        id: powerPopup
        actions: root.actions
        anchorWindow: root.anchorWindow
        onActionTriggered: action => root.runPowerAction(action)
    }
}
