import QtQuick

Rectangle {
    id: root

    property string text: ""
    property color normalColor: Theme.surfaceSunken
    property color hoverColor: Theme.surfaceActive
    property color textColor: Theme.textSecondary
    signal clicked

    implicitWidth: Math.max(96, label.implicitWidth + 28)
    implicitHeight: 34
    radius: Theme.radiusSm
    color: mouseArea.containsMouse ? hoverColor : normalColor

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPressed: forceActiveFocus()
        onClicked: root.clicked()
    }

    UiText {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.pixelSize: Theme.textMd
    }
}
