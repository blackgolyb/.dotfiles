import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Src.Ui as Ui
import Src.Widgets as Widgets
import Src.Widgets.StatusLine as Status

Ui.UiPopup {
    id: root

    required property var status
    property bool hovered: false
    readonly property int slideDistance: 22

    anchor.rect.x: root.anchorWindow != null ? Math.max(20, Math.round((root.anchorWindow.width - root.implicitWidth) / 2)) : 0
    anchor.rect.y: root.anchorWindow != null ? root.anchorWindow.height : 0
    implicitWidth: 500
    implicitHeight: 390
    grabFocus: false

    function run(command): void {
        actionProcess.exec(["sh", "-c", command]);
    }

    function sliderValue(mouseX, width): real {
        return Math.max(0, Math.min(100, 100 * mouseX / width));
    }

    Process {
        id: actionProcess
    }

    Item {
        anchors.fill: parent
        clip: true

        Ui.UiCard {
        id: card
        border.width: 0

        width: parent.width
        height: parent.height
        y: root.visible ? 0 : -root.slideDistance
        opacity: root.visible ? 1 : 0

        HoverHandler {
            onHoveredChanged: root.hovered = hovered
        }

        Behavior on y {
            NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: card.radius + 1
            color: card.color
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

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
                    text: status.wifiService.activeSsid.length > 0 ? `󰤨 ${status.wifiService.activeSsid}` : "󰤭 Offline"
                    color: Ui.Theme.textMuted
                    font.pixelSize: Ui.Theme.textSm
                    elide: Text.ElideRight
                    Layout.preferredWidth: 170
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: status.music.hasPlayers ? 142 : 46
                radius: Ui.Theme.radiusMd
                color: status.music.hasPlayers ? Ui.Theme.transparent : Ui.Theme.surfaceSunken

                Widgets.MusicWidget {
                    anchors.fill: parent
                    anchorWindow: root.anchorWindow
                    enablePopup: false
                    visible: status.music.hasPlayers
                }

                RowLayout {
                    anchors.centerIn: parent
                    visible: !status.music.hasPlayers
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

                    Ui.UiIcon { text: status.volumeIcon(status.volume, status.muted); font.pixelSize: 18 }
                    Status.Progress {
                        id: volumeProgress
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                        progress: Math.min(1, status.volume / 100)
                        active: !status.muted
                        MouseArea {
                            id: volumeMouse
                            anchors.fill: parent
                            onPressed: mouse => status.setVolume(root.sliderValue(mouse.x, volumeProgress.width))
                            onPositionChanged: mouse => {
                                if (volumeMouse.pressed)
                                    status.setVolume(root.sliderValue(mouse.x, volumeProgress.width));
                            }
                        }
                    }
                    Ui.UiText { text: `${status.volume}%`; color: Ui.Theme.textMuted; font.pixelSize: Ui.Theme.textSm; Layout.preferredWidth: 42 }
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 26
                        radius: Ui.Theme.radiusSm
                        color: muteMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive
                        Ui.UiIcon { anchors.centerIn: parent; text: status.muted ? "󰝟" : "󰕾"; font.pixelSize: 14 }
                        MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: status.toggleMute() }
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
                        progress: status.brightness / 100
                        active: status.brightnessReady
                        MouseArea {
                            id: brightnessMouse
                            anchors.fill: parent
                            onPressed: mouse => status.setBrightness(root.sliderValue(mouse.x, brightnessProgress.width))
                            onPositionChanged: mouse => {
                                if (brightnessMouse.pressed)
                                    status.setBrightness(root.sliderValue(mouse.x, brightnessProgress.width));
                            }
                        }
                    }
                    Ui.UiText { text: `${status.brightness}%`; color: Ui.Theme.textMuted; font.pixelSize: Ui.Theme.textSm; Layout.preferredWidth: 42 }
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
                    color: status.wifiService.wifiEnabled ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Ui.UiIcon { text: status.wifiService.wifiEnabled ? "󰤨" : "󰤭"; font.pixelSize: 18 }
                        Ui.UiText { Layout.fillWidth: true; text: status.wifiService.activeSsid.length > 0 ? status.wifiService.activeSsid : status.wifiService.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"; elide: Text.ElideRight; font.pixelSize: Ui.Theme.textSm }
                        Ui.UiIcon { text: "󰐥"; font.pixelSize: 14 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: status.wifiService.toggleWifi() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Ui.Theme.radiusMd
                    color: status.bluetoothPowered ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Ui.UiIcon { text: "󰂯"; font.pixelSize: 18 }
                        Ui.UiText { Layout.fillWidth: true; text: status.bluetoothPowered ? "Bluetooth on" : status.bluetoothReady ? "Bluetooth off" : "Bluetooth unavailable"; elide: Text.ElideRight; font.pixelSize: Ui.Theme.textSm }
                        Ui.UiIcon { text: "󰐥"; font.pixelSize: 14 }
                    }
                    MouseArea { anchors.fill: parent; enabled: status.bluetoothReady; onClicked: status.toggleBluetooth() }
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
        }
    }
}
