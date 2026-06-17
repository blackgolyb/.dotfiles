import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

Item {
    id: root

    NotificationServer {
        id: notificationServer
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    PanelWindow {
        id: notificationWindow

        readonly property int notificationCount: notificationServer.trackedNotifications.values.length

        width: 360
        height: Math.min(620, Math.max(1, notificationColumn.implicitHeight))
        visible: notificationCount > 0
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        anchors {
            top: true
            right: true
        }

        margins {
            top: 38
            right: 12
        }

        ColumnLayout {
            id: notificationColumn
            anchors.fill: parent
            spacing: 8

            Repeater {
                model: notificationServer.trackedNotifications

                Rectangle {
                    id: card

                    required property var modelData

                    readonly property int autoExpireMs: modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : 5000

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(84, cardContent.implicitHeight + 24)
                    radius: 14
                    color: "#2e3440"
                    border.width: 1
                    border.color: urgencyColor(card.modelData.urgency)
                    opacity: 0
                    x: 24

                    Component.onCompleted: {
                        opacity = 1;
                        x = 0;
                    }

                    function urgencyColor(urgency) {
                        if (urgency === NotificationUrgency.Critical)
                            return "#bf616a";
                        if (urgency === NotificationUrgency.Low)
                            return "#4c566a";
                        return "#88c0d0";
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                        }
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Timer {
                        interval: card.autoExpireMs
                        running: !card.modelData.resident && card.modelData.urgency !== NotificationUrgency.Critical
                        repeat: false
                        onTriggered: card.modelData.expire()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: card.modelData.dismiss()
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 9
                                color: "#252b35"
                                visible: card.modelData.image.length === 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 17
                                }
                            }

                            Image {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                visible: card.modelData.image.length > 0
                                source: card.modelData.image
                                fillMode: Image.PreserveAspectCrop
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.summary
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.appName
                                    color: "#8f98aa"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    visible: card.modelData.appName.length > 0
                                }
                            }

                            Text {
                                text: "×"
                                color: closeMouse.containsMouse ? "#ffffff" : "#8f98aa"
                                font.pixelSize: 18

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: card.modelData.dismiss()
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.body
                            textFormat: Text.RichText
                            color: "#c3c3c3"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            visible: card.modelData.body.length > 0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: card.modelData.actions.length > 0
                            spacing: 6

                            Item {
                                Layout.fillWidth: true
                            }

                            Repeater {
                                model: card.modelData.actions

                                Rectangle {
                                    required property var modelData

                                    Layout.preferredWidth: Math.max(actionText.implicitWidth + 18, 52)
                                    Layout.preferredHeight: 26
                                    radius: 8
                                    color: actionMouse.containsMouse ? "#4c566a" : "#3b4252"

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        color: "#ffffff"
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: parent.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
