import QtQuick

Item {
    id: root

    property string mode: "progress"
    property string icon: ""
    property int orientation: Qt.Horizontal
    property real progress: 0
    property bool active: true
    property bool running: true
    property int thickness: 2
    property int iconSize: 12
    property int animationDuration: 160
    property int loadingDuration: 900
    property color backgroundColor: Theme.border
    property color activeColor: Theme.accent
    property color inactiveColor: Theme.textDisabled
    property color passiveColor: Theme.surfaceActive
    property color iconColor: active ? Theme.textPrimary : Theme.textDisabled

    implicitWidth: orientation === Qt.Horizontal ? 120 : thickness
    implicitHeight: orientation === Qt.Horizontal ? thickness : 120

    Loader {
        anchors.fill: parent
        sourceComponent: root.mode === "loading" ? loadingComponent : root.mode === "passive" ? passiveComponent : progressComponent
    }

    UiIcon {
        anchors.centerIn: parent
        visible: root.icon.length > 0
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
    }

    Component {
        id: progressComponent

        Progress {
            orientation: root.orientation
            progress: root.progress
            active: root.active
            thickness: root.thickness
            animationDuration: root.animationDuration
            backgroundColor: root.backgroundColor
            activeColor: root.activeColor
            inactiveColor: root.inactiveColor
        }
    }

    Component {
        id: loadingComponent

        Loading {
            orientation: root.orientation
            running: root.running
            active: root.active
            thickness: root.thickness
            duration: root.loadingDuration
            backgroundColor: root.backgroundColor
            activeColor: root.activeColor
            inactiveColor: root.inactiveColor
        }
    }

    Component {
        id: passiveComponent

        Rectangle {
            radius: Math.min(width, height) / 2
            color: root.passiveColor
        }
    }
}
