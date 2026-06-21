import QtQuick
import Quickshell.Hyprland
import "../ui" as Ui
import "../utils/fp.mjs" as FP

Item {
    id: root

    readonly property int itemWidth: 32
    readonly property int itemHeight: 24
    readonly property int animationDuration: 190
    readonly property var keys:   [ "f", "d", "s", "a", "v", "c", "x", "z" ]
    readonly property var labels: [ "󰈹", "", "", "", "󱞁", "", "󰋋", "" ]
    readonly property var groups: FP.range(root.keys.length)
        .map( i => ({
            key: root.keys[i],
            label: root.labels[i],
        }))
    readonly property var activeGroups: root.groups
        .map(group => ({
            key: group.key,
            label: group.label,
            workspace: root.workspaceFor(group.key),
        }))
        .filter(group => root.isShown(group.workspace))
    readonly property int activeIndex: root.activeGroups.findIndex(group => root.isActive(group.key))

    implicitWidth: root.activeGroups.length * root.itemWidth
    implicitHeight: root.itemHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    function isShown(workspace) {
        return workspace != null && (workspace.toplevels.values.length > 0 || workspace.active);
    }

    function isActive(name) {
        return Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.name === name;
    }

    function workspaceFor(key) {
        for (const workspace of Hyprland.workspaces.values) {
            if (workspace.name === key)
                return workspace;
        }
        return null;
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.groups

            Rectangle {
                required property var modelData

                readonly property var workspace: root.workspaceFor(modelData.key)
                readonly property bool shown: root.isShown(workspace)

                width: shown ? root.itemWidth : 0
                height: root.itemHeight
                radius: 0
                color: Ui.Theme.transparent
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.7
                transformOrigin: Item.Center
                clip: false

                Behavior on width {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: shown ? Easing.OutBack : Easing.InCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.shown
                    onClicked: parent.workspace.activate()
                }

                Ui.UiText {
                    width: root.itemWidth
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: parent.modelData.label + "<sup> " + parent.modelData.key + "</sup>"
                    textFormat: Text.RichText
                    color: Ui.Theme.textPrimary
                    font.pixelSize: Ui.Theme.textXl
                }
            }
        }
    }

    Rectangle {
        id: activeIndicator

        width: root.itemWidth
        height: 1.5
        radius: 1
        color: Ui.Theme.textPrimary
        visible: root.activeIndex >= 0
        x: root.activeIndex * root.itemWidth
        y: root.itemHeight - height

        Behavior on x {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
