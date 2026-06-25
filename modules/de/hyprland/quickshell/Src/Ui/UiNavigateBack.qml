import QtQuick
import QtQuick.Layouts
import Src.Ui as Ui

Rectangle {
    id: root

    required property var view
    signal clicked

    visible: root.view != null

    Layout.preferredWidth: 34
    Layout.preferredHeight: 28
    radius: Ui.Theme.radiusSm
    color: backMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive

    Ui.UiIcon {
        anchors.centerIn: parent
        text: "󰁍"
        font.pixelSize: 16
    }

    MouseArea {
        id: backMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (root.view != null && root.view.depth > 1)
                root.view.pop();
            root.clicked();
        }
    }
}
