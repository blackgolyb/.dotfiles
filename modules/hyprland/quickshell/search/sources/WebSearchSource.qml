import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    readonly property string sourceId: "web"
    readonly property string name: "Web"
    property string browser: "zen"
    property string searchEngine: "duckduckgo"
    property string suggestionEngine: "duckduckgo"
    property string query: ""
    property string searchTerm: ""
    property int generation: 0
    property var results: []
    signal resultsUpdated

    function active(input): bool {
        return input.trim().startsWith("?");
    }

    function setQuery(input): void {
        query = input;
        generation++;

        if (!active(input)) {
            searchTerm = "";
            suggestionsTimer.stop();
            results = [];
            resultsUpdated();
            return;
        }

        searchTerm = input.trim().slice(1).trim();
        if (searchTerm.length === 0) {
            suggestionsTimer.stop();
            results = [];
            resultsUpdated();
            return;
        }

        results = [searchResult(searchTerm)];
        resultsUpdated();
        suggestionsTimer.restart();
    }

    function searchResult(term): var {
        return {
            source: root,
            sourceId: root.sourceId,
            title: `Search DuckDuckGo for "${term}"`,
            subtitle: searchUrl(term),
            iconText: "󰖟",
            score: 0,
            actionText: browser,
            term
        };
    }

    function suggestionResult(term, index): var {
        return {
            source: root,
            sourceId: root.sourceId,
            title: term,
            subtitle: "DuckDuckGo suggestion",
            iconText: "",
            score: 10 + index / 1000,
            actionText: browser,
            term
        };
    }

    function searchUrl(term): string {
        const encoded = encodeURIComponent(term);
        if (searchEngine === "google")
            return `https://www.google.com/search?q=${encoded}`;
        return `https://duckduckgo.com/?q=${encoded}`;
    }

    function suggestionsUrl(term): string {
        const encoded = encodeURIComponent(term);
        if (suggestionEngine === "google")
            return `https://suggestqueries.google.com/complete/search?client=firefox&q=${encoded}`;
        return `https://duckduckgo.com/ac/?q=${encoded}&type=list`;
    }

    function fetchSuggestions(): void {
        const term = searchTerm;
        const requestGeneration = generation;

        if (term.length < 2)
            return;

        suggestionProcess.requestGeneration = requestGeneration;
        suggestionProcess.requestTerm = term;
        suggestionProcess.exec(["curl", "-fsSL", "--max-time", "3", suggestionsUrl(term)]);
    }

    function applySuggestions(text, requestGeneration, requestTerm): void {
        if (requestGeneration !== generation || requestTerm !== searchTerm)
            return;

        try {
            const payload = JSON.parse(text);
            let suggestions = [];

            if (suggestionEngine === "google")
                suggestions = payload[1] ?? [];
            else
                suggestions = payload.map(item => item.phrase).filter(item => item !== undefined);

            const unique = [];
            const seen = new Set([searchTerm.toLowerCase()]);
            for (const suggestion of suggestions) {
                const value = String(suggestion).trim();
                const key = value.toLowerCase();
                if (value.length === 0 || seen.has(key))
                    continue;
                seen.add(key);
                unique.push(value);
                if (unique.length >= 8)
                    break;
            }

            results = [searchResult(searchTerm)].concat(unique.map((term, index) => suggestionResult(term, index)));
            resultsUpdated();
        } catch (error) {
            results = [searchResult(searchTerm)];
            resultsUpdated();
        }
    }

    function run(result): void {
        Quickshell.execDetached([browser, searchUrl(result.term)]);
    }

    Timer {
        id: suggestionsTimer
        interval: 220
        repeat: false
        onTriggered: root.fetchSuggestions()
    }

    Process {
        id: suggestionProcess
        property int requestGeneration: 0
        property string requestTerm: ""
        stdout: StdioCollector {
            onStreamFinished: root.applySuggestions(text, suggestionProcess.requestGeneration, suggestionProcess.requestTerm)
        }
    }
}
