import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import Src.Services as Services
import Src.Ui as Ui
import Src.Widgets as Widgets
import Src.Widgets.StatusLine as Status

Item {
    id: root

    required property var anchorWindow
    property alias wifiService: wifiService

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audio: root.audioSink != null ? root.audioSink.audio : null
    readonly property bool audioReady: Pipewire.ready && root.audioSink != null && root.audioSink.ready && root.audio != null
    readonly property int volume: root.audioReady ? Math.round(root.audio.volume * 100) : 0
    readonly property bool muted: root.audioReady ? root.audio.muted : false

    readonly property var music: Services.MusicService
    readonly property bool hasPlayers: music.hasPlayers
    readonly property bool playing: music.playing
    readonly property real musicProgress: music.progress

    readonly property string effectiveMode: transientMode.length > 0 ? transientMode : hasPlayers ? "music" : "passive"
    readonly property real effectiveProgress: effectiveMode === "volume" ? Math.min(1, volume / 100) : effectiveMode === "brightness" ? brightness / 100 : effectiveMode === "music" ? musicProgress : 0
    readonly property bool effectiveActive: effectiveMode === "music" ? playing : effectiveMode !== "passive"
    readonly property string effectiveIcon: effectiveMode === "volume" ? volumeIcon(volume, muted) : effectiveMode === "brightness" ? "󰃠" : effectiveMode === "music" ? playing ? "" : "" : ""
    readonly property string effectiveText: effectiveMode === "volume" ? `${volume}%` : effectiveMode === "brightness" ? `${brightness}%` : effectiveMode === "music" ? music.titleLine : ""

    property int brightness: 0
    property bool brightnessReady: false
    property bool bluetoothPowered: false
    property bool bluetoothReady: false
    property string transientMode: ""
    property bool widgetHovered: false
    property bool panelHovered: false
    property bool panelOpen: false
    property int lastVolume: -1
    property bool lastMuted: false

    implicitWidth: 300
    implicitHeight: 24

    onVolumeChanged: {
        if (!audioReady)
            return;
        if (lastVolume >= 0 && lastVolume !== volume)
            showTransient("volume");
        lastVolume = volume;
    }

    onMutedChanged: {
        if (!audioReady)
            return;
        if (lastVolume >= 0 && lastMuted !== muted)
            showTransient("volume");
        lastMuted = muted;
    }

    function showTransient(mode: string): void {
        transientMode = mode;
        transientTimer.restart();
    }

    function openPanel(): void {
        closeTimer.stop();
        panelOpen = true;
        wifiService.refresh(false);
        refreshBrightness();
        refreshBluetooth();
    }

    function scheduleClose(): void {
        closeTimer.restart();
    }

    function volumeIcon(volume, muted): string {
        if (muted || volume === 0)
            return "󰝟";
        if (volume <= 33)
            return "";
        if (volume <= 66)
            return "󰖀";
        return "󰕾";
    }

    function setVolume(value: real): void {
        if (audioReady)
            audio.volume = Math.max(0, Math.min(1.5, value / 100));
    }

    function toggleMute(): void {
        if (audioReady)
            audio.muted = !audio.muted;
    }

    function setBrightness(value: real): void {
        const next = Math.round(Math.max(1, Math.min(100, value)));
        brightnessWriteProcess.exec(["brightnessctl", "set", `${next}%`]);
    }

    function refreshBrightness(): void {
        brightnessReadProcess.exec(["brightnessctl", "-m"]);
    }

    function refreshBluetooth(): void {
        bluetoothReadProcess.exec(["bluetoothctl", "show"]);
    }

    function toggleBluetooth(): void {
        bluetoothCommandProcess.exec(["bluetoothctl", "power", bluetoothPowered ? "off" : "on"]);
    }

    Component.onCompleted: {
        refreshBrightness();
        refreshBluetooth();
        wifiService.refresh(false);
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Widgets.WifiService {
        id: wifiService
    }

    Timer {
        id: transientTimer
        interval: 1400
        repeat: false
        onTriggered: root.transientMode = ""
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: root.panelOpen = root.widgetHovered || root.panelHovered
    }

    Timer {
        interval: 1200
        repeat: true
        running: true
        onTriggered: root.refreshBrightness()
    }

    Timer {
        interval: 6000
        repeat: true
        running: true
        onTriggered: root.refreshBluetooth()
    }

    Process {
        id: brightnessReadProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                const rawPercent = Number((parts[4] ?? "0%").replace("%", ""));
                if (Number.isNaN(rawPercent))
                    return;

                const percent = Math.round(Math.max(0, Math.min(100, rawPercent)));
                if (root.brightnessReady && root.brightness !== percent)
                    root.showTransient("brightness");
                root.brightness = percent;
                root.brightnessReady = true;
            }
        }
    }

    Process {
        id: brightnessWriteProcess
        onExited: root.refreshBrightness()
    }

    Process {
        id: bluetoothReadProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothPowered = text.includes("Powered: yes");
                root.bluetoothReady = text.length > 0;
            }
        }
    }

    Process {
        id: bluetoothCommandProcess
        onExited: root.refreshBluetooth()
    }

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: compactMouse.containsMouse || root.panelOpen ? Ui.Theme.surfaceActive : Ui.Theme.transparent

        Status.StatusLine {
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
            onClicked: root.hasPlayers ? root.music.togglePlaying() : root.openPanel()
            onWheel: root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? 5 : -5))
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
