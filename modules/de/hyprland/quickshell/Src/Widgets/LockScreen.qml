import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtMultimedia
import Src.Ui as Ui

Item {
    id: root

    property string password: ""
    property string statusText: ""
    property bool authenticating: false
    property bool lockVideoActive: false
    property bool lockVideoLoop: false
    property bool lockVideoAudio: false
    property bool lockVideoStarted: false
    property int lockVideoPosition: 0
    property int lockVideoPlaybackPosition: 0
    property string lockVideoSource: ""
    property string lockVideoAudioSource: ""
    property string wallpaperFit: "cover"
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") ?? `${Quickshell.env("HOME")}/.cache`
    readonly property string currentWallpaper: `${cacheHome}/hypr/current-wallpaper`

    visible: false

    function open(): void {
        password = "";
        statusText = "";
        authenticating = false;
        lockVideoActive = false;
        lockVideoStarted = false;
        lockVideoAudioSource = "";
        wallpaperFit = "cover";
        lockStateProcess.exec(["wallpaper_manager", "lock-state"]);
        sessionLock.locked = true;
    }

    function authenticate(passwordText): void {
        if (authenticating || passwordText.length === 0)
            return;

        password = passwordText;
        statusText = "Checking password...";
        authenticating = true;

        if (pam.active)
            pam.abort();
        if (!pam.start()) {
            authenticating = false;
            statusText = "Could not start authentication";
        }
    }

    function unlockSession(): void {
        if (lockVideoActive) {
            const resumePosition = lockVideoStarted ? lockVideoPlaybackPosition : lockVideoPosition;
            resumeProcess.exec(["wallpaper_manager", "resume", "--position-ms", String(resumePosition)]);
            lockVideoActive = false;
            lockVideoStarted = false;
        }
        password = "";
        statusText = "";
        authenticating = false;
        sessionLock.locked = false;
    }

    function fail(message): void {
        password = "";
        authenticating = false;
        statusText = message;
    }

    function runPower(command): void {
        Quickshell.execDetached(command);
    }

    function videoUrl(source): string {
        return source.startsWith("/") ? `file://${source}` : source;
    }

    function imageFillMode(): int {
        if (wallpaperFit === "contain")
            return Image.PreserveAspectFit;
        if (wallpaperFit === "fill")
            return Image.Stretch;
        return Image.PreserveAspectCrop;
    }

    function videoFillMode(): int {
        if (wallpaperFit === "contain")
            return VideoOutput.PreserveAspectFit;
        if (wallpaperFit === "fill")
            return VideoOutput.Stretch;
        return VideoOutput.PreserveAspectCrop;
    }

    Process {
        id: lockStateProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (!sessionLock.locked)
                    return;
                try {
                    const state = JSON.parse(text);
                    root.wallpaperFit = state.fit ?? "cover";
                    if (state.type !== "video" || !state.handoff)
                        return;
                    root.lockVideoPosition = state.positionMs ?? 0;
                    root.lockVideoPlaybackPosition = root.lockVideoPosition;
                    root.lockVideoLoop = state.loop ?? false;
                    root.lockVideoAudio = state.audio ?? false;
                    root.lockVideoSource = root.videoUrl(state.source ?? "");
                    root.lockVideoAudioSource = root.videoUrl(state.audioSource ?? "");
                    root.lockVideoActive = root.lockVideoSource.length > 0;
                } catch (error) {
                    root.lockVideoActive = false;
                }
            }
        }
    }

    Process {
        id: resumeProcess
    }

    IpcHandler {
        target: "lock"

        function open(): void {
            root.open();
        }
    }

    PamContext {
        id: pam
        config: "quickshell-lock"
        user: Quickshell.env("USER") ?? ""

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.password);
        }

        onCompleted: result => {
            if (result == PamResult.Success)
                root.unlockSession();
            else if (result == PamResult.MaxTries)
                root.fail("Too many attempts");
            else
                root.fail("Wrong password");
        }

        onError: error => root.fail(PamError.toString(error))
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            id: surface
            color: Ui.Theme.background
            property bool videoStarted: false
            property bool videoReady: false
            property bool audioReady: false
            property bool audioFailed: false

            readonly property var powerActions: [
                {
                    label: "Suspend",
                    icon: "󰒲",
                    command: ["systemctl", "suspend"]
                },
                {
                    label: "Reboot",
                    icon: "󰜉",
                    command: ["systemctl", "reboot"]
                },
                {
                    label: "Power off",
                    icon: "⏻",
                    command: ["systemctl", "poweroff"]
                },
            ]

            onVisibleChanged: {
                if (visible) {
                    passwordInput.text = "";
                    passwordInput.forceInputFocus();
                }
            }

            function submit(): void {
                root.authenticate(passwordInput.text);
                passwordInput.text = "";
            }

            function startVideo(): void {
                if (!root.lockVideoActive || videoStarted || !videoReady)
                    return;

                const separateAudio = root.lockVideoAudio && root.lockVideoAudioSource.length > 0 && screen === Quickshell.screens[0] && !audioFailed;
                if (separateAudio && (!audioReady || (root.lockVideoPosition > 0 && !lockAudioPlayer.seekable)))
                    return;
                if (root.lockVideoPosition > 0 && !lockVideoPlayer.seekable)
                    return;

                lockVideoPlayer.position = root.lockVideoPosition;
                if (separateAudio) {
                    lockAudioPlayer.position = root.lockVideoPosition;
                    lockAudioPlayer.play();
                }
                root.lockVideoPlaybackPosition = lockVideoPlayer.position;
                videoStarted = true;
                root.lockVideoStarted = true;
                lockVideoPlayer.play();
            }

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
            }

            MediaPlayer {
                id: lockVideoPlayer

                source: root.lockVideoActive ? root.lockVideoSource : ""
                videoOutput: lockVideoOutput
                audioOutput: AudioOutput {
                    muted: !root.lockVideoAudio || root.lockVideoAudioSource.length > 0 || surface.screen !== Quickshell.screens[0]
                }
                loops: root.lockVideoLoop ? MediaPlayer.Infinite : 1

                onSourceChanged: {
                    surface.videoReady = false;
                    surface.videoStarted = false;
                }
                onMediaStatusChanged: {
                    if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                        surface.videoReady = true;
                        surface.startVideo();
                    }
                }
                onSeekableChanged: surface.startVideo()
                onPositionChanged: root.lockVideoPlaybackPosition = position
                onErrorOccurred: {
                    root.lockVideoActive = false;
                    root.lockVideoStarted = false;
                    resumeProcess.exec(["wallpaper_manager", "resume", "--position-ms", String(root.lockVideoPosition)]);
                }
            }

            MediaPlayer {
                id: lockAudioPlayer

                source: root.lockVideoActive && root.lockVideoAudio && surface.screen === Quickshell.screens[0] ? root.lockVideoAudioSource : ""
                audioOutput: AudioOutput {}
                loops: root.lockVideoLoop ? MediaPlayer.Infinite : 1

                onSourceChanged: {
                    surface.audioReady = false;
                    surface.audioFailed = false;
                }
                onMediaStatusChanged: {
                    if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                        surface.audioReady = true;
                        surface.startVideo();
                    }
                }
                onSeekableChanged: surface.startVideo()
                onErrorOccurred: {
                    surface.audioFailed = true;
                    surface.audioReady = true;
                    surface.startVideo();
                }
            }

            Image {
                anchors.fill: parent
                visible: !root.lockVideoActive
                source: `file://${root.currentWallpaper}`
                cache: false
                fillMode: root.imageFillMode()
                asynchronous: true
            }

            VideoOutput {
                id: lockVideoOutput

                anchors.fill: parent
                visible: root.lockVideoActive
                fillMode: root.videoFillMode()
            }

            Rectangle {
                anchors.fill: parent
                color: Ui.Theme.overlay
                opacity: 0.42
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Ui.Theme.transparent
                    }
                    GradientStop {
                        position: 1
                        color: Ui.Theme.background
                    }
                }
                opacity: 0.76
            }

            ColumnLayout {
                id: clockBlock
                anchors.centerIn: parent
                spacing: 4

                Ui.UiText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    color: Ui.Theme.textPrimary
                    font.pixelSize: 72
                    font.bold: true
                }

                Ui.UiText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd, dd MMMM")
                    color: Ui.Theme.textSecondary
                    font.pixelSize: Ui.Theme.textLg
                }
            }

            ColumnLayout {
                width: Math.min(surface.width - 48, 460)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: clockBlock.bottom
                anchors.topMargin: 28
                spacing: 12

                Ui.UiTextInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    implicitHeight: 44
                    inputEnabled: !root.authenticating
                    echoMode: TextInput.Password
                    placeholderText: root.authenticating ? "Checking..." : "Password"
                    textPixelSize: Ui.Theme.textLg
                    color: Ui.Theme.transparent
                    onAccepted: surface.submit()
                }

                Ui.UiText {
                    Layout.fillWidth: true
                    text: root.statusText
                    visible: text.length > 0
                    color: root.authenticating ? Ui.Theme.textSubtle : Ui.Theme.danger
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Ui.Theme.textSm
                }
            }

            RowLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                spacing: 10

                Repeater {
                    model: surface.powerActions

                    Ui.UiButton {
                        required property var modelData

                        text: `${modelData.icon} ${modelData.label}`
                        implicitWidth: 124
                        normalColor: Ui.Theme.surfaceSunken
                        hoverColor: Ui.Theme.surfaceActive
                        textColor: Ui.Theme.textSecondary
                        onClicked: root.runPower(modelData.command)
                    }
                }
            }
        }
    }
}
