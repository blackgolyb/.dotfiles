import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Src.Ui as Ui

Ui.UiCard {
    id: root

    property var sources: []
    property var results: []
    property int selectedIndex: 0
    property var mode: null
    property int initialRefreshAttempts: 0
    property alias query: searchField.text
    readonly property var activeSources: mode === null ? sources : sources.filter(source => sourceMode(source) === mode)
    readonly property string placeholderText: mode === null ? "Search" : `Search ${modeName()}`
    signal accepted
    signal closeRequested

    function sourceMode(source): var {
        return source.mode;
    }

    function modeName(): string {
        const source = activeSources.length > 0 ? activeSources[0] : null;
        return source !== null && source.name !== undefined ? source.name.toLowerCase() : String(mode);
    }

    function setMode(nextMode): void {
        mode = nextMode;
        reset();
    }

    function setSourceMode(source): void {
        setMode(sourceMode(source));
    }

    function reset(): void {
        searchField.text = "";
        selectedIndex = 0;
        initialRefreshAttempts = 0;
        refreshActiveSources();
        updateSources();
        initialRefreshTimer.restart();
    }

    function forceSearchFocus(): void {
        searchField.forceInputFocus();
    }

    function refreshActiveSources(): void {
        for (const source of activeSources) {
            if (source.refresh !== undefined)
                source.refresh();
        }
    }

    function updateSources(): void {
        for (const source of activeSources) {
            if (source.setQuery !== undefined)
                source.setQuery(query, mode !== null);
        }
        refreshResults();
    }

    function refreshResults(): void {
        const nextResults = [];

        for (const source of activeSources) {
            const sourceResults = source.results ?? [];
            for (const result of sourceResults)
                nextResults.push(result);
        }

        nextResults.sort((a, b) => {
            const scoreDelta = (a.score ?? 1000) - (b.score ?? 1000);
            if (scoreDelta !== 0)
                return scoreDelta;
            return String(a.title).localeCompare(String(b.title));
        });

        results = nextResults.slice(0, 80);
        clampSelection();
    }

    function clampSelection(): void {
        if (selectedIndex >= results.length)
            selectedIndex = Math.max(0, results.length - 1);
    }

    function moveSelection(delta): void {
        if (results.length === 0)
            return;

        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        resultList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function runSelected(): void {
        if (results.length === 0)
            return;

        const result = results[selectedIndex];
        accepted();
        if (result.source !== undefined && result.source.run !== undefined)
            result.source.run(result);
    }

    onQueryChanged: {
        selectedIndex = 0;
        initialRefreshTimer.stop();
        updateSources();
        resultList.positionViewAtBeginning();
    }

    Timer {
        id: initialRefreshTimer
        interval: 80
        repeat: true
        onTriggered: {
            root.initialRefreshAttempts += 1;
            root.updateSources();
            if (root.results.length > 0 || root.initialRefreshAttempts >= 5)
                stop();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Ui.Theme.spacingLg
        spacing: Ui.Theme.spacingMd

        Ui.UiSearchField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: root.placeholderText
            onAccepted: root.runSelected()
            onEscaped: root.closeRequested()
            onMoveRequested: delta => root.moveSelection(delta)
            onPageMoveRequested: delta => root.moveSelection(delta)
        }

        ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.results

            delegate: Ui.UiListItem {
                required property var modelData
                required property int index

                width: resultList.width
                height: 58
                selected: index === root.selectedIndex
                onEntered: root.selectedIndex = index
                onClicked: {
                    root.selectedIndex = index;
                    root.runSelected();
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Ui.Theme.spacingMd
                    anchors.rightMargin: Ui.Theme.spacingMd
                    spacing: Ui.Theme.spacingMd

                    IconImage {
                        visible: modelData.iconName !== undefined && modelData.iconName.length > 0
                        implicitSize: 34
                        source: visible ? Quickshell.iconPath(modelData.iconName, "application-x-executable") : ""
                        asynchronous: true
                    }

                    Ui.UiText {
                        visible: modelData.iconText !== undefined && modelData.iconText.length > 0
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.iconText ?? ""
                        color: Ui.Theme.accent
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Ui.UiText {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: Ui.Theme.textPrimary
                            elide: Text.ElideRight
                            font.pixelSize: Ui.Theme.textLg
                        }

                        Ui.UiText {
                            Layout.fillWidth: true
                            text: modelData.subtitle ?? ""
                            visible: text.length > 0
                            color: Ui.Theme.textSubtle
                            elide: Text.ElideRight
                            font.pixelSize: Ui.Theme.textSm
                        }
                    }

                    Ui.UiText {
                        visible: modelData.actionText !== undefined && modelData.actionText.length > 0
                        text: modelData.actionText ?? ""
                        color: Ui.Theme.textMuted
                        font.pixelSize: Ui.Theme.textSm
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }

        Ui.UiText {
            Layout.fillWidth: true
            text: root.results.length + " results"
            color: Ui.Theme.textMuted
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Ui.Theme.textSm
        }
    }
}
