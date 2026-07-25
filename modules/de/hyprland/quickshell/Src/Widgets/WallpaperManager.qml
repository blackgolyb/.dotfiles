import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Src.Ui as Ui

Ui.UiOverlay {
    id: root

    property var wallpapers: []
    property string activeId: ""
    property string page: "library"
    property bool loopVideo: true
    property bool audioEnabled: false
    property string videoFit: "cover"
    readonly property var fitModes: ["cover", "contain", "fill"]
    property string statusText: ""
    property bool statusError: false

    namespaceName: "wallpaper-manager"
    enableBlur: true
    exclusiveKeyboard: true
    focusableWindow: true
    overlay: true
    dimOpacity: 0.28
    screen: root.anchorWindow.screen
    onDismissed: root.close()
    visible: false

    function open(): void {
        root.page = "library";
        root.statusText = "";
        root.visible = true;
        root.refresh();
    }

    function close(): void {
        root.visible = false;
    }

    function refresh(): void {
        listProcess.exec(["wallpaper_manager", "list"]);
    }

    function playEntry(entryId): void {
        root.runAction(["wallpaper_manager", "play", entryId], "Wallpaper applied");
    }

    function imageFillMode(fit): int {
        if (fit === "contain")
            return Image.PreserveAspectFit;
        if (fit === "fill")
            return Image.Stretch;
        return Image.PreserveAspectCrop;
    }

    function addAndPlay(): void {
        const url = urlInput.text.trim();
        if (url.length === 0) {
            root.statusError = true;
            root.statusText = "Enter a URL or file path";
            urlInput.forceInputFocus();
            return;
        }

        const command = ["wallpaper_manager", "add", url, "--play", "--fit", root.videoFit];
        if (root.loopVideo)
            command.push("--loop");
        if (root.audioEnabled)
            command.push("--audio");
        root.runAction(command, "Video saved and playing");
    }

    function runAction(command, successMessage): void {
        root.statusText = "";
        actionProcess.successMessage = successMessage;
        actionProcess.errorOutput = "";
        actionProcess.exec(command);
    }

    onVisibleChanged: {
        if (visible)
            focusTrap.forceActiveFocus();
    }

    IpcHandler {
        target: "wallpaper"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    Process {
        id: listProcess

        property string errorOutput: ""

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const catalog = JSON.parse(text);
                    root.wallpapers = catalog.wallpapers ?? [];
                    root.activeId = catalog.active ?? "";
                } catch (error) {
                    root.statusError = true;
                    root.statusText = `Invalid wallpaper catalog: ${error}`;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: listProcess.errorOutput = text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.statusError = true;
                root.statusText = listProcess.errorOutput || "Could not load wallpaper catalog";
            }
        }
    }

    Process {
        id: actionProcess

        property string successMessage: ""
        property string errorOutput: ""

        stderr: StdioCollector {
            onStreamFinished: actionProcess.errorOutput = text.trim()
        }
        onExited: exitCode => {
            root.statusError = exitCode !== 0;
            root.statusText = exitCode === 0 ? actionProcess.successMessage : (actionProcess.errorOutput || "Wallpaper command failed");
            if (exitCode === 0) {
                urlInput.text = "";
                root.refresh();
            }
        }
    }

    Item {
        id: focusTrap
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.close()
    }

    Ui.UiCard {
        width: Math.min(root.width - 40, 760)
        height: Math.min(root.height - 64, 610)
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: Ui.Theme.spacingMd

            RowLayout {
                Layout.fillWidth: true
                spacing: Ui.Theme.spacingMd

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Ui.UiText {
                        text: "Wallpaper manager"
                        color: Ui.Theme.textPrimary
                        font.pixelSize: Ui.Theme.textXl
                        font.bold: true
                    }

                    Ui.UiText {
                        text: "Images and videos from wallpapers.json"
                        color: Ui.Theme.textMuted
                        font.pixelSize: Ui.Theme.textSm
                    }
                }

                Ui.UiButton {
                    text: "󰅖"
                    icon: true
                    onClicked: root.close()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Ui.Theme.spacingSm

                Repeater {
                    model: [
                        {
                            key: "library",
                            label: "󰋩  Wallpapers"
                        },
                        {
                            key: "new",
                            label: "󰐕  Play new"
                        }
                    ]

                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: Ui.Theme.radiusSm
                        color: root.page === modelData.key ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken
                        border.width: root.page === modelData.key ? 1 : 0
                        border.color: Ui.Theme.accent

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.page = parent.modelData.key;
                                root.statusText = "";
                                if (root.page === "new")
                                    urlInput.forceInputFocus();
                            }
                        }

                        Ui.UiText {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: root.page === parent.modelData.key ? Ui.Theme.textPrimary : Ui.Theme.textSecondary
                            font.pixelSize: Ui.Theme.textMd
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: wallpaperGrid

                    anchors.fill: parent
                    visible: root.page === "library"
                    clip: true
                    cellWidth: width / 3
                    cellHeight: 150
                    model: root.wallpapers

                    delegate: Item {
                        required property var modelData

                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: Ui.Theme.radiusMd
                            color: Ui.Theme.surfaceSunken
                            border.width: modelData.id === root.activeId ? 2 : 1
                            border.color: modelData.id === root.activeId ? Ui.Theme.accent : Ui.Theme.border
                            clip: true

                            Image {
                                anchors.fill: parent
                                visible: modelData.type === "image"
                                source: visible ? modelData.source : ""
                                fillMode: root.imageFillMode(modelData.fit)
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: modelData.type === "video"
                                color: Ui.Theme.surfaceRaised

                                Ui.UiIcon {
                                    anchors.centerIn: parent
                                    text: "󰕧"
                                    color: Ui.Theme.accent
                                    font.pixelSize: 34
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 38
                                color: "#cc252b35"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 6

                                    Ui.UiText {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: Ui.Theme.textPrimary
                                        font.pixelSize: Ui.Theme.textSm
                                        elide: Text.ElideRight
                                    }

                                    Ui.UiText {
                                        text: modelData.fit
                                        color: Ui.Theme.textMuted
                                        font.pixelSize: Ui.Theme.textXs
                                    }

                                    Ui.UiIcon {
                                        text: modelData.type === "video" ? "󰕧" : "󰋩"
                                        color: Ui.Theme.textSubtle
                                        font.pixelSize: Ui.Theme.textMd
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !actionProcess.running
                                onClicked: root.playEntry(modelData.id)
                            }
                        }
                    }

                    Ui.UiText {
                        anchors.centerIn: parent
                        visible: root.wallpapers.length === 0
                        text: "No wallpapers configured"
                        color: Ui.Theme.textMuted
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    visible: root.page === "new"
                    spacing: Ui.Theme.spacingMd

                    Item {
                        Layout.fillHeight: true
                    }

                    Ui.UiText {
                        Layout.fillWidth: true
                        text: "Video URL or local path"
                        color: Ui.Theme.textSecondary
                        font.pixelSize: Ui.Theme.textSm
                    }

                    Ui.UiTextInput {
                        id: urlInput

                        Layout.fillWidth: true
                        iconText: "󰖟"
                        placeholderText: "https://example.com/wallpaper.mp4"
                        textPixelSize: Ui.Theme.textMd
                        onAccepted: root.addAndPlay()
                        onEscaped: root.close()
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Ui.Theme.spacingSm

                        Ui.UiText {
                            text: "Fit"
                            color: Ui.Theme.textSecondary
                            font.pixelSize: Ui.Theme.textSm
                        }

                        Ui.UiComboBox {
                            id: fitSelector

                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            model: ["Cover", "Contain", "Fill"]
                            editable: false
                            inlineCompletion: false
                            currentIndex: root.fitModes.indexOf(root.videoFit)
                            onActivated: index => root.videoFit = root.fitModes[index]
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Ui.Theme.spacingSm

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            radius: Ui.Theme.radiusSm
                            color: Ui.Theme.surfaceSunken
                            border.width: root.loopVideo ? 1 : 0
                            border.color: Ui.Theme.accent

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.loopVideo = !root.loopVideo
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                Ui.UiIcon {
                                    text: "󰑖"
                                    color: root.loopVideo ? Ui.Theme.accent : Ui.Theme.textMuted
                                }

                                Ui.UiText {
                                    Layout.fillWidth: true
                                    text: "Loop"
                                    color: Ui.Theme.textPrimary
                                }

                                Ui.UiText {
                                    text: root.loopVideo ? "On" : "Off"
                                    color: root.loopVideo ? Ui.Theme.accent : Ui.Theme.textMuted
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            radius: Ui.Theme.radiusSm
                            color: Ui.Theme.surfaceSunken
                            border.width: root.audioEnabled ? 1 : 0
                            border.color: Ui.Theme.accent

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.audioEnabled = !root.audioEnabled
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                Ui.UiIcon {
                                    text: root.audioEnabled ? "󰕾" : "󰖁"
                                    color: root.audioEnabled ? Ui.Theme.accent : Ui.Theme.textMuted
                                }

                                Ui.UiText {
                                    Layout.fillWidth: true
                                    text: "Audio"
                                    color: Ui.Theme.textPrimary
                                }

                                Ui.UiText {
                                    text: root.audioEnabled ? "On" : "Off"
                                    color: root.audioEnabled ? Ui.Theme.accent : Ui.Theme.textMuted
                                }
                            }
                        }
                    }

                    Ui.UiText {
                        Layout.fillWidth: true
                        text: "The new video is saved to wallpapers.json and started on every output."
                        color: Ui.Theme.textMuted
                        font.pixelSize: Ui.Theme.textSm
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            Layout.fillWidth: true
                        }

                        Ui.UiButton {
                            text: actionProcess.running ? "Starting…" : "Save & play"
                            variant: "accent"
                            minWidth: 132
                            enabled: !actionProcess.running
                            onClicked: root.addAndPlay()
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            Ui.UiText {
                Layout.fillWidth: true
                visible: root.statusText.length > 0
                text: root.statusText
                color: root.statusError ? Ui.Theme.danger : Ui.Theme.success
                font.pixelSize: Ui.Theme.textSm
                wrapMode: Text.Wrap
            }
        }
    }
}
