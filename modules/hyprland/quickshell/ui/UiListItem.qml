import QtQuick

Rectangle {
    id: root

    property bool selected: false
    property bool hovered: mouseArea.containsMouse
    signal clicked
    signal entered

    radius: Theme.radiusMd
    color: selected ? Theme.surfaceActive : hovered ? Theme.surfaceHover : Theme.transparent

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.entered()
        onClicked: root.clicked()
    }
}
