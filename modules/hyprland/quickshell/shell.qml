import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "widgets"

ShellRoot {
    PanelWindow {
        id: bar
        implicitHeight: 26
        color: "#2e3440"
        exclusiveZone: implicitHeight
        exclusionMode: ExclusionMode.Auto
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            left: true
            right: true
        }

        RowLayout {
            id: barContent
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8

            WorkspacesWidget {}

            Item {
                Layout.fillWidth: true
            }

            VolumeWidget {}

            WifiWidget {
                anchorWindow: bar
            }

            KeyboardLayoutWidget {}

            BatteryWidget {}

            ClockWidget {
                anchorWindow: bar
            }

            PowerButton {
                popupVisible: powerPopup.visible
                onClicked: powerPopup.visible = !powerPopup.visible
            }
        }
    }

    PowerPopup {
        id: powerPopup
        anchorWindow: bar
    }

    NotificationManager {}
}
