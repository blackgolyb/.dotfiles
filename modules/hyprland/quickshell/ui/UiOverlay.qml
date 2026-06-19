import QtQuick

Item {
    id: root

    default property alias content: contentHost.data
    property real dimOpacity: 0.28
    signal dismissed

    Rectangle {
        anchors.fill: parent
        color: Theme.overlay
        opacity: root.dimOpacity

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
