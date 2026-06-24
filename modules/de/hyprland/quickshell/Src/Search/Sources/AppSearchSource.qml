import QtQuick
import Quickshell

Item {
    id: root

    visible: false

    readonly property string sourceId: "apps"
    readonly property string name: "Applications"
    readonly property string mode: sourceId
    property string query: ""
    property var results: []
    signal resultsUpdated

    function active(input, forceActive = false): bool {
        if (forceActive)
            return true;

        const trimmed = input.trim();
        return !trimmed.startsWith("=") && !trimmed.startsWith("?") && !trimmed.startsWith("clip:");
    }

    function searchText(entry): string {
        return [entry.name, entry.genericName, entry.comment, entry.id, entry.keywords.join(" "), entry.categories.join(" ")].join(" ").toLowerCase();
    }

    function score(entry, needle): int {
        const name = entry.name.toLowerCase();
        const generic = entry.genericName.toLowerCase();
        const entryId = entry.id.toLowerCase();

        if (name === needle)
            return 0;
        if (name.startsWith(needle))
            return 10;
        if (generic.startsWith(needle) || entryId.startsWith(needle))
            return 20;
        return 50;
    }

    function setQuery(input, forceActive = false): void {
        query = input;

        if (!active(input, forceActive)) {
            results = [];
            resultsUpdated();
            return;
        }

        const needle = input.trim().toLowerCase();
        const entries = needle.length === 0 ? DesktopEntries.applications.values.slice() : DesktopEntries.applications.values.filter(entry => searchText(entry).includes(needle));

        results = entries.sort((a, b) => {
            if (needle.length > 0) {
                const scoreDelta = score(a, needle) - score(b, needle);
                if (scoreDelta !== 0)
                    return scoreDelta;
            }

            return a.name.localeCompare(b.name);
        }).slice(0, 80).map((entry, index) => ({
                    source: root,
                    sourceId: root.sourceId,
                    title: entry.name,
                    subtitle: entry.comment.length > 0 ? entry.comment : entry.genericName,
                    iconName: entry.icon,
                    score: (needle.length > 0 ? score(entry, needle) : 40) + index / 1000,
                    actionText: "Open",
                    entry
                }));

        resultsUpdated();
    }

    function run(result): void {
        if (result.entry !== undefined)
            result.entry.execute();
    }
}
