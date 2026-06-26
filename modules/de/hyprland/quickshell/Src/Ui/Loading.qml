import QtQuick

Item {
    id: root

    property var name: "loading"
    property int orientation: Qt.Horizontal
    property bool running: true
    property bool active: true
    property int thickness: 2
    property int duration: 900
    property real segmentRatio: 0.34
    property color backgroundColor: Theme.border
    property color activeColor: Theme.accent
    property color inactiveColor: Theme.textDisabled
    property real phase: 0

    implicitWidth: orientation === Qt.Horizontal ? 120 : thickness
    implicitHeight: orientation === Qt.Horizontal ? thickness : 120

    onRunningChanged: {
        if (!running)
            phase = 0;
    }

    NumberAnimation on phase {
        from: 0
        to: 1
        duration: root.duration
        loops: Animation.Infinite
        running: root.running
        easing.type: Easing.InOutQuad
    }

    Rectangle {
        id: track

        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: root.backgroundColor
        clip: true

        Rectangle {
            width: root.orientation === Qt.Horizontal ? Math.max(root.thickness, parent.width * root.segmentRatio) : parent.width
            height: root.orientation === Qt.Horizontal ? parent.height : Math.max(root.thickness, parent.height * root.segmentRatio)
            x: root.orientation === Qt.Horizontal ? -width + (parent.width + width) * root.phase : 0
            y: root.orientation === Qt.Horizontal ? 0 : parent.height - (parent.height + height) * root.phase
            radius: parent.radius
            color: root.active ? root.activeColor : root.inactiveColor
        }
    }
}
