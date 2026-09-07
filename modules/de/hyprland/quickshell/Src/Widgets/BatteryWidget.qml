import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets
import Src.Ui as Ui

RowLayout {
    id: root

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: root.batteryDevice != null && root.batteryDevice.ready && root.batteryDevice.isPresent
    readonly property int batteryPercentValue: root.batteryReady ? Math.round(root.batteryDevice.percentage * 100) : 0
    readonly property string iconName: root.batteryReady ? root.batteryIconNameFor(root.batteryPercentValue, root.batteryDevice.state) : "battery-missing"
    readonly property string percentText: root.batteryReady ? `${root.batteryPercentValue}%` : ""
    readonly property bool discharging: root.batteryReady && root.batteryDevice.state === UPowerDeviceState.Discharging

    readonly property int notificationTimeoutMs: 6000
    readonly property string notificationTag: "battery"
    readonly property var batteryLevels: [
        {
            threshold: 5,
            state: "critical",
            urgency: "critical",
            title: "Battery critical"
        },
        {
            threshold: 10,
            state: "low",
            urgency: "critical",
            title: "Battery low"
        }
    ]

    property string batteryWarningState: "none"

    spacing: 4

    onBatteryPercentValueChanged: root.checkLowBattery()
    onDischargingChanged: root.checkLowBattery()

    function batteryIconNameFor(percent, state) {
        const charging = state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge;
        const clamped = Math.max(0, Math.min(100, percent));
        const level = Math.round(clamped / 10) * 10;
        const levelName = level.toString().padStart(3, "0");

        if (state === UPowerDeviceState.FullyCharged)
            return "battery-full-charged";
        if (charging)
            return `battery-${levelName}-charging`;
        return `battery-${levelName}`;
    }

    function activeLevel() {
        if (!root.batteryReady || !root.discharging)
            return null;
        for (let i = 0; i < root.batteryLevels.length; ++i) {
            if (root.batteryPercentValue <= root.batteryLevels[i].threshold)
                return root.batteryLevels[i];
        }
        return null;
    }

    function checkLowBattery() {
        const level = root.activeLevel();
        const targetState = level ? level.state : "none";

        if (root.batteryWarningState === targetState)
            return;

        root.batteryWarningState = targetState;

        if (targetState === "none")
            root.sendNotification("normal", "Charger connected", "Battery is charging", true);
        else
            root.sendNotification(level.urgency, level.title, `Battery is at ${root.batteryPercentValue}%`, false);
    }

    function sendNotification(urgency, title, body, charging) {
        const icon = charging ? "battery-050-charging.svg" : "battery-050.svg";
        const iconPath = Qt.resolvedUrl(`../../battery_icons/${icon}`);
        notifyProcess.exec(["notify-send", "-a", root.notificationTag, "-i", iconPath, "-u", urgency, "-t", root.notificationTimeoutMs, "-h", `string:x-quickshell-stack-tag:${root.notificationTag}`, title, body]);
    }

    Component.onCompleted: root.checkLowBattery()

    Process {
        id: notifyProcess
    }

    IconImage {
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        source: Qt.resolvedUrl(`../../battery_icons/${root.iconName}.svg`)
    }

    Ui.UiText {
        text: root.percentText
        color: Ui.Theme.textPrimary
        font.pixelSize: Ui.Theme.textXl
    }
}
