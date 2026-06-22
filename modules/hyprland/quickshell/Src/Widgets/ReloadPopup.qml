import QtQuick
import QtQuick.Layouts
import Quickshell
import Src.Ui as Ui

Scope {
    id: root

    property bool failed: false
    property string errorString: ""
    readonly property int duration: failed ? 10000 : 1400

    Connections {
        target: Quickshell

        function onReloadCompleted(): void {
            Quickshell.inhibitReloadPopup();
            root.failed = false;
            root.errorString = "";
            popupLoader.active = false;
            popupLoader.loading = true;
        }

        function onReloadFailed(error: string): void {
            Quickshell.inhibitReloadPopup();
            root.failed = true;
            root.errorString = error;
            popupLoader.active = false;
            popupLoader.loading = true;
        }
    }

    LazyLoader {
        id: popupLoader

        Ui.UiOverlay {
            id: popup

            implicitWidth: Math.min(contentCard.implicitWidth, 680)
            implicitHeight: contentCard.implicitHeight
            namespaceName: "reload-popup"
            enableBlur: false

            anchors {
                top: true
                right: true
            }

            margins {
                top: 44
                right: 18
            }

            Ui.UiCard {
                id: contentCard

                implicitWidth: Math.min(textColumn.implicitWidth + 58, 680)
                implicitHeight: contentColumn.implicitHeight + 28
                border.color: root.failed ? Ui.Theme.danger : Ui.Theme.success
                opacity: 0
                y: -10

                Component.onCompleted: {
                    opacity = 1;
                    y = 0;
                    dismissAnimation.start();
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    id: popupMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popupLoader.active = false
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: Ui.Theme.radiusSm
                            color: root.failed ? Ui.Theme.surfaceActive : Ui.Theme.surfaceSunken

                            Ui.UiIcon {
                                anchors.centerIn: parent
                                text: root.failed ? "󰅖" : "󰄬"
                                color: root.failed ? Ui.Theme.danger : Ui.Theme.success
                                font.pixelSize: 18
                            }
                        }

                        ColumnLayout {
                            id: textColumn
                            Layout.fillWidth: true
                            spacing: 2

                            Ui.UiText {
                                Layout.fillWidth: true
                                text: root.failed ? "Reload failed" : "Reload complete"
                                color: Ui.Theme.textPrimary
                                font.pixelSize: Ui.Theme.textLg
                                font.bold: true
                            }

                            Ui.UiText {
                                Layout.fillWidth: true
                                text: root.failed ? root.errorString : "Quickshell configuration reloaded"
                                color: root.failed ? Ui.Theme.textSecondary : Ui.Theme.textSubtle
                                font.pixelSize: Ui.Theme.textSm
                                wrapMode: Text.Wrap
                                maximumLineCount: root.failed ? 8 : 1
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: progressTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: 3
                        color: Ui.Theme.surfaceSunken

                        Rectangle {
                            id: progressBar
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: parent.radius
                            color: root.failed ? Ui.Theme.danger : Ui.Theme.success
                        }
                    }
                }

                PropertyAnimation {
                    id: dismissAnimation
                    target: progressBar
                    property: "width"
                    from: progressTrack.width
                    to: 0
                    duration: root.duration
                    paused: popupMouse.containsMouse
                    onFinished: popupLoader.active = false
                }
            }
        }
    }
}
