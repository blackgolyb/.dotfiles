import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Quickshell.Widgets

RowLayout {
    id: root

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: root.batteryDevice != null && root.batteryDevice.ready && root.batteryDevice.isPresent
    readonly property int batteryPercentValue: root.batteryReady ? Math.round(root.batteryDevice.percentage * 100) : 0
    readonly property string iconName: root.batteryReady ? root.batteryIconNameFor(root.batteryPercentValue, root.batteryDevice.state) : "battery-missing"
    readonly property string percentText: root.batteryReady ? `${root.batteryPercentValue}%` : ""

    spacing: 4

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
