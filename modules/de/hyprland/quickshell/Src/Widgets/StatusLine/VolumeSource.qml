import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property string mode: "volume"
    readonly property bool available: showing
    readonly property real progress: Math.min(1, volume / 100)
    readonly property bool active: !muted
    readonly property string icon: volumeIcon(volume, muted)
    readonly property string text: `${volume}%`

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audio: root.audioSink != null ? root.audioSink.audio : null
    readonly property bool ready: Pipewire.ready && root.audioSink != null && root.audioSink.ready && root.audio != null
    readonly property int volume: root.ready ? Math.round(root.audio.volume * 100) : 0
    readonly property bool muted: root.ready ? root.audio.muted : false

    property bool showing: false
    property int lastVolume: -1
    property bool lastMuted: false

    visible: false

    onVolumeChanged: {
        if (!ready)
            return;
        if (lastVolume >= 0 && lastVolume !== volume)
            showTransient();
        lastVolume = volume;
    }

    onMutedChanged: {
        if (!ready)
            return;
        if (lastVolume >= 0 && lastMuted !== muted)
            showTransient();
        lastMuted = muted;
    }

    function showTransient(): void {
        showing = true;
        transientTimer.restart();
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
        if (ready)
            audio.volume = Math.max(0, Math.min(1.5, value / 100));
    }

    function toggleMute(): void {
        if (ready)
            audio.muted = !audio.muted;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Timer {
        id: transientTimer
        interval: 1400
        repeat: false
        onTriggered: root.showing = false
    }
}
