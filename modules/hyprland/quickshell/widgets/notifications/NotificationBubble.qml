import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../ui" as Ui

Ui.UiCard {
    id: root

    required property var entry
    readonly property var notification: entry.notification
    readonly property string serial: entry.serial
    readonly property string imageSource: root.notification.image ?? ""
    readonly property string appIcon: root.notification.appIcon ?? ""
    readonly property bool hasImage: root.imageSource.length > 0
    readonly property bool hasAppIcon: root.appIcon.length > 0

    signal dismissRequested(var notification)
    signal actionRequested(var action)

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(84, cardContent.implicitHeight + 24)
    border.color: urgencyColor(root.notification.urgency)
    opacity: 0
    x: 24

    Component.onCompleted: {
        opacity = 1;
        x = 0;
    }

    function urgencyColor(urgency): color {
        if (urgency === NotificationUrgency.Critical)
            return Ui.Theme.danger;
        if (urgency === NotificationUrgency.Low)
            return Ui.Theme.border;
        return Ui.Theme.accent;
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

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissRequested(root.notification)
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
                radius: Ui.Theme.radiusSm
                color: Ui.Theme.surfaceSunken
                visible: !root.hasImage && !root.hasAppIcon

                Ui.UiIcon {
                    anchors.centerIn: parent
                    text: "󰂚"
                    font.pixelSize: 17
                }
            }

            Image {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                visible: root.hasImage
                source: root.imageSource
                fillMode: Image.PreserveAspectCrop
            }

            IconImage {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                visible: !root.hasImage && root.hasAppIcon
                source: visible ? Quickshell.iconPath(root.appIcon, "dialog-information") : ""
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Ui.UiText {
                    Layout.fillWidth: true
                    text: root.notification.summary
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Ui.UiText {
                    Layout.fillWidth: true
                    text: root.notification.appName
                    color: Ui.Theme.textDisabled
                    font.pixelSize: Ui.Theme.textXs
                    elide: Text.ElideRight
                    visible: root.notification.appName.length > 0
                }
            }

            Ui.UiText {
                text: "×"
                color: closeMouse.containsMouse ? Ui.Theme.textPrimary : Ui.Theme.textDisabled
                font.pixelSize: 18

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.dismissRequested(root.notification)
                }
            }
        }

        Ui.UiText {
            Layout.fillWidth: true
            text: root.notification.body
            textFormat: Text.RichText
            color: Ui.Theme.textSecondary
            font.pixelSize: Ui.Theme.textSm
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            visible: root.notification.body.length > 0
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.notification.actions.length > 0
            spacing: 6

            Item {
                Layout.fillWidth: true
            }

            Repeater {
                model: root.notification.actions

                Rectangle {
                    required property var modelData

                    Layout.preferredWidth: Math.max(actionText.implicitWidth + 18, 52)
                    Layout.preferredHeight: 26
                    radius: Ui.Theme.radiusSm
                    color: actionMouse.containsMouse ? Ui.Theme.border : Ui.Theme.surfaceActive

                    Ui.UiText {
                        id: actionText
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: Ui.Theme.textPrimary
                        font.pixelSize: Ui.Theme.textXs
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.actionRequested(parent.modelData)
                    }
                }
            }
        }
    }
}
