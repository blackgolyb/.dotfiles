pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root

    readonly property string devicePath: device.length > 0 ? `/sys/class/backlight/${device}` : ""
    readonly property int percent: ready && maxBrightness > 0 ? Math.round(Math.max(0, Math.min(100, currentBrightness * 100 / maxBrightness))) : 0

    property bool ready: false
    property string device: ""
    property int currentBrightness: 0
    property int maxBrightness: 0

    visible: false

    function parseNumber(text): int {
        const value = Number(String(text).trim());
        return Number.isNaN(value) ? 0 : Math.round(value);
    }

    function updateFromFiles(): void {
        if (root.devicePath.length === 0)
            return;

        const current = parseNumber(brightnessFile.text());
        const maximum = parseNumber(maxBrightnessFile.text());
        if (maximum <= 0)
            return;

        root.currentBrightness = current;
        root.maxBrightness = maximum;
        root.ready = true;
    }

    function refresh(): void {
        if (root.devicePath.length > 0) {
            brightnessFile.reload();
            maxBrightnessFile.reload();
            return;
        }

        deviceProcess.exec(["brightnessctl", "-m"]);
    }

    function setPercent(value: real): void {
        const next = Math.round(Math.max(1, Math.min(100, value)));
        writeProcess.exec(["brightnessctl", "set", `${next}%`]);
    }

    Process {
        id: deviceProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                const nextDevice = parts[0] ?? "";
                if (nextDevice.length === 0)
                    return;

                root.device = nextDevice;
            }
        }
    }

    Process {
        id: writeProcess
        onExited: root.refresh()
    }

    FileView {
        id: brightnessFile

        path: root.devicePath.length > 0 ? `${root.devicePath}/brightness` : ""
        preload: root.devicePath.length > 0
        blockLoading: true
        watchChanges: root.devicePath.length > 0
        printErrors: false

        onLoaded: root.updateFromFiles()
        onTextChanged: root.updateFromFiles()
        onFileChanged: reload()
    }

    FileView {
        id: maxBrightnessFile

        path: root.devicePath.length > 0 ? `${root.devicePath}/max_brightness` : ""
        preload: root.devicePath.length > 0
        blockLoading: true
        watchChanges: root.devicePath.length > 0
        printErrors: false

        onLoaded: root.updateFromFiles()
        onTextChanged: root.updateFromFiles()
        onFileChanged: reload()
    }

    Component.onCompleted: root.refresh()
}
