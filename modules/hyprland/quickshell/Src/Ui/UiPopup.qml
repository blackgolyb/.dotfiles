import QtQuick
import Quickshell

PopupWindow {
    id: root

    default property alias content: contentHost.data
    property var anchorWindow: null

    anchor.window: root.anchorWindow
    color: Theme.transparent

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
