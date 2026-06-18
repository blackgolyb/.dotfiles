import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets

RowLayout {
    id: root

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: root.batteryDevice != null && root.batteryDevice.ready && root.batteryDevice.isPresent
    readonly property int batteryPercentValue: root.batteryReady ? Math.round(root.batteryDevice.percentage * 100) : 0
    readonly property string iconName: root.batteryReady ? root.batteryIconNameFor(root.batteryPercentValue, root.batteryDevice.state) : "battery-missing"
    readonly property string percentText: root.batteryReady ? `${root.batteryPercentValue}%` : ""
    readonly property bool discharging: root.batteryReady && root.batteryDevice.state === UPowerDeviceState.Discharging

    property bool notifiedTenPercent: false
    property bool notifiedFivePercent: false

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

    function checkLowBattery() {
        if (!root.discharging || root.batteryPercentValue > 10) {
            root.notifiedTenPercent = false;
            root.notifiedFivePercent = false;
            return;
        }

        if (root.batteryPercentValue <= 5) {
            if (!root.notifiedFivePercent) {
                root.notifiedFivePercent = true;
                root.sendNotification("critical", "Battery critical", `Battery is at ${root.batteryPercentValue}%`);
            }
            return;
        }

        if (!root.notifiedTenPercent) {
            root.notifiedTenPercent = true;
            root.sendNotification("normal", "Battery low", `Battery is at ${root.batteryPercentValue}%`);
        }
    }

    function sendNotification(urgency, title, body) {
        notifyProcess.exec(["notify-send", "-a", "battery", "-u", urgency, "-t", "6000", title, body]);
    }

    Component.onCompleted: root.checkLowBattery()

    Process {
        id: notifyProcess
    }

    IconImage {
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        source: Qt.resolvedUrl(`../battery_icons/${root.iconName}.svg`)
    }

    Text {
        text: root.percentText
        color: "#ffffff"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 16
    }
}
