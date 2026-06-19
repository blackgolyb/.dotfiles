import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../ui" as Ui

Item {
    id: root

    property var anchorWindow: null

    readonly property var players: Mpris.players.values
    readonly property bool hasPlayers: players.length > 0
    readonly property var player: players.find(player => player.isPlaying) ?? players[0] ?? null
    readonly property string title: player != null && player.trackTitle.length > 0 ? player.trackTitle : "Unknown Title"
    readonly property string artist: player != null && player.trackArtist.length > 0 ? player.trackArtist : "Unknown Artist"
    readonly property string album: player != null && player.trackAlbum.length > 0 ? player.trackAlbum : "Unknown Album"
    readonly property string artUrl: player != null ? player.trackArtUrl : ""
    readonly property bool playing: player != null && player.isPlaying
    readonly property bool canSeek: player != null && player.canSeek && player.positionSupported
    readonly property real position: player != null ? player.position : 0
    readonly property real length: player != null ? player.length : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property string titleLine: `${title}  -  ${artist}`

    property bool widgetHovered: false
    property bool popupHovered: false
    property bool detailsOpen: false

    visible: hasPlayers
    implicitWidth: hasPlayers ? 280 : 0
    implicitHeight: 22

    function formatTime(seconds) {
        const safeSeconds = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(safeSeconds / 60);
        const rest = safeSeconds % 60;
        return `${minutes}:${rest.toString().padStart(2, "0")}`;
    }

    function seekAt(mouseX, width) {
        if (!root.canSeek || root.player == null || root.length <= 0)
            return;
        root.player.position = Math.max(0, Math.min(root.length, root.length * mouseX / width));
    }

    function toggleDetails(open) {
        closeTimer.stop();
        if (open) {
            detailsOpen = true;
        } else {
            closeTimer.start();
        }
    }

    Timer {
        id: closeTimer
        interval: 160
        repeat: false
        onTriggered: root.detailsOpen = root.widgetHovered || root.popupHovered
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player != null && root.playing
        onTriggered: root.player.positionChanged()
    }

    Rectangle {
        id: compactCard
        anchors.fill: parent
        radius: 8
        color: compactMouse.containsMouse || root.detailsOpen ? Ui.Theme.surfaceActive : Ui.Theme.transparent

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            radius: 1
            color: Ui.Theme.border

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: parent.radius
                color: root.playing ? Ui.Theme.accent : Ui.Theme.textDisabled

                Behavior on width {
                    NumberAnimation {
                        duration: 160
                    }
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 2
            spacing: 6

            Ui.UiIcon {
                text: root.playing ? "" : ""
                font.pixelSize: 12
            }

            Item {
                id: titleViewport

                readonly property int repeatGap: 36
                readonly property int marqueePixelsPerSecond: 12
                readonly property real cycleWidth: compactTitlePrimary.implicitWidth + repeatGap
                readonly property bool scrolling: compactTitlePrimary.implicitWidth > width

                Layout.fillWidth: true
                Layout.preferredHeight: 18
                clip: true

                Item {
                    id: titleTicker

                    x: 0
                    y: 1

                    Ui.UiText {
                        id: compactTitlePrimary
                        text: root.titleLine
                        font.pixelSize: 12
                    }

                    Ui.UiText {
                        x: titleViewport.cycleWidth
                        text: root.titleLine
                        visible: titleViewport.scrolling
                        font.pixelSize: 12
                    }

                    NumberAnimation on x {
                        from: 0
                        to: -titleViewport.cycleWidth
                        duration: titleViewport.cycleWidth / titleViewport.marqueePixelsPerSecond * 1000
                        easing.type: Easing.Linear
                        loops: Animation.Infinite
                        running: root.hasPlayers && titleViewport.scrolling
                        onRunningChanged: {
                            if (!running)
                                titleTicker.x = 0;
                        }
                    }
                }
            }
        }

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: {
                root.widgetHovered = true;
                root.toggleDetails(true);
            }
            onExited: {
                root.widgetHovered = false;
                root.toggleDetails(false);
            }
            onClicked: {
                if (root.player != null && root.player.canTogglePlaying)
                    root.player.togglePlaying();
            }
        }
    }

    PopupWindow {
        id: popup
        anchor.window: root.anchorWindow
        anchor.rect.x: root.anchorWindow != null ? Math.max(20, Math.round((root.anchorWindow.width - popup.implicitWidth) / 2)) : 0
        anchor.rect.y: root.anchorWindow != null ? root.anchorWindow.height + 8 : 0
        implicitWidth: 420
        implicitHeight: 156
        visible: root.detailsOpen && root.hasPlayers
        color: Ui.Theme.transparent

        Ui.UiCard {
            id: popupCard
            anchors.fill: parent

            HoverHandler {
                onHoveredChanged: {
                    root.popupHovered = hovered;
                    root.toggleDetails(hovered);
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 94
                    Layout.preferredHeight: 94
                    radius: 14
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
                            text: root.formatTime(root.position)
                            color: Ui.Theme.textDisabled
                            font.pixelSize: Ui.Theme.textXs
                        }

                        Rectangle {
                            id: popupProgress
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Ui.Theme.border

                            Rectangle {
                                width: parent.width * root.progress
                                height: parent.height
                                radius: parent.radius
                                color: root.canSeek ? Ui.Theme.accent : Ui.Theme.textDisabled
                            }

                            MouseArea {
                                id: progressMouse
                                anchors.fill: parent
                                enabled: root.canSeek
                                cursorShape: Qt.PointingHandCursor
                                onPressed: mouse => root.seekAt(mouse.x, popupProgress.width)
                                onPositionChanged: mouse => {
                                    if (progressMouse.pressed)
                                        root.seekAt(mouse.x, popupProgress.width);
                                }
                            }
                        }

                        Ui.UiText {
                            text: root.length > 0 ? root.formatTime(root.length) : "--:--"
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
                            radius: 9
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
                                onClicked: root.player.previous()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 32
                            radius: 11
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
                                onClicked: root.player.togglePlaying()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 28
                            radius: 9
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
                                onClicked: root.player.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
