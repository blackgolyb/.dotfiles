import QtQuick
import Quickshell.Hyprland
import "../ui" as Ui

Item {
    id: root

    readonly property int itemWidth: 32
    readonly property int itemHeight: 24
    readonly property var groups: [
        {
            key: "f",
            label: "󰈹"
        },
        {
            key: "d",
            label: ""
        },
        {
            key: "s",
            label: ""
        },
        {
            key: "a",
            label: ""
        },
        {
            key: "v",
            label: "󱞁"
        },
        {
            key: "c",
            label: ""
        },
        {
            key: "x",
            label: "󰋋"
        },
        {
            key: "z",
            label: ""
        },
    ]
    readonly property var activeGroups: root.groups.map(group => {
        const workspace = root.workspaceFor(group.key);
        return {
            key: group.key,
            label: group.label,
            workspace: workspace
        };
    }).filter(group => root.isShown(group.workspace))
    readonly property int activeIndex: root.activeGroups.findIndex(group => root.isActive(group.key))

    implicitWidth: root.activeGroups.length * root.itemWidth
    implicitHeight: root.itemHeight

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
            model: root.activeGroups

            Rectangle {
                required property var modelData

                width: root.itemWidth
                height: root.itemHeight
                radius: 0
                color: Ui.Theme.transparent

                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.modelData.workspace.activate()
                }

                Ui.UiText {
                    anchors.centerIn: parent
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

        readonly property int duration: 160
        width: root.itemWidth
        height: 1.5
        radius: 1
        color: Ui.Theme.textPrimary
        visible: root.activeIndex >= 0
        x: root.activeIndex * root.itemWidth
        y: root.itemHeight - height

        Behavior on x {
            ParallelAnimation {
                NumberAnimation {
                    target: activeIndicator
                    property: "x"
                    duration: activeIndicator.duration
                    easing.type: Easing.OutCubic
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: activeIndicator
                        property: "width"
                        to: root.itemWidth * 1.2
                        duration: Math.round(activeIndicator.duration * 0.4)
                        easing.type: Easing.InOutCubic
                    }

                    NumberAnimation {
                        target: activeIndicator
                        property: "width"
                        to: root.itemWidth
                        duration: Math.round(activeIndicator.duration * 0.4)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
