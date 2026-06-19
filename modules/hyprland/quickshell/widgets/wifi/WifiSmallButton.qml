import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui

Rectangle {
    id: root

    required property string label
    property bool subtle: false
    signal clicked

    Layout.preferredWidth: root.subtle ? 24 : Math.max(42, labelText.implicitWidth + 16)
    Layout.preferredHeight: 26
    radius: Ui.Theme.radiusSm
    color: root.subtle ? (buttonMouse.containsMouse ? Ui.Theme.surfaceHover : Ui.Theme.transparent) : (buttonMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive)

    Ui.UiText {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: Ui.Theme.textPrimary
        font.pixelSize: Ui.Theme.textSm
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
