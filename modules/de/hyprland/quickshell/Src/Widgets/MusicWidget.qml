import QtQuick
import QtQuick.Layouts
import Quickshell
import Src.Services as Services
import Src.Ui as Ui
import Src.Widgets.StatusLine as Status

Item {
    id: root

    property var anchorWindow: null
    property bool enablePopup: false
    readonly property var music: Services.MusicService
    readonly property bool hasPlayers: music.hasPlayers
    readonly property var player: music.player
    readonly property string title: music.title
    readonly property string artist: music.artist
    readonly property string album: music.album
    readonly property string artUrl: music.artUrl
    readonly property bool playing: music.playing
    readonly property bool canSeek: music.canSeek
    readonly property real position: music.position
    readonly property real length: music.length
    readonly property real progress: music.progress

    visible: hasPlayers
    implicitWidth: hasPlayers ? 420 : 0
    implicitHeight: hasPlayers ? 126 : 0

    Ui.UiCard {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 88
                Layout.preferredHeight: 88
                radius: 16
                color: Ui.Theme.surfaceSunken
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    visible: root.artUrl.length > 0
                    fillMode: Image.PreserveAspectCrop
                }

                Ui.UiIcon {
                    anchors.centerIn: parent
                    visible: root.artUrl.length === 0
                    text: "󰝚"
                    color: Ui.Theme.textDisabled
                    font.pixelSize: 34
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Ui.UiText {
                    Layout.fillWidth: true
                    text: root.title
                    color: Ui.Theme.textPrimary
                    font.pixelSize: Ui.Theme.textLg
                    font.bold: true
                    elide: Text.ElideRight
                }

                Ui.UiText {
                    Layout.fillWidth: true
                    text: `${root.artist}  -  ${root.album}`
                    color: Ui.Theme.textSecondary
                    font.pixelSize: Ui.Theme.textSm
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Ui.UiText {
                        text: root.music.formatTime(root.position)
                        color: Ui.Theme.textDisabled
                        font.pixelSize: Ui.Theme.textXs
                    }

                    Status.Progress {
                        id: musicProgress
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        progress: root.progress
                        active: root.canSeek

                        MouseArea {
                            id: progressMouse
                            anchors.fill: parent
                            enabled: root.canSeek
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => root.music.seekAt(mouse.x, musicProgress.width)
                            onPositionChanged: mouse => {
                                if (progressMouse.pressed)
                                    root.music.seekAt(mouse.x, musicProgress.width);
                            }
                        }
                    }

                    Ui.UiText {
                        text: root.length > 0 ? root.music.formatTime(root.length) : "--:--"
                        color: Ui.Theme.textDisabled
                        font.pixelSize: Ui.Theme.textXs
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 28
                        radius: Ui.Theme.radiusSm
                        opacity: root.player != null && root.player.canGoPrevious ? 1 : 0.35
                        color: previousMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive

                        Ui.UiIcon {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: previousMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.player != null && root.player.canGoPrevious
                            onClicked: root.music.previous()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 32
                        radius: Ui.Theme.radiusSm
                        opacity: root.player != null && root.player.canTogglePlaying ? 1 : 0.35
                        color: toggleMouse.containsMouse ? Ui.Theme.accent : Ui.Theme.primitive.frost3

                        Ui.UiIcon {
                            anchors.centerIn: parent
                            text: root.playing ? "" : ""
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: toggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.player != null && root.player.canTogglePlaying
                            onClicked: root.music.togglePlaying()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 28
                        radius: Ui.Theme.radiusSm
                        opacity: root.player != null && root.player.canGoNext ? 1 : 0.35
                        color: nextMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive

                        Ui.UiIcon {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.player != null && root.player.canGoNext
                            onClicked: root.music.next()
                        }
                    }
                }
            }
        }
    }
}
