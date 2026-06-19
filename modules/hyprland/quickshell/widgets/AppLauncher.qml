import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var anchorWindow
    readonly property var applications: DesktopEntries.applications.values
    readonly property var filteredApplications: filterApplications()
    property int selectedIndex: 0
    property string query: ""

    screen: root.anchorWindow.screen
    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-app-launcher"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible) {
            root.query = "";
            root.selectedIndex = 0;
            searchInput.forceActiveFocus();
        }
    }

    onFilteredApplicationsChanged: clampSelection()

    function toggle(): void {
        root.visible = !root.visible;
    }

    function close(): void {
        root.visible = false;
    }

    function clampSelection(): void {
        if (root.selectedIndex >= root.filteredApplications.length)
            root.selectedIndex = Math.max(0, root.filteredApplications.length - 1);
    }

    function searchText(entry): string {
        return [entry.name, entry.genericName, entry.comment, entry.id, entry.keywords.join(" "), entry.categories.join(" ")].join(" ").toLowerCase();
    }

    function score(entry, needle): int {
        const name = entry.name.toLowerCase();
        const generic = entry.genericName.toLowerCase();
        const id = entry.id.toLowerCase();

        if (name === needle)
            return 0;
        if (name.startsWith(needle))
            return 1;
        if (generic.startsWith(needle) || id.startsWith(needle))
            return 2;
        return 3;
    }

    function filterApplications(): var {
        const needle = root.query.trim().toLowerCase();
        const entries = needle.length === 0 ? root.applications.slice() : root.applications.filter(entry => root.searchText(entry).includes(needle));

        return entries.sort((a, b) => {
            if (needle.length > 0) {
                const scoreDelta = root.score(a, needle) - root.score(b, needle);
                if (scoreDelta !== 0)
                    return scoreDelta;
            }

            return a.name.localeCompare(b.name);
        }).slice(0, 80);
    }

    function moveSelection(delta): void {
        if (root.filteredApplications.length === 0)
            return;

        root.selectedIndex = Math.max(0, Math.min(root.filteredApplications.length - 1, root.selectedIndex + delta));
        applicationList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function launchSelected(): void {
        if (root.filteredApplications.length === 0)
            return;

        const entry = root.filteredApplications[root.selectedIndex];
        root.close();
        entry.execute();
    }

    function deletePreviousWord(input): void {
        const text = input.text;
        let start = input.cursorPosition;
        const end = start;

        while (start > 0 && /\s/.test(text.charAt(start - 1)))
            start--;
        while (start > 0 && !/\s/.test(text.charAt(start - 1)))
            start--;

        input.text = text.slice(0, start) + text.slice(end);
        input.cursorPosition = start;
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.visible = true;
        }

        function close(): void {
            root.close();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.28

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: launcherCard
        width: Math.min(root.width - 40, 720)
        height: Math.min(root.height - 80, 560)
        anchors.centerIn: parent
        radius: 18
        color: "#2e3440"
        border.width: 1
        border.color: "#4c566a"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 12
                color: "#252b35"
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: "#88c0d0"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: ""
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 16
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        text: root.query
                        color: "#eceff4"
                        selectedTextColor: "#2e3440"
                        selectionColor: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 16
                        clip: true
                        onTextChanged: {
                            root.query = text;
                            root.selectedIndex = 0;
                            applicationList.positionViewAtBeginning();
                        }
                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                        Keys.onDownPressed: root.moveSelection(1)
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_W && event.modifiers & Qt.ControlModifier) {
                                root.deletePreviousWord(searchInput);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageDown) {
                                root.moveSelection(8);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                root.moveSelection(-8);
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            ListView {
                id: applicationList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: root.filteredApplications

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: applicationList.width
                    height: 58
                    radius: 12
                    color: index === root.selectedIndex ? "#3b4252" : mouseArea.containsMouse ? "#343b49" : "transparent"

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = parent.index
                        onClicked: {
                            root.selectedIndex = parent.index;
                            root.launchSelected();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        IconImage {
                            implicitSize: 34
                            source: modelData.icon.length > 0 ? Quickshell.iconPath(modelData.icon, "application-x-executable") : Quickshell.iconPath("application-x-executable")
                            asynchronous: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: "#eceff4"
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.comment.length > 0 ? modelData.comment : modelData.genericName
                                visible: text.length > 0
                                color: "#a9b1c1"
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.filteredApplications.length + " apps"
                color: "#7f889b"
                horizontalAlignment: Text.AlignRight
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 11
            }
        }
    }
}
