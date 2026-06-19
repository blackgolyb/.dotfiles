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
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
            top: true
            left: true
            right: true
        }

        Item {
            id: barContent
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                WorkspacesWidget {}
            }

            MusicWidget {
                anchors.centerIn: parent
                anchorWindow: bar
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

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
    }

    PowerPopup {
        id: powerPopup
        anchorWindow: bar
    }

    AppLauncher {
        anchorWindow: bar
    }

    PolkitAuth {
        anchorWindow: bar
    }

    NotificationManager {}
}
