import QtQuick

Item {
    id: root

    property var name: "progress"
    property int orientation: Qt.Horizontal
    property real progress: 0
    property bool active: true
    property int thickness: 2
    property int animationDuration: 160
    property color backgroundColor: Theme.border
    property color activeColor: Theme.accent
    property color inactiveColor: Theme.textDisabled
    readonly property real normalizedProgress: Math.max(0, Math.min(1, progress))

    implicitWidth: orientation === Qt.Horizontal ? 120 : thickness
    implicitHeight: orientation === Qt.Horizontal ? thickness : 120

    Rectangle {
        id: track

        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: root.backgroundColor

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.orientation === Qt.Horizontal ? parent.width * root.normalizedProgress : parent.width
            height: root.orientation === Qt.Horizontal ? parent.height : parent.height * root.normalizedProgress
            radius: parent.radius
            color: root.active ? root.activeColor : root.inactiveColor

            Behavior on width {
                NumberAnimation {
                    duration: root.animationDuration
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: root.animationDuration
                }
            }
        }
    }
}
