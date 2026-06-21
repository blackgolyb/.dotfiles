import QtQuick
import QtQuick.Layouts
import Quickshell
import Src.Ui as Ui

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
    color: Ui.Theme.surface

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Ui.UiText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.clockDate, "dd MMMM yyyy")
            color: Ui.Theme.textPrimary
            font.pixelSize: Ui.Theme.textXl
        }

        Ui.UiText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.clockDate, "dddd")
            color: Ui.Theme.textSecondary
            font.pixelSize: Ui.Theme.textLg
        }
    }
}
