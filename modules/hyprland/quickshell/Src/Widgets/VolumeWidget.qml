import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import Src.Ui as Ui

Ui.UiText {
    id: root

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audio: root.audioSink != null ? root.audioSink.audio : null
    readonly property bool audioReady: Pipewire.ready && root.audioSink != null && root.audioSink.ready && root.audio != null
    readonly property int volume: root.audioReady ? Math.round(root.audio.volume * 100) : 0
    readonly property bool muted: root.audioReady ? root.audio.muted : false
    readonly property string volumeText: `${root.volumeIcon(root.volume, root.muted)} ${root.volume}`

    text: root.volumeText
    color: Ui.Theme.textPrimary
    font.pixelSize: Ui.Theme.textXl

    function volumeIcon(volume, muted) {
        if (muted || volume === 0)
            return "󰝟";
        if (volume <= 33)
            return "";
        if (volume <= 66)
            return "󰖀";
        return "󰕾";
    }

    function setVolume(volume) {
        if (root.audioReady)
            root.audio.volume = Math.max(0, Math.min(1.5, volume / 100));
    }

    function toggleMute() {
        if (root.audioReady)
            root.audio.muted = !root.audio.muted;
    }

    function openMixer() {
        detachedProcess.command = ["pavucontrol"];
        detachedProcess.startDetached();
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Process {
        id: detachedProcess
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse.button === Qt.RightButton ? root.openMixer() : root.toggleMute()
        onWheel: root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? 5 : -5))
    }
}
