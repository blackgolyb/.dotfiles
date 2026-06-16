import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    required property var actions
    required property var anchorWindow

    signal actionTriggered(var action)

    anchor.window: root.anchorWindow
    anchor.rect.x: Math.round((root.anchorWindow.width - width) / 2)
    anchor.rect.y: root.anchorWindow.height + 16
    width: 360
    height: 116
    visible: false
    color: "#2e3440"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Repeater {
            model: root.actions

            Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: powerMouse.containsMouse ? "#3b4252" : "#252b35"

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.actionTriggered(parent.modelData)
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.modelData.icon
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 22
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.modelData.label
                        color: "#c3c3c3"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
