import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../search" as Search
import "../search/sources" as Sources
import "../ui" as Ui

PanelWindow {
    id: root

    required property var anchorWindow

    screen: root.anchorWindow.screen
    visible: false
    color: Ui.Theme.transparent
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
            searchView.reset();
            searchView.forceSearchFocus();
        }
    }

    function toggle(): void {
        root.visible = !root.visible;
    }

    function close(): void {
        root.visible = false;
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
    }

    Ui.UiOverlay {
        anchors.fill: parent
        dimOpacity: 0.28
        onDismissed: root.close()

        Search.SearchView {
            id: searchView
            width: Math.min(root.width - 40, 720)
            height: Math.min(root.height - 80, 560)
            anchors.centerIn: parent
            sources: [appSource, calculatorSource, webSource]
            onAccepted: root.close()
            onCloseRequested: root.close()
        }
    }
}
