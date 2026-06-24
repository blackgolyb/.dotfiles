import QtQuick
import Quickshell
import Quickshell.Io
import Src.Search as Search
import Src.Search.Sources as Sources
import Src.Ui as Ui

Ui.UiOverlay {
    id: root

    namespaceName: "app-launcher"
    enableBlur: true
    exclusiveKeyboard: true
    focusableWindow: true
    overlay: true
    dimOpacity: 0.28
    screen: root.anchorWindow.screen
    onDismissed: root.close()
    visible: false

    onVisibleChanged: {
        if (visible) {
            searchView.reset();
            searchView.forceSearchFocus();
        }
    }

    function open(modeName = null): void {
        const wasVisible = root.visible;
        const nextMode = modeName === undefined || modeName === "" ? null : modeName;
        if (wasVisible)
            searchView.setMode(nextMode);
        else
            searchView.mode = nextMode;

        root.visible = true;
        if (wasVisible)
            searchView.forceSearchFocus();
    }

    function close(): void {
        root.visible = false;
    }

    IpcHandler {
        target: "launcher"

        function open(): void {
            root.open();
        }

        function openWithMode(modeName: string): void {
            root.open(modeName);
        }

        function close(): void {
            root.close();
        }
    }

    Item {
        id: sourceHost
        visible: false

        Sources.AppSearchSource {
            id: appSource
            onResultsUpdated: searchView.refreshResults()
        }

        Sources.CalculatorSearchSource {
            id: calculatorSource
            onResultsUpdated: searchView.refreshResults()
        }

        Sources.WebSearchSource {
            id: webSource
            browser: "zen"
            searchEngine: "duckduckgo"
            suggestionEngine: "duckduckgo"
            onResultsUpdated: searchView.refreshResults()
        }

        Sources.ClipboardSearchSource {
            id: clipboardSource
            onResultsUpdated: searchView.refreshResults()
        }
    }

    Search.SearchView {
        id: searchView
        width: Math.min(root.width - 40, 720)
        height: Math.min(root.height - 80, 560)
        anchors.centerIn: parent
        sources: [appSource, calculatorSource, webSource, clipboardSource]
        onAccepted: root.close()
        onCloseRequested: root.close()
    }
}
