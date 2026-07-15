import QtQuick
import QtQuick.Layouts
import Src.Ui as Ui
import Src.Widgets.StatusLine as Status

Item {
    id: root

    required property var anchorWindow

    readonly property var sources: [volumeSource, brightnessSource, musicSource, passiveSource]
    readonly property var currentSource: sourceForDisplay(sourceRevision)

    readonly property var music: musicSource.music
    readonly property bool hasPlayers: musicSource.hasPlayers
    readonly property var volumeControl: volumeSource
    readonly property var brightnessControl: brightnessSource
    readonly property int volume: volumeSource.volume
    readonly property bool muted: volumeSource.muted
    readonly property bool audioReady: volumeSource.ready
    readonly property int brightness: brightnessSource.percent
    readonly property bool brightnessReady: brightnessSource.ready

    readonly property string effectiveMode: currentSource.mode
    readonly property real effectiveProgress: currentSource.progress
    readonly property bool effectiveActive: currentSource.active
    readonly property string effectiveIcon: currentSource.icon
    readonly property string effectiveText: currentSource.text

    property bool widgetHovered: false
    property bool panelHovered: false
    property bool panelOpen: false
    property int sourceRevision: 0

    implicitWidth: 300
    implicitHeight: 24

    function sourceForDisplay(revision = 0): var {
        const orderedSources = sources;
        for (const source of orderedSources) {
            if (source.available)
                return source;
        }
        return passiveSource;
    }

    function updateCurrentSource(): void {
        sourceRevision += 1;
    }

    function openPanel(): void {
        closeTimer.stop();
        panelOpen = true;
    }

    function scheduleClose(): void {
        closeTimer.restart();
    }

    function handleClick(): void {
        if (root.hasPlayers) {
            root.music.togglePlaying();
        }
    }

    function handleWheel(wheel): void {
        const deltaChange = wheel.angleDelta.y > 0 ? 5 : -5;
        root.volumeControl.setVolume(root.volume + deltaChange);
    }

    Status.VolumeSource {
        id: volumeSource
    }

    Status.BrightnessSource {
        id: brightnessSource
    }

    Status.MusicSource {
        id: musicSource
    }

    Status.PassiveSource {
        id: passiveSource
    }

    Connections {
        target: volumeSource
        function onAvailableChanged(): void {
            root.updateCurrentSource();
        }
    }

    Connections {
        target: brightnessSource
        function onAvailableChanged(): void {
            root.updateCurrentSource();
        }
    }

    Connections {
        target: musicSource
        function onAvailableChanged(): void {
            root.updateCurrentSource();
        }
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: root.panelOpen = root.widgetHovered || root.panelHovered
    }

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: compactMouse.containsMouse || root.panelOpen ? Ui.Theme.surfaceActive : Ui.Theme.transparent

        Ui.StatusLine {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.effectiveMode === "passive" ? 2 : 3
            mode: root.effectiveMode === "passive" ? "passive" : "progress"
            progress: root.effectiveProgress
            active: root.effectiveActive
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 3
            spacing: 7
            visible: root.effectiveMode !== "passive"

            Ui.UiIcon {
                text: root.effectiveIcon
                color: root.effectiveActive ? Ui.Theme.textPrimary : Ui.Theme.textDisabled
                font.pixelSize: 12
            }

            Ui.UiText {
                Layout.fillWidth: true
                text: root.effectiveText
                color: root.effectiveActive ? Ui.Theme.textPrimary : Ui.Theme.textDisabled
                font.pixelSize: Ui.Theme.textSm
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                root.widgetHovered = true;
                root.openPanel();
            }
            onExited: {
                root.widgetHovered = false;
                root.scheduleClose();
            }
            onClicked: root.handleClick()
            onWheel: root.handleWheel(wheel)
        }
    }

    StatusPanel {
        id: panel
        anchorWindow: root.anchorWindow
        status: root
        visible: root.panelOpen
        onHoveredChanged: {
            root.panelHovered = hovered;
            if (!hovered)
                root.scheduleClose();
        }
    }
}
