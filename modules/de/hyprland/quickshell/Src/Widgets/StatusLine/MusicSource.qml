import QtQuick
import Src.Services as Services

Item {
    id: root

    readonly property var music: Services.MusicService
    readonly property string mode: "music"
    readonly property bool available: music.hasPlayers
    readonly property real progress: music.progress
    readonly property bool active: music.playing
    readonly property string icon: music.playing ? "" : ""
    readonly property string text: music.titleLine
    readonly property bool hasPlayers: music.hasPlayers
    readonly property bool playing: music.playing

    visible: false

    function togglePlaying(): void {
        music.togglePlaying();
    }
}
