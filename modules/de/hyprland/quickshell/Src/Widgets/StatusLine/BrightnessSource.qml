import QtQuick
import Src.Services as Services

Item {
    id: root

    readonly property var service: Services.BrightnessService
    readonly property string mode: "brightness"
    readonly property bool available: showing
    readonly property real progress: percent / 100
    readonly property bool active: ready
    readonly property string icon: "󰃠"
    readonly property string text: `${percent}%`
    readonly property int percent: service.percent
    readonly property bool ready: service.ready

    property bool showing: false
    property int lastPercent: -1

    visible: false

    onReadyChanged: {
        if (ready)
            lastPercent = percent;
    }

    onPercentChanged: {
        if (!ready)
            return;
        if (lastPercent >= 0 && lastPercent !== percent)
            showTransient();
        lastPercent = percent;
    }

    function showTransient(): void {
        showing = true;
        transientTimer.restart();
    }

    function setPercent(value: real): void {
        service.setPercent(value);
    }

    function refresh(): void {
        service.refresh();
    }

    Timer {
        id: transientTimer
        interval: 1400
        repeat: false
        onTriggered: root.showing = false
    }
}
