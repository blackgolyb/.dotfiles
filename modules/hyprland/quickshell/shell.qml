import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets

ShellRoot {
    id: root

    readonly property var groups: [
        { key: "f", label: "󰈹", description: "f" },
        { key: "d", label: "", description: "d" },
        { key: "s", label: "", description: "s" },
        { key: "a", label: "", description: "a" },
        { key: "v", label: "󱞁", description: "v" },
        { key: "c", label: "", description: "c" },
        { key: "x", label: "󰋋", description: "x" },
        { key: "z", label: "", description: "z" },
    ]
    readonly property var activeGroups: root.groups.map(group => {
        const workspace = root.workspaceFor(group.key);
        return {
            key: group.key,
            label: group.label,
            description: group.description,
            workspace: workspace,
        };
    }).filter(group => group.workspace != null && group.workspace.toplevels.values.length > 0)

    property string volumeText: "󰕾 0"
    property string layoutText: "us"
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: root.batteryDevice != null && root.batteryDevice.ready && root.batteryDevice.isPresent
    readonly property string batteryIconName: root.batteryReady ? root.batteryIconNameFor(Math.round(root.batteryDevice.percentage), root.batteryDevice.state) : "battery-missing"
    readonly property string batteryPercent: root.batteryReady ? `${Math.round(root.batteryDevice.percentage)}%` : ""

    function workspaceActive(key) {
        return Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.name === key;
    }

    function workspaceFor(key) {
        for (const workspace of Hyprland.workspaces.values) {
            if (workspace.name === key)
                return workspace;
        }
        return null;
    }

    function volumeIcon(volume, muted) {
        if (muted || volume === 0)
            return "󰝟";
        if (volume <= 33)
            return "";
        if (volume <= 66)
            return "󰖀";
        return "󰕾";
    }

    function batteryIconNameFor(percent, state) {
        const charging = state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge;

        if (charging && percent >= 95)
            return "battery-full-charging";
        if (state === UPowerDeviceState.FullyCharged || percent >= 95)
            return "battery-full";
        if (charging && percent >= 60)
            return "battery-good-charging";
        if (charging && percent >= 25)
            return "battery-low-charging";
        if (charging)
            return "battery-caution-charging";
        if (percent >= 60)
            return "battery-good";
        if (percent >= 25)
            return "battery-low";
        return "battery-caution";
    }

    function updateVolume() {
        volumeProcess.exec(["sh", "-c", "printf '%s %s' \"$(pamixer --get-volume 2>/dev/null || printf 0)\" \"$(pamixer --get-mute 2>/dev/null || printf false)\""]);
    }

    function updateLayout() {
        layoutProcess.exec(["sh", "-c", "hyprctl devices -j | jq -r 'first(.keyboards[]? | select(.main == true) | .active_keymap) // \"\" | ascii_downcase | if test(\"english\") then \"us\" elif test(\"ukrainian\") then \"ua\" else . end'"]);
    }

    function runDetached(command) {
        detachedProcess.command = command;
        detachedProcess.startDetached();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: volumeProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                const volume = parseInt(parts[0] || "0");
                const muted = (parts[1] || "false") === "true";
                root.volumeText = `${root.volumeIcon(volume, muted)} ${volume}`;
            }
        }
    }

    Process {
        id: layoutProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const layout = text.trim();
                if (layout.length > 0)
                    root.layoutText = layout;
            }
        }
    }

    Process {
        id: detachedProcess
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updateVolume();
            root.updateLayout();
        }
    }

    PanelWindow {
        id: bar
        implicitHeight: 30
        color: "#2e3440"
        exclusiveZone: implicitHeight

        anchors {
            top: true
            left: true
            right: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8

            RowLayout {
                spacing: 0

                Repeater {
                    model: root.activeGroups

                    Rectangle {
                        required property var modelData

                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 24
                        radius: 0
                        color: "transparent"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.modelData.workspace.activate()
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label + "<sup> " + parent.modelData.description + "</sup>"
                            textFormat: Text.RichText
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 16
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 18
                            height: 2
                            radius: 1
                            color: "#ffffff"
                            visible: root.workspaceActive(parent.modelData.key)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.volumeText
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 16

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse.button === Qt.RightButton ? root.runDetached(["pavucontrol"]) : root.runDetached(["sh", "-c", "$HOME/.config/hypr/scripts/volume_control mute"])
                    onWheel: wheel.angleDelta.y > 0 ? root.runDetached(["sh", "-c", "$HOME/.config/hypr/scripts/volume_control up"]) : root.runDetached(["sh", "-c", "$HOME/.config/hypr/scripts/volume_control down"])
                }
            }

            Text {
                text: root.layoutText
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 16
            }

            RowLayout {
                spacing: 4

                IconImage {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    source: Quickshell.iconPath(root.batteryIconName)
                }

                Text {
                    text: root.batteryPercent
                    color: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                }
            }

            Text {
                id: clockText
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 16

                MouseArea {
                    anchors.fill: parent
                    onClicked: calendar.visible = !calendar.visible
                }
            }
        }

        PopupWindow {
            id: calendar
            anchor.window: bar
            anchor.rect.x: bar.width - width - 20
            anchor.rect.y: bar.height
            width: 260
            height: 96
            visible: false
            color: "#2e3440"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dd MMMM yyyy")
                    color: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd")
                    color: "#c3c3c3"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 14
                }
            }
        }
    }
}
