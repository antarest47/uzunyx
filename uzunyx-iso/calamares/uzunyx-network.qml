// "Conexión" page of Calamares (notesqml@network, uzunyx-network.conf), right
// after the welcome: the Wi-Fi networks, with the password in the chosen one,
// or that it's connected already. Without internet it installs all the same, so
// it informs and doesn't warn, and "Siguiente" always goes on. The welcome no
// longer checks for internet. Approved mockup of 2026-11-14.
// Calamares can't run commands from QML, and Plasma's executable data source
// crashed it on loading (ISO 0.2.2): uzunyx-calamares starts
// uzunyx-calamares-network next to it, and this page reads its state.json and
// writes request.json with XMLHttpRequest. Only QtQuick, nothing of Plasma.
import QtQuick
import QtQuick.Controls

Item {
    id: page

    readonly property color accent: "#e62967"
    readonly property color text: "#f2f2f7"
    readonly property color dim: "#c8ccd6"
    readonly property string dir: "file:///run/uzunyx-calamares-network/"
    readonly property string kora: "file:///usr/share/icons/kora/panel/16/"

    property var net: null
    // Apart, and kept while a password is being typed: a new model would
    // recreate the rows and clear it.
    property var networks: []
    property string chosen: ""
    property string connecting: ""
    property string failed: ""
    property real lastRequest: 0

    function request(data) {
        lastRequest = Date.now();
        data.id = lastRequest;
        const xhr = new XMLHttpRequest();
        xhr.open("PUT", dir + "request.json");
        xhr.send(JSON.stringify(data));
    }
    function connect(network, password) {
        connecting = network.ssid;
        failed = "";
        request({action: "connect", ssid: network.ssid, password: password});
    }
    function read() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || !xhr.responseText) {
                return;
            }
            let state = null;
            try {
                state = JSON.parse(xhr.responseText);
            } catch (e) {
                return;
            }
            net = state;
            const answer = state.answer;
            if (connecting && answer && answer.id === lastRequest) {
                connecting = "";
                if (answer.ok) {
                    chosen = "";
                } else {
                    failed = answer.ssid;
                }
            }
            if (!chosen || connecting) {
                networks = state.networks;
            }
        };
        xhr.open("GET", dir + "state.json");
        xhr.send();
    }
    function signalIcon(signal) {
        return kora + (signal >= 80 ? "network-wireless-signal-excellent-symbolic.svg"
            : signal >= 55 ? "network-wireless-signal-good-symbolic.svg"
            : signal >= 30 ? "network-wireless-signal-ok-symbolic.svg"
            : "network-wireless-signal-weak-symbolic.svg");
    }

    Timer {
        interval: 1000
        running: page.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: page.read()
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
                    property bool shown: false
                    echoMode: shown ? TextInput.Normal : TextInput.Password
                    placeholderText: "Contraseña"
                    color: page.text
                    rightPadding: 34
                    background: Rectangle {
                        radius: 6
                        color: "#0d0e12"
                        border.color: password.activeFocus ? page.accent : "#343944"
                    }
                    // Show or hide what's typed. Kora's view-hidden is the same open
                    // eye as view-visible; the crossed-out one is hint.svg.
                    Image {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        sourceSize: Qt.size(32, 32)
                        source: "file:///usr/share/icons/kora/actions/16/"
                            + (password.shown ? "hint.svg" : "view-visible.svg")
                        opacity: eye.containsMouse || password.shown ? 1 : 0.6
                        MouseArea {
                            id: eye
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: password.shown = !password.shown
                        }
                    }
                    onVisibleChanged: {
                        text = "";
                        shown = false;
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
                onClicked: page.request({action: "wifi-on"})
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
