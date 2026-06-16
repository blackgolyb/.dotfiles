import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var clockDate

    anchor.window: root.anchorWindow
    anchor.rect.x: root.anchorWindow.width - width - 20
    anchor.rect.y: root.anchorWindow.height
    width: 260
    height: 96
    visible: false
    color: "#2e3440"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.clockDate, "dd MMMM yyyy")
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 16
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.clockDate, "dddd")
            color: "#c3c3c3"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 14
        }
    }
}
