import QtQuick
import Quickshell.Io

Item {
    id: root

    readonly property string qrPath: "/tmp/quickshell-wifi-qr.png"
    readonly property var filteredNetworks: networks.filter(network => network.ssid.toLowerCase().includes(searchText.toLowerCase()))

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

    visible: false

    function shellQuote(value): string {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function parseNetworkLine(line): var {
        const parts = line.split(":");
        return {
            active: parts[0] === "yes",
            ssid: parts[1] ?? "",
            signal: Number(parts[2] ?? 0),
            security: parts.slice(3).join(":")
        };
    }

    function setStatus(message): void {
        statusText = message;
    }

    function refresh(rescan = false): void {
        const scan = rescan ? "yes" : "no";
        refreshProcess.exec(["sh", "-c", `nmcli -t -f WIFI radio; printf '\n---\n'; nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan ${scan}; printf '\n---\n'; nmcli -t -f NAME,TYPE connection show`]);
    }

    function toggleWifi(): void {
        commandProcess.exec(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
        root.setStatus(root.wifiEnabled ? "Disabling Wi-Fi" : "Enabling Wi-Fi");
    }

    function connect(ssid, password): void {
        if (ssid.length === 0)
            return;

        root.setStatus(`Connecting to ${ssid}`);
        const quotedSsid = root.shellQuote(ssid);
        const command = password.length > 0 ? `nmcli dev wifi connect ${quotedSsid} password ${root.shellQuote(password)}` : `nmcli connection up id ${quotedSsid} || nmcli dev wifi connect ${quotedSsid}`;
        commandProcess.exec(["sh", "-c", command]);
    }

    function disconnect(): void {
        if (root.activeSsid.length === 0)
            return;
        root.setStatus(`Disconnecting from ${root.activeSsid}`);
        commandProcess.exec(["sh", "-c", `nmcli connection down id ${root.shellQuote(root.activeSsid)}`]);
    }

    function forget(ssid): void {
        if (ssid.length === 0)
            return;
        root.setStatus(`Forgetting ${ssid}`);
        commandProcess.exec(["sh", "-c", `nmcli connection delete id ${root.shellQuote(ssid)}`]);
    }

    function showPasswordPrompt(ssid): void {
        root.selectedSsid = ssid;
        root.selectedPassword = "";
    }

    function closePasswordPrompt(): void {
        root.selectedSsid = "";
        root.selectedPassword = "";
    }

    function toggleActions(ssid): void {
        root.closePasswordPrompt();
        root.actionSsid = root.actionSsid === ssid ? "" : ssid;
    }

    function showQrCode(): void {
        if (root.activeSsid.length === 0)
            return;
        qrProcess.exec(["sh", "-c", qrScript]);
    }

    function clearQrCode(): void {
        root.qrVersion = 0;
        qrCleanupProcess.exec(["rm", "-f", root.qrPath]);
    }

    function copyPassword(): void {
        if (root.activeSsid.length === 0)
            return;
        copyPasswordProcess.exec(["sh", "-c", "nmcli dev wifi show-password | sed -n 's/^Password: //p' | head -n1 | wl-copy"]);
    }

    function signalIcon(signal): string {
        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function securityIcon(security): string {
        return security.length > 0 && security !== "--" ? "" : "";
    }

    function isRemembered(ssid): bool {
        return root.rememberedSsids.includes(ssid);
    }

    readonly property string qrScript: `
ssid=$(nmcli dev wifi show-password | sed -n 's/^SSID: //p' | head -n1)
security=$(nmcli dev wifi show-password | sed -n 's/^Security: //p' | head -n1)
password=$(nmcli dev wifi show-password | sed -n 's/^Password: //p' | head -n1)
test -n "$ssid" || exit 1
qrencode -t PNG -s 8 -m 2 -o ${root.shellQuote(root.qrPath)} "WIFI:S:$ssid;T:$security;P:$password;;"
`

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
        id: qrCleanupProcess
    }

    Process {
        id: copyPasswordProcess
        onExited: exitCode => root.setStatus(exitCode === 0 ? "Wi-Fi password copied" : "Could not copy Wi-Fi password")
    }

    Component.onCompleted: root.refresh(false)
}
