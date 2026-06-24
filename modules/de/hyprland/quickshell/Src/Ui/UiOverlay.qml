import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    default property alias content: contentHost.data
    property var anchorWindow: null
    property string namespaceName: "popup"
    property bool enableBlur: true
    property bool exclusiveKeyboard: false
    property bool focusableWindow: false
    property bool overlay: false
    property real dimOpacity: 0.28
    property bool dismissOnOverlay: true
    signal dismissed

    color: Theme.transparent
    exclusionMode: ExclusionMode.Ignore
    focusable: root.focusableWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: `${root.enableBlur ? "quickshell-overlay" : "quickshell"}-${root.namespaceName}`

    anchors.top: root.overlay
    anchors.bottom: root.overlay
    anchors.left: root.overlay
    anchors.right: root.overlay

    Rectangle {
        anchors.fill: parent
        visible: root.overlay
        color: Theme.overlay
        opacity: root.dimOpacity

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.dismissOnOverlay)
                    root.dismissed();
            }
        }
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
