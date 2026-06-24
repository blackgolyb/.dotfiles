import QtQuick

MouseArea {
    id: root

    signal sinkClicked

    anchors.fill: parent
    onClicked: sinkClicked()
}
