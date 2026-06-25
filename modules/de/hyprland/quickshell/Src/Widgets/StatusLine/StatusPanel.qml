import QtQuick
import QtQuick.Controls as Controls
import Src.Ui as Ui
import Src.Widgets as Widgets

Ui.UiPopup {
    id: root

    required property var status
    property bool hovered: false
    readonly property int slideDistance: 22

    anchor.rect.x: root.anchorWindow != null ? Math.max(20, Math.round((root.anchorWindow.width - root.implicitWidth) / 2)) : 0
    anchor.rect.y: root.anchorWindow != null ? root.anchorWindow.height : 0
    implicitWidth: 500
    implicitHeight: 390
    grabFocus: false

    function resetView(): void {
        if (stackView.depth > 1)
            stackView.pop(stackView.get(0), Controls.StackView.Immediate);
        root.status.wifiService.closePasswordPrompt();
    }

    onVisibleChanged: {
        if (!visible)
            resetView();
    }

    Item {
        anchors.fill: parent
        clip: true

        Ui.UiCard {
            id: card

            width: parent.width
            height: parent.height
            y: root.visible ? 0 : -root.slideDistance
            opacity: root.visible ? 1 : 0
            border.width: 0

            HoverHandler {
                onHoveredChanged: root.hovered = hovered
            }

            Behavior on y {
                NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
            }

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: card.radius + 1
                color: card.color
            }

            Controls.StackView {
                id: stackView

                anchors.fill: parent
                clip: true
                initialItem: mainScreenComponent

                pushEnter: Transition {
                    NumberAnimation { property: "x"; from: stackView.width; to: 0; duration: 170; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
                }

                pushExit: Transition {
                    NumberAnimation { property: "x"; from: 0; to: -stackView.width * 0.25; duration: 170; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 }
                }

                popEnter: Transition {
                    NumberAnimation { property: "x"; from: -stackView.width * 0.25; to: 0; duration: 170; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
                }

                popExit: Transition {
                    NumberAnimation { property: "x"; from: 0; to: stackView.width; duration: 170; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 }
                }

                onCurrentItemChanged: {
                    if (root.visible && currentItem != null && currentItem.focusSearch != null)
                        currentItem.focusSearch();
                }
            }

            Component {
                id: mainScreenComponent

                StatusPanelMainScreen {
                    status: root.status
                    anchorWindow: root.anchorWindow
                    onWifiRequested: {
                        root.status.wifiService.closePasswordPrompt();
                        root.status.wifiService.refresh(false);
                        stackView.push(wifiScreenComponent);
                    }
                }
            }

            Component {
                id: wifiScreenComponent

                Widgets.WifiScreen {
                    service: root.status.wifiService
                    view: stackView
                    margins: 16
                    qrSize: 96
                }
            }
        }
    }
}
