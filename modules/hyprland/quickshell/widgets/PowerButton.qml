import QtQuick
import "../ui" as Ui

Item {
    id: root

    required property bool popupVisible

    implicitWidth: powerText.implicitWidth
    implicitHeight: powerText.implicitHeight

    signal clicked

    Ui.UiText {
        id: powerText
        text: "⏻"
        color: root.popupVisible ? Ui.Theme.textPrimary : Ui.Theme.textSecondary
        font.pixelSize: 17
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
