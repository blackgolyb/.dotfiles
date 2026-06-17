import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    required property var anchorWindow

    readonly property string qrPath: "/tmp/quickshell-wifi-qr.png"
    readonly property string buttonText: wifiEnabled ? "󰤥" : "󰤭"
    readonly property var filteredNetworks: networks.filter(network => network.ssid.toLowerCase().includes(searchText.toLowerCase()))

    property bool menuOpen: false
    property bool wifiEnabled: false
    property string activeSsid: ""
    property string searchText: ""
    property string selectedSsid: ""
    property string selectedPassword: ""
    property string actionSsid: ""
    property string statusText: ""
    property int qrVersion: 0
    property var networks: []
    property var rememberedSsids: []

    implicitWidth: wifiText.implicitWidth
    implicitHeight: wifiText.implicitHeight

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function parseNetworkLine(line) {
        const parts = line.split(":");
        return {
            active: parts[0] === "yes",
            ssid: parts[1] ?? "",
            signal: Number(parts[2] ?? 0),
            security: parts.slice(3).join(":")
        };
    }

    function setStatus(message) {
        statusText = message;
    }

    function refresh(rescan = false) {
        const scan = rescan ? "yes" : "no";
        refreshProcess.exec(["sh", "-c", `nmcli -t -f WIFI radio; printf '\\n---\\n'; nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan ${scan}; printf '\\n---\\n'; nmcli -t -f NAME,TYPE connection show`]);
    }

    function toggleWifi() {
        commandProcess.exec(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
        root.setStatus(root.wifiEnabled ? "Disabling Wi-Fi" : "Enabling Wi-Fi");
    }

    function connect(ssid, password) {
        if (ssid.length === 0)
            return;

        root.setStatus(`Connecting to ${ssid}`);
        const quotedSsid = root.shellQuote(ssid);
        const command = password.length > 0 ? `nmcli dev wifi connect ${quotedSsid} password ${root.shellQuote(password)}` : `nmcli connection up id ${quotedSsid} || nmcli dev wifi connect ${quotedSsid}`;
        commandProcess.exec(["sh", "-c", command]);
    }

    function disconnect() {
        if (root.activeSsid.length === 0)
            return;
        root.setStatus(`Disconnecting from ${root.activeSsid}`);
        commandProcess.exec(["sh", "-c", `nmcli connection down id ${root.shellQuote(root.activeSsid)}`]);
    }

    function forget(ssid) {
        if (ssid.length === 0)
            return;
        root.setStatus(`Forgetting ${ssid}`);
        commandProcess.exec(["sh", "-c", `nmcli connection delete id ${root.shellQuote(ssid)}`]);
    }

    function showPasswordPrompt(ssid) {
        root.selectedSsid = ssid;
        root.selectedPassword = "";
        passwordPrompt.forceActiveFocus();
    }

    function closePasswordPrompt() {
        root.selectedSsid = "";
        root.selectedPassword = "";
    }

    function connectOrPrompt(network) {
        if (network.active)
            return;
        if (network.remembered || network.security.length === 0 || network.security === "--")
            root.connect(network.ssid, "");
        else
            root.showPasswordPrompt(network.ssid);
    }

    function toggleActions(ssid) {
        root.closePasswordPrompt();
        root.actionSsid = root.actionSsid === ssid ? "" : ssid;
    }

    function showQrCode() {
        if (root.activeSsid.length === 0)
            return;
        qrProcess.exec(["sh", "-c", qrScript]);
    }

    function copyPassword() {
        if (root.activeSsid.length === 0)
            return;
        copyPasswordProcess.exec(["sh", "-c", "nmcli dev wifi show-password | sed -n 's/^Password: //p' | head -n1 | wl-copy"]);
    }

    function signalIcon(signal) {
        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function securityIcon(security) {
        return security.length > 0 && security !== "--" ? "" : "";
    }

    function isRemembered(ssid) {
        return root.rememberedSsids.includes(ssid);
    }

    readonly property string qrScript: `
ssid=$(nmcli dev wifi show-password | sed -n 's/^SSID: //p' | head -n1)
security=$(nmcli dev wifi show-password | sed -n 's/^Security: //p' | head -n1)
password=$(nmcli dev wifi show-password | sed -n 's/^Password: //p' | head -n1)
test -n "$ssid" || exit 1
qrencode -t PNG -s 8 -m 2 -o ${root.shellQuote(root.qrPath)} "WIFI:S:$ssid;T:$security;P:$password;;"
`

    Text {
        id: wifiText
        text: root.buttonText
        color: root.menuOpen ? "#ffffff" : "#c3c3c3"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 16

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.menuOpen = !root.menuOpen;
            if (root.menuOpen)
                root.refresh(false);
        }
    }

    Process {
        id: refreshProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.trim().split("\n---\n");
                const radio = (sections[0] ?? "").trim();
                const wifiLines = (sections[1] ?? "").split("\n").filter(line => line.length > 0);
                const connectionLines = (sections[2] ?? "").split("\n").filter(line => line.endsWith(":802-11-wireless"));
                const seen = new Set();
                const parsed = [];

                root.wifiEnabled = radio === "enabled";
                root.activeSsid = "";
                root.rememberedSsids = connectionLines.map(line => line.slice(0, -":802-11-wireless".length));

                for (const line of wifiLines) {
                    const network = root.parseNetworkLine(line);
                    if (network.ssid.length === 0 || seen.has(network.ssid))
                        continue;

                    seen.add(network.ssid);
                    network.remembered = root.isRemembered(network.ssid);
                    parsed.push(network);

                    if (network.active)
                        root.activeSsid = network.ssid;
                }

                root.networks = parsed.sort((a, b) => {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1;
                    if (a.remembered !== b.remembered)
                        return a.remembered ? -1 : 1;
                    return b.signal - a.signal;
                });
                if (root.statusText.length === 0)
                    root.statusText = root.wifiEnabled ? "" : "Wi-Fi is disabled";
                if (!root.networks.some(network => network.ssid === root.actionSsid))
                    root.actionSsid = "";
            }
        }
    }

    Process {
        id: commandProcess
        onExited: root.refresh(false)
    }

    Process {
        id: qrProcess
        onExited: exitCode => {
            if (exitCode === 0) {
                root.qrVersion += 1;
                root.setStatus("QR code generated");
            } else {
                root.setStatus("Could not generate Wi-Fi QR code");
            }
        }
    }

    Process {
        id: copyPasswordProcess
        onExited: exitCode => root.setStatus(exitCode === 0 ? "Wi-Fi password copied" : "Could not copy Wi-Fi password")
    }

    Component.onCompleted: root.refresh(false)

    PopupWindow {
        id: popup
        anchor.window: root.anchorWindow
        anchor.rect.x: root.anchorWindow.width - width - 84
        anchor.rect.y: root.anchorWindow.height + 8
        width: 420
        height: 500
        visible: root.menuOpen
        grabFocus: true
        color: "transparent"

        onVisibleChanged: {
            root.menuOpen = visible;
            wifiFocusGrab.active = visible;
            if (visible)
                searchInput.forceActiveFocus();
        }

        Rectangle {
            id: card
            anchors.fill: parent
            scale: root.menuOpen ? 1 : 0.96
            opacity: root.menuOpen ? 1 : 0
            radius: 16
            color: "#2e3440"
            border.width: 1
            border.color: "#4c566a"

            Behavior on scale {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.closePasswordPrompt()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: root.wifiEnabled ? "Wi-Fi" : "Wi-Fi Off"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 17
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 26
                        radius: 8
                        visible: root.wifiEnabled
                        color: refreshMouse.containsMouse ? "#434c5e" : "#3b4252"

                        Text {
                            anchors.centerIn: parent
                            text: "󰑓"
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.closePasswordPrompt();
                                root.refresh(true);
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 26
                        radius: 13
                        color: root.wifiEnabled ? "#a3be8c" : "#4c566a"

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            y: 3
                            x: root.wifiEnabled ? parent.width - width - 3 : 3
                            color: "#ffffff"

                            Behavior on x {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.closePasswordPrompt();
                                root.toggleWifi();
                            }
                        }
                    }
                }

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    visible: root.qrVersion > 0
                    cache: false
                    source: root.qrVersion > 0 ? `file://${root.qrPath}?v=${root.qrVersion}` : ""
                    fillMode: Image.PreserveAspectFit
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 9
                    color: "#252b35"
                    border.width: 1
                    border.color: searchInput.activeFocus ? "#88c0d0" : "#3b4252"

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        selectionColor: "#5e81ac"
                        selectedTextColor: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 13
                        clip: true
                        text: root.searchText
                        onActiveFocusChanged: {
                            if (activeFocus)
                                root.closePasswordPrompt();
                        }
                        onTextChanged: root.searchText = text
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        visible: searchInput.text.length === 0 && !searchInput.activeFocus
                        text: "Search networks"
                        color: "#6f7787"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 9
                    color: "#252b35"
                    visible: root.selectedSsid.length > 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 8

                        Text {
                            text: root.selectedSsid
                            color: "#ffffff"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.preferredWidth: 110
                        }

                        TextInput {
                            id: passwordPrompt
                            Layout.fillWidth: true
                            text: root.selectedPassword
                            echoMode: TextInput.Password
                            color: "#ffffff"
                            selectionColor: "#5e81ac"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 12
                            clip: true
                            onTextChanged: root.selectedPassword = text
                            onAccepted: root.connect(root.selectedSsid, root.selectedPassword)
                            Keys.onEscapePressed: root.closePasswordPrompt()
                        }

                        SmallButton {
                            label: "Connect"
                            onClicked: root.connect(root.selectedSsid, root.selectedPassword)
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: root.filteredNetworks

                    delegate: Rectangle {
                        id: networkRow

                        required property var modelData

                        width: ListView.view.width
                        height: root.actionSsid === modelData.ssid ? 76 : 42
                        radius: 10
                        color: networkMouse.containsMouse ? "#3b4252" : "#252b35"

                        Behavior on height {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        RowLayout {
                            z: 1
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            height: 42
                            spacing: 8

                            Text {
                                text: root.signalIcon(networkRow.modelData.signal)
                                color: "#ffffff"
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: networkRow.modelData.ssid
                                    color: "#ffffff"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: `${networkRow.modelData.signal}% ${root.securityIcon(networkRow.modelData.security)} ${networkRow.modelData.remembered ? "remembered" : networkRow.modelData.security}`
                                    color: "#8f98aa"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: networkRow.modelData.active ? "●" : ""
                                color: "#a3be8c"
                                font.pixelSize: 12
                            }

                            SmallButton {
                                subtle: true
                                label: "⋮"
                                onClicked: root.toggleActions(networkRow.modelData.ssid)
                            }
                        }

                        RowLayout {
                            z: 1
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 42
                            anchors.leftMargin: 38
                            anchors.rightMargin: 8
                            height: 30
                            spacing: 8
                            visible: root.actionSsid === networkRow.modelData.ssid
                            opacity: visible ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            SmallButton {
                                visible: !networkRow.modelData.active
                                label: "Connect"
                                onClicked: {
                                    root.actionSsid = "";
                                    root.closePasswordPrompt();
                                    root.connectOrPrompt(networkRow.modelData);
                                }
                            }

                            SmallButton {
                                visible: networkRow.modelData.active
                                label: "QR"
                                onClicked: {
                                    root.closePasswordPrompt();
                                    root.showQrCode();
                                }
                            }

                            SmallButton {
                                visible: networkRow.modelData.active
                                label: "Copy password"
                                onClicked: {
                                    root.closePasswordPrompt();
                                    root.copyPassword();
                                }
                            }

                            SmallButton {
                                visible: networkRow.modelData.active
                                label: "Disconnect"
                                onClicked: {
                                    root.actionSsid = "";
                                    root.closePasswordPrompt();
                                    root.disconnect();
                                }
                            }

                            SmallButton {
                                visible: networkRow.modelData.remembered
                                label: "Forget"
                                onClicked: {
                                    root.actionSsid = "";
                                    root.closePasswordPrompt();
                                    root.forget(networkRow.modelData.ssid);
                                }
                            }
                        }

                        MouseArea {
                            id: networkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                root.closePasswordPrompt();
                                root.connectOrPrompt(networkRow.modelData);
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.statusText
                    color: "#8f98aa"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: wifiFocusGrab
        windows: [popup]
        onCleared: root.menuOpen = false
    }

    component SmallButton: Rectangle {
        id: button

        required property string label
        property bool subtle: false
        signal clicked

        Layout.preferredWidth: button.subtle ? 24 : Math.max(42, labelText.implicitWidth + 16)
        Layout.preferredHeight: 26
        radius: 8
        color: button.subtle ? (buttonMouse.containsMouse ? "#343b49" : "transparent") : (buttonMouse.containsMouse ? "#4c566a" : "#3b4252")

        Text {
            id: labelText
            anchors.centerIn: parent
            text: button.label
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 11
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }
}
