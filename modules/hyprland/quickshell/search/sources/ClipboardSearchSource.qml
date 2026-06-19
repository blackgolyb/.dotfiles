import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false

    readonly property string sourceId: "clipboard"
    readonly property string name: "Clipboard"
    readonly property string mode: sourceId
    property string query: ""
    property bool forceActiveQuery: false
    property var entries: []
    property var results: []
    signal resultsUpdated

    function active(input, forceActive = false): bool {
        return forceActive || input.trim().startsWith("clip:");
    }

    function shellQuote(value): string {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function displayText(line): string {
        return String(line).replace(/^\s*[0-9]+\s+/, "").replace(/\s+/g, " ").trim();
    }

    function setQuery(input, forceActive = false): void {
        query = input;
        forceActiveQuery = forceActive;

        if (!active(input, forceActive)) {
            results = [];
            resultsUpdated();
            return;
        }

        const needle = (forceActive ? input.trim() : input.trim().slice("clip:".length).trim()).toLowerCase();
        const filtered = needle.length === 0 ? entries : entries.filter(entry => entry.display.toLowerCase().includes(needle));

        results = filtered.slice(0, 80).map((entry, index) => ({
                    source: root,
                    sourceId: root.sourceId,
                    title: entry.display.length > 0 ? entry.display : "Clipboard item",
                    subtitle: "Clipboard history",
                    iconText: "󰅌",
                    score: index / 1000,
                    actionText: "Copy",
                    raw: entry.raw
                }));
        resultsUpdated();
    }

    function refresh(): void {
        listProcess.exec(["cliphist", "list"]);
    }

    function run(result): void {
        decodeProcess.exec(["sh", "-c", `printf '%s\n' ${root.shellQuote(result.raw)} | cliphist decode | wl-copy`]);
    }

    Process {
        id: listProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(line => line.length > 0).map(line => ({
                            raw: line,
                            display: root.displayText(line)
                        }));
                root.setQuery(root.query, root.forceActiveQuery);
            }
        }
    }

    Process {
        id: decodeProcess
    }
}
