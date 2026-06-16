import QtQuick
import Quickshell

Item {
    id: root

    required property var anchorWindow

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText
        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: "#ffffff"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        onClicked: calendar.visible = !calendar.visible
    }

    CalendarPopup {
        id: calendar
        anchorWindow: root.anchorWindow
        clockDate: clock.date
    }
}
