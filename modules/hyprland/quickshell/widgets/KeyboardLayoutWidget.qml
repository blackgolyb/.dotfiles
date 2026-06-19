import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../ui" as Ui

Ui.UiText {
    id: root

    property string layoutText: "us"

    text: root.layoutText
    color: Ui.Theme.textPrimary
    font.pixelSize: Ui.Theme.textXl

    function normalizeLayout(layout) {
        const value = layout.trim().toLowerCase();
        if (value.includes("english"))
            return "us";
        if (value.includes("ukrainian"))
            return "ua";
        return value;
    }

    function updateLayout() {
        layoutProcess.exec(["sh", "-c", "hyprctl devices -j | jq -r 'first(.keyboards[]? | select(.main == true) | .active_keymap) // \"\" | ascii_downcase | if test(\"english\") then \"us\" elif test(\"ukrainian\") then \"ua\" else . end'"]);
    }

    Process {
        id: layoutProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const layout = root.normalizeLayout(text);
                if (layout.length > 0)
                    root.layoutText = layout;
            }
        }
    }

    Component.onCompleted: root.updateLayout()

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;

            const parts = event.parse(2);
            const layout = parts.length >= 2 ? root.normalizeLayout(parts[1]) : root.normalizeLayout(event.data.split(",").pop());
            if (layout.length > 0)
                root.layoutText = layout;
        }
    }
}
