pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    readonly property var allowedPlayerNames: ["pear-desktop", "com.github.th_ch.youtube_music", "youtube_music"]
    readonly property var blockedPlayerNames: ["firefox", "zen", "chromium", "google-chrome", "google chrome", "brave", "vivaldi", "opera", "microsoft-edge", "microsoft edge", "librewolf", "waterfox", "floorp"]
    readonly property var blockedPlayerDbusPrefixes: ["firefox", "zen", "librewolf", "waterfox", "floorp"]
    readonly property var players: Mpris.players.values.filter(player => !isBlockedPlayer(player))
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

    property string artAccentColor: ""
    property string pendingAccentArtUrl: ""

    visible: false

    onArtUrlChanged: root.extractAccentColor()

    function playerText(value): string {
        return value == null ? "" : value.toString().toLowerCase();
    }

    function playerIdentityText(player): string {
        return `${playerText(player.desktopEntry)} ${playerText(player.identity)}`;
    }

    function playerDbusName(player): string {
        return playerText(player.dbusName).replace(/^org\.mpris\.mediaplayer2\./, "");
    }

    function isBlockedPlayer(player): bool {
        const identityText = playerIdentityText(player);
        const dbusName = playerDbusName(player);

        if (allowedPlayerNames.some(name => identityText.includes(name)))
            return false;
        if (blockedPlayerNames.some(name => identityText.includes(name)))
            return true;
        if (blockedPlayerDbusPrefixes.some(name => dbusName === name || dbusName.startsWith(`${name}.`) || dbusName.startsWith(`${name}_`)))
            return true;

        return false;
    }

    function formatTime(seconds: real): string {
        const safeSeconds = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(safeSeconds / 60);
        const rest = safeSeconds % 60;
        return `${minutes}:${rest.toString().padStart(2, "0")}`;
    }

    function colorzInputFor(url: string): string {
        if (url.startsWith("file://"))
            return decodeURIComponent(url.slice("file://".length));
        return url;
    }

    function parseAccentColor(output: string): string {
        const colors = output.trim().split(/\s+/);
        return colors.length >= 2 ? colors[1] : "";
    }

    function extractAccentColor(): void {
        if (root.artUrl.length === 0) {
            root.pendingAccentArtUrl = "";
            root.artAccentColor = "";
            return;
        }

        root.pendingAccentArtUrl = root.artUrl;
        accentProcess.exec(["sh", "-c", "command -v colorz >/dev/null 2>&1 || exit 127; colorz -n 1 --no-preview \"$1\"", "colorz", root.colorzInputFor(root.artUrl)]);
    }

    function seekAt(mouseX: real, width: real): void {
        if (root.canSeek && root.length > 0)
            root.player.position = Math.max(0, Math.min(root.length, root.length * mouseX / width));
    }

    function togglePlaying(): void {
        if (root.player != null && root.player.canTogglePlaying)
            root.player.togglePlaying();
    }

    function play(): void {
        if (root.player != null && root.player.canPlay)
            root.player.play();
    }

    function pause(): void {
        if (root.player != null && root.player.canPause)
            root.player.pause();
    }

    function stop(): void {
        if (root.player != null && root.player.canControl)
            root.player.stop();
    }

    function next(): void {
        if (root.player != null && root.player.canGoNext)
            root.player.next();
    }

    function previous(): void {
        if (root.player != null && root.player.canGoPrevious)
            root.player.previous();
    }

    function seek(offset: real): void {
        if (root.player != null && root.player.canSeek)
            root.player.seek(offset);
    }

    function setPosition(position: real): void {
        if (root.canSeek && root.length > 0)
            root.player.position = Math.max(0, Math.min(root.length, position));
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player != null && root.playing
        onTriggered: root.player.positionChanged()
    }

    Process {
        id: accentProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.pendingAccentArtUrl !== root.artUrl)
                    return;
                root.artAccentColor = root.parseAccentColor(text);
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0 && root.pendingAccentArtUrl === root.artUrl)
                root.artAccentColor = "";
        }
    }

    IpcHandler {
        target: "music"

        function toggle(): void {
            root.togglePlaying();
        }
        function playPause(): void {
            root.togglePlaying();
        }
        function play(): void {
            root.play();
        }
        function pause(): void {
            root.pause();
        }
        function stop(): void {
            root.stop();
        }
        function next(): void {
            root.next();
        }
        function previous(): void {
            root.previous();
        }
        function seek(offset: real): void {
            root.seek(offset);
        }
        function setPosition(position: real): void {
            root.setPosition(position);
        }
    }
}
