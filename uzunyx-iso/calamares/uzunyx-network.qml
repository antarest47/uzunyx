// "Conexión" page of Calamares (notesqml@network, uzunyx-network.conf), right
// after the welcome: the Wi-Fi networks, with the password in the chosen one,
// or that it's connected already. Without internet it installs all the same, so
// it informs and doesn't warn, and "Siguiente" always goes on. The welcome no
// longer checks for internet. Approved mockup of 2026-11-14.
// Calamares has no way to run a command from QML: uzunyx-calamares-network
// runs through Plasma's executable data source.
import QtQuick
import QtQuick.Controls
import org.kde.plasma.plasma5support as P5Support

Item {
    id: page

    readonly property color accent: "#e62967"
    readonly property color text: "#f2f2f7"
    readonly property color dim: "#c8ccd6"
    readonly property string helper: "/usr/libexec/uzunyx-calamares-network"
    readonly property string kora: "file:///usr/share/icons/kora/panel/16/"

    property var net: null
    // Apart, and kept while a password is being typed: a new model would
    // recreate the rows and clear it.
    property var networks: []
    property string chosen: ""
    property string connecting: ""
    property string failed: ""

    function quote(text) {
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }
    function run(args) {
        runner.connectSource(helper + " " + args);
    }
    function connect(network, password) {
        connecting = network.ssid;
        failed = "";
        run("connect " + quote(network.ssid) + (password ? " " + quote(password) : ""));
    }
    function signalIcon(signal) {
        return kora + (signal >= 80 ? "network-wireless-signal-excellent-symbolic.svg"
            : signal >= 55 ? "network-wireless-signal-good-symbolic.svg"
            : signal >= 30 ? "network-wireless-signal-ok-symbolic.svg"
            : "network-wireless-signal-weak-symbolic.svg");
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            let out = null;
            try {
                out = JSON.parse(data.stdout.trim());
            } catch (e) {
                return;
            }
            // Changing sources inside onNewData overflows the stack: later.
            if (out.state) {
                page.net = out.state;
                if (!page.chosen || page.connecting) {
                    page.networks = out.state.networks;
                }
            } else if (out.connect !== undefined) {
                page.connecting = "";
                if (out.ok) {
                    page.chosen = "";
                } else {
                    page.failed = out.connect;
                }
                Qt.callLater(page.run, "state");
            } else if (out.wifiOn) {
                Qt.callLater(page.run, "state --rescan");
            }
        }
    }
    Timer {
        interval: 4000
        running: page.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: page.run(page.net ? "state" : "state --rescan")
    }

    Rectangle {
        anchors.fill: parent
        color: "#111318"
    }

    component Status: Rectangle {
        id: status
        property alias icon: statusIcon.source
        property alias label: statusText.text
        property bool good: false
        width: parent.width
        height: Math.max(statusText.implicitHeight, 18) + 18
        radius: 8
        color: good ? "#14201a" : "#171920"
        border.color: good ? "#2f5a40" : "#343944"
        Image {
            id: statusIcon
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            sourceSize: Qt.size(36, 36)
        }
        Text {
            id: statusText
            x: 40
            width: parent.width - 52
            anchors.verticalCenter: parent.verticalCenter
            color: status.good ? page.text : page.dim
            font.pixelSize: 13
            textFormat: Text.StyledText
            wrapMode: Text.WordWrap
        }
    }

    component Network: Rectangle {
        id: network
        required property var modelData
        readonly property bool open: page.chosen === modelData.ssid
        readonly property bool asks: open && modelData.secure && !modelData.saved && !modelData.inUse
        width: ListView.view.width
        height: column.implicitHeight + 20
        radius: 10
        color: open || modelData.inUse ? "#22151c" : mouse.containsMouse ? "#1d2028" : "#171920"
        border.color: open ? page.accent : modelData.inUse ? "#7a1537" : "#343944"
        border.width: open ? 2 : 1

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (network.modelData.inUse || page.connecting) {
                    return;
                }
                page.failed = "";
                if (network.modelData.secure && !network.modelData.saved) {
                    page.chosen = network.open ? "" : network.modelData.ssid;
                } else {
                    page.chosen = network.modelData.ssid;
                    page.connect(network.modelData, "");
                }
            }
        }
        Image {
            x: 14
            y: 12
            width: 20
            height: 20
            sourceSize: Qt.size(40, 40)
            source: page.signalIcon(network.modelData.signal)
        }
        Column {
            id: column
            x: 46
            y: 10
            width: parent.width - 60
            spacing: 2
            Text {
                color: page.text
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
                width: parent.width
                text: network.modelData.ssid
            }
            Text {
                color: network.modelData.inUse ? "#ffd6e2" : page.dim
                font.pixelSize: 12
                text: network.modelData.inUse ? "Conectado"
                    : page.connecting === network.modelData.ssid ? "Conectando…"
                    : page.failed === network.modelData.ssid ? "No se pudo conectar. Revisa la contraseña."
                    : (network.modelData.security || "Abierta") + (network.modelData.saved ? " · guardada" : "")
            }
            Row {
                visible: network.asks
                width: parent.width
                topPadding: 6
                spacing: 8
                TextField {
                    id: password
                    width: parent.width - connectButton.width - 8
                    echoMode: TextInput.Password
                    placeholderText: "Contraseña"
                    color: page.text
                    background: Rectangle {
                        radius: 6
                        color: "#0d0e12"
                        border.color: password.activeFocus ? page.accent : "#343944"
                    }
                    onVisibleChanged: {
                        text = "";
                        if (visible) {
                            forceActiveFocus();
                        }
                    }
                    onAccepted: if (text.length > 0) page.connect(network.modelData, text)
                }
                Button {
                    id: connectButton
                    text: "Conectar"
                    enabled: password.text.length > 0 && !page.connecting
                    onClicked: page.connect(network.modelData, password.text)
                    contentItem: Text {
                        text: connectButton.text
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: connectButton.enabled ? 1 : 0.5
                    }
                    background: Rectangle {
                        implicitWidth: 96
                        radius: 6
                        color: page.accent
                    }
                }
            }
        }
    }

    Column {
        id: header
        x: 22
        y: 22
        width: parent.width - 44
        spacing: 12

        Column {
            width: parent.width
            spacing: 4
            Text {
                color: page.text
                font.pixelSize: 19
                font.weight: Font.Bold
                text: "Conexión a internet"
            }
            Text {
                width: parent.width
                color: page.dim
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                text: "Con internet, el instalador baja las actualizaciones y las aplicaciones extra. "
                    + "Sin ella, Uzunyx se instala igual desde el disco."
            }
        }
        Status {
            readonly property var connected: page.net ? page.net.connected : null
            good: connected !== null && page.net.online
            icon: connected === null ? page.kora + "network-wireless-signal-none-symbolic.svg"
                : connected.type === "ethernet" ? page.kora + "network-wired-symbolic.svg"
                : page.kora + "network-wireless-signal-good-symbolic.svg"
            label: page.net === null ? "Buscando redes…"
                : connected === null ? (page.net.wifi ? "No estás conectado. Elige una red wifi o conecta un cable."
                                                       : "No estás conectado. Conecta un cable de red.")
                : !page.net.online ? "Conectado a <b>" + connected.name + "</b>, pero sin acceso a internet."
                : connected.type === "ethernet" ? "Conectado por cable. Puedes seguir."
                : "Conectado a <b>" + connected.name + "</b>. Puedes seguir."
        }
        Row {
            visible: page.net !== null && page.net.wifi && !page.net.wifiOn
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: page.dim
                font.pixelSize: 13
                text: "El wifi está apagado."
            }
            Button {
                text: "Encender wifi"
                onClicked: page.run("wifi-on")
            }
        }
    }
    ListView {
        x: 22
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        width: parent.width - 44
        clip: true
        spacing: 8
        visible: page.net !== null && page.net.wifi && page.net.wifiOn
        model: page.networks
        delegate: Network {}
        ScrollBar.vertical: ScrollBar {}
    }
}
