import QtQuick
import QtQuick.Layouts
import Quickshell
import "widgets"

ShellRoot {
    PanelWindow {
        id: bar
        implicitHeight: 30
        color: "#2e3440"
        exclusiveZone: implicitHeight
        aboveWindows: false

        anchors {
            top: true
            left: true
            right: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8

            WorkspacesWidget {}

            Item {
                Layout.fillWidth: true
            }

            VolumeWidget {}

            KeyboardLayoutWidget {}

            BatteryWidget {}

            ClockWidget {
                anchorWindow: bar
            }

            PowerButton {
                anchorWindow: bar
            }
        }
    }
}
