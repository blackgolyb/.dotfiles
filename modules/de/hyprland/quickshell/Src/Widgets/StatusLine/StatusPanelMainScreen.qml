import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Src.Ui as Ui
import Src.Widgets as Widgets
import Src.Widgets.StatusLine as Status

ColumnLayout {
    id: root

    required property var status
    required property var anchorWindow
    signal wifiRequested

    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    function run(command): void {
        actionProcess.exec(["sh", "-c", command]);
    }

    function sliderValue(mouseX, width): real {
        return Math.max(0, Math.min(100, 100 * mouseX / width));
    }

    Process {
        id: actionProcess
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Ui.UiText {
            text: "Control center"
            color: Ui.Theme.textPrimary
            font.pixelSize: Ui.Theme.textLg
            font.bold: true
            Layout.fillWidth: true
        }

        Ui.UiText {
            text: root.status.wifiService.activeSsid.length > 0 ? `󰤨 ${root.status.wifiService.activeSsid}` : "󰤭 Offline"
            color: Ui.Theme.textMuted
            font.pixelSize: Ui.Theme.textSm
            elide: Text.ElideRight
            Layout.preferredWidth: 170
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.status.music.hasPlayers ? 142 : 46
        radius: Ui.Theme.radiusMd
        color: root.status.music.hasPlayers ? Ui.Theme.transparent : Ui.Theme.surfaceSunken

        Widgets.MusicWidget {
            anchors.fill: parent
            anchorWindow: root.anchorWindow
            enablePopup: false
            visible: root.status.music.hasPlayers
        }

        RowLayout {
            anchors.centerIn: parent
            visible: !root.status.music.hasPlayers
            spacing: 8

            Ui.UiIcon {
                text: "󰝚"
                color: Ui.Theme.textDisabled
                font.pixelSize: 16
            }

            Ui.UiText {
                text: "No active player"
                color: Ui.Theme.textDisabled
                font.pixelSize: Ui.Theme.textMd
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Ui.UiIcon { text: root.status.volumeIcon(root.status.volume, root.status.muted); font.pixelSize: 18 }
            Status.Progress {
                id: volumeProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                progress: Math.min(1, root.status.volume / 100)
                active: !root.status.muted
                MouseArea {
                    id: volumeMouse
                    anchors.fill: parent
                    onPressed: mouse => root.status.setVolume(root.sliderValue(mouse.x, volumeProgress.width))
                    onPositionChanged: mouse => {
                        if (volumeMouse.pressed)
                            root.status.setVolume(root.sliderValue(mouse.x, volumeProgress.width));
                    }
                }
            }
            Ui.UiText { text: `${root.status.volume}%`; color: Ui.Theme.textMuted; font.pixelSize: Ui.Theme.textSm; Layout.preferredWidth: 42 }
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 26
                radius: Ui.Theme.radiusSm
                color: muteMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive
                Ui.UiIcon { anchors.centerIn: parent; text: root.status.muted ? "󰝟" : "󰕾"; font.pixelSize: 14 }
                MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.status.toggleMute() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Ui.UiIcon { text: "󰃠"; font.pixelSize: 18 }
            Status.Progress {
                id: brightnessProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                progress: root.status.brightness / 100
                active: root.status.brightnessReady
                MouseArea {
                    id: brightnessMouse
                    anchors.fill: parent
                    onPressed: mouse => root.status.setBrightness(root.sliderValue(mouse.x, brightnessProgress.width))
                    onPositionChanged: mouse => {
                        if (brightnessMouse.pressed)
                            root.status.setBrightness(root.sliderValue(mouse.x, brightnessProgress.width));
                    }
                }
            }
            Ui.UiText { text: `${root.status.brightness}%`; color: Ui.Theme.textMuted; font.pixelSize: Ui.Theme.textSm; Layout.preferredWidth: 42 }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 10
        rowSpacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: Ui.Theme.radiusMd
            color: root.status.wifiService.wifiEnabled ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                Ui.UiIcon { text: root.status.wifiService.wifiEnabled ? "󰤨" : "󰤭"; font.pixelSize: 18 }
                Ui.UiText { Layout.fillWidth: true; text: root.status.wifiService.activeSsid.length > 0 ? root.status.wifiService.activeSsid : root.status.wifiService.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"; elide: Text.ElideRight; font.pixelSize: Ui.Theme.textSm }
                Ui.UiIcon { text: "󰐥"; font.pixelSize: 14 }
            }
            MouseArea { anchors.fill: parent; onClicked: root.wifiRequested() }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: Ui.Theme.radiusMd
            color: root.status.bluetoothPowered ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                Ui.UiIcon { text: "󰂯"; font.pixelSize: 18 }
                Ui.UiText { Layout.fillWidth: true; text: root.status.bluetoothPowered ? "Bluetooth on" : root.status.bluetoothReady ? "Bluetooth off" : "Bluetooth unavailable"; elide: Text.ElideRight; font.pixelSize: Ui.Theme.textSm }
                Ui.UiIcon { text: "󰐥"; font.pixelSize: 14 }
            }
            MouseArea { anchors.fill: parent; enabled: root.status.bluetoothReady; onClicked: root.status.toggleBluetooth() }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: [
                { label: "Lock", command: "lock" },
                { label: "Suspend", command: "systemctl suspend" },
                { label: "Power", command: "systemctl poweroff" }
            ]

            Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: Ui.Theme.radiusSm
                color: utilityMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive

                Ui.UiText {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: Ui.Theme.textSm
                }

                MouseArea {
                    id: utilityMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(modelData.command)
                }
            }
        }
    }
}
