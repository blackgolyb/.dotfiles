import QtQuick

Item {
    id: root

    required property bool popupVisible

    implicitWidth: powerText.implicitWidth
    implicitHeight: powerText.implicitHeight

    signal clicked

    Text {
        id: powerText
        text: "⏻"
        color: root.popupVisible ? "#ffffff" : "#c3c3c3"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 17
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
