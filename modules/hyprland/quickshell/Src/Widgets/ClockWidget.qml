import QtQuick
import Quickshell
import Quickshell.Hyprland
import Src.Ui as Ui

Item {
    id: root

    required property var anchorWindow

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Ui.UiText {
        id: clockText
        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: Ui.Theme.textPrimary
        font.pixelSize: Ui.Theme.textXl
    }

    MouseArea {
        anchors.fill: parent
        onClicked: calendar.visible = !calendar.visible
    }

    CalendarPopup {
        id: calendar
        anchorWindow: root.anchorWindow
        clockDate: clock.date
        onVisibleChanged: calendarFocusGrab.active = visible
    }

    HyprlandFocusGrab {
        id: calendarFocusGrab
        windows: [calendar]
        onCleared: calendar.visible = false
    }
}
