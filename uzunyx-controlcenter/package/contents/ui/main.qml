/*
 * Control center, in the manner of GNOME's: a pill in the panel with network,
 * volume and battery, next to the lock keys, opens the sliders, the toggles, the player and the session
 * actions, with the running timers on top. It reuses Plasma's own modules; the normal and focus modes and the
 * tiling are the uzunyx-mode and uzunyx-tiling commands.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.battery as PlasmaBattery
import org.kde.plasma.private.bluetooth as PlasmaBt
import org.kde.plasma.private.brightnesscontrolplugin as Brightness
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.systemtray as SystemTray
import org.kde.plasma.private.sessions as Sessions
import org.kde.plasma.private.volume as PlasmaPa

PlasmoidItem {
    id: root

    // Normal and focus modes, tiling: from the commands, also for changes elsewhere.
    property string layoutMode: "normal"
    property string tiling: "off"
    readonly property var tilingNames: ({ off: i18n("No tiling"), stack: i18n("Main and stack"), spiral: i18n("Spiral") })
    readonly property var tilingOrder: ["off", "stack", "spiral"]

    readonly property var sink: PlasmaPa.PreferredDevice.sink
    readonly property int normalVolume: PlasmaPa.PulseAudio.NormalVolume
    readonly property int volumePercent: sink ? Math.round(sink.volume / normalVolume * 100) : 0
    readonly property bool muted: sink ? sink.muted : true

    readonly property var battery: power.data["Battery"] || {}
    readonly property bool hasBattery: battery["Has Battery"] === true
    readonly property int batteryPercent: battery["Percent"] || 0
    readonly property bool charging: battery["State"] === "Charging" || battery["State"] === "FullyCharged"
    // With a charger plugged in always green, also if the charge limit stops it charging.
    readonly property color batteryColor: batteryModel.pluggedIn ? "#4cd964"
        : batteryPercent < 20 ? "#ff3b30"
        : batteryPercent < 30 ? "#ffcc00" : Kirigami.Theme.textColor
    // Low on battery: the pill's background beats, the lock keys stay on top as they are.
    readonly property bool batteryLow: hasBattery && !batteryModel.pluggedIn && batteryPercent < 20
    // The model reports the charger as it starts up, which is no plugging in.
    property bool batteryKnown: false
    Timer {
        interval: 3000
        running: true
        onTriggered: root.batteryKnown = true
    }
    readonly property string batteryState: {
        const name = batteryNames[battery["State"]];
        return name ? i18nd("plasma_applet_org.kde.plasma.battery", name) : "";
    }
    readonly property var batteryNames: ({
        Charging: "Charging", Discharging: "Discharging", FullyCharged: "Fully Charged", NoCharge: "Not Charging"
    })

    readonly property bool wifiOn: enabledConnections.wirelessEnabled
    readonly property bool bluetoothOn: !BluezQt.Manager.bluetoothBlocked && BluezQt.Manager.bluetoothOperational
    // The pill shows Bluetooth only while a device is connected.
    readonly property bool bluetoothConnected: bluetoothOn && BluezQt.Manager.connectedDevices.length > 0
    readonly property bool dndOn: {
        const until = notificationSettings.notificationsInhibitedUntil;
        return until !== undefined && !isNaN(until) && until.getTime() > now.getTime();
    }
    property date now: new Date()
    // What the popup shows: main, wifi, bluetooth or audio.
    property string page: "main"
    property string menuSource: ""
    property string menuTitle: ""
    // An app in the background asks for attention: the pill says so.
    readonly property bool attention: {
        for (let i = 0; i < attentionWatcher.count; i++) {
            const item = attentionWatcher.objectAt(i);
            if (item && item.wants) {
                return true;
            }
        }
        return false;
    }
    onExpandedChanged: isExpanded => {
        if (!isExpanded) {
            page = "main";
        }
    }
    // Running timers (uzunyx-timer), soonest first: {id, label, seconds, end (ms)}.
    // They go on top, in the accent like the clock's pill in the panel.
    property var timers: []
    property date timerNow: new Date()

    function showTimers(json) {
        try {
            timers = JSON.parse(json).sort((a, b) => a.end - b.end);
        } catch (e) {
            timers = [];
        }
        timerSource.connectSource("uzunyx-timer wait");
    }

    // 4:32, or 1:04:32 with hours.
    function timeLeft(timer) {
        const left = Math.max(0, Math.ceil((timer.end - Math.max(timerNow.getTime(), Date.now())) / 1000));
        const two = n => String(n).padStart(2, "0");
        const hours = Math.floor(left / 3600);
        const minutes = Math.floor(left / 60) % 60;
        return hours > 0 ? hours + ":" + two(minutes) + ":" + two(left % 60)
            : minutes + ":" + two(left % 60);
    }

    // Whether KWin's night light is set up and running: it has no QML for that.
    property bool nightEnabled: false
    property bool nightRunning: false
    // The Wi-Fi connection's name. NetworkStatus only has a translated sentence.
    property string networkName: ""
    // The devices, from nmcli: a computer without Wi-Fi shows its cable instead.
    property bool hasWifi: true
    property bool wifiConnected: false
    property bool hasWired: false
    property bool wiredOn: false
    property string wiredName: ""
    // The pill shows one: Wi-Fi while it is connected, else the cable if it is.
    readonly property string networkIcon: wifiConnected ? "network-wireless-symbolic"
        : wiredOn ? "network-wired-symbolic"
        : hasWifi ? (wifiOn ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic")
        : hasWired ? "network-wired-disconnected-symbolic" : ""

    readonly property string volumeIcon: muted || volumePercent === 0 ? "audio-volume-muted-symbolic"
        : volumePercent < 34 ? "audio-volume-low-symbolic"
        : volumePercent < 67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic"
    readonly property string batteryIcon: "battery-" + String(Math.round(batteryPercent / 10) * 10).padStart(3, "0")
        + (charging ? "-charging" : "") + "-symbolic"

    toolTipMainText: Plasmoid.title
    toolTipSubText: hasBattery ? batteryPercent + " %" : ""
    Plasmoid.icon: "preferences-system"

    readonly property string nightQuery: "n=org.kde.KWin.NightLight; p='qdbus6 org.kde.KWin /org/kde/KWin/NightLight org.freedesktop.DBus.Properties.Get'; echo night=$($p $n enabled),$($p $n running)"

    readonly property string wifiQuery: "echo net=; nmcli -t -f TYPE,STATE,CONNECTION device"

    // Plasma's tray stays out of sight: the notifications live in it, and it holds
    // the widgets we have no controls for, which open in the "more" page. The panel
    // leaves out a widget with hidden status (not while editing it), and the tray
    // resets its status now and then, so hide it again each time.
    property var tray: null
    function findTray() {
        const applets = Plasmoid.containment ? Plasmoid.containment.applets : [];
        for (let i = 0; i < applets.length; i++) {
            if (applets[i].pluginName === "org.kde.plasma.systemtray") {
                tray = applets[i];
                hideTray();
                return;
            }
        }
    }
    function hideTray() {
        if (tray && tray.status !== PlasmaCore.Types.HiddenStatus) {
            tray.status = PlasmaCore.Types.HiddenStatus;
        }
    }
    // The tray has no place of its own in the panel: its settings choose which widgets
    // show up in "more", and are reached from here.
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Configure available widgets…")
            icon.name: "configure-symbolic"
            enabled: root.tray !== null
            onTriggered: root.tray.internalAction("configure").trigger()
        }
    ]
    Component.onCompleted: findTray()
    Connections {
        target: root.tray
        function onStatusChanged() {
            root.hideTray();
        }
    }
    Connections {
        target: Plasmoid.containment
        function onAppletAdded() {
            root.findTray();
        }
    }

    // Lines of «type:state:connection»; nmcli escapes colons in names as «\:».
    function readDevices(lines) {
        let wifi = false, wifiName = "", wired = false, wiredName = "";
        for (const line of lines) {
            const fields = line.split(":");
            const name = fields.slice(2).join(":").replace(/\\:/g, ":");
            const connected = fields[1].indexOf("connected") === 0;
            if (fields[0] === "wifi") {
                wifi = true;
                if (connected && !wifiName) {
                    wifiName = name;
                }
            } else if (fields[0] === "ethernet") {
                wired = true;
                if (connected && !wiredName) {
                    wiredName = name;
                }
            }
        }
        hasWifi = wifi;
        wifiConnected = wifiName !== "";
        networkName = wifiName;
        hasWired = wired;
        wiredOn = wiredName !== "";
        root.wiredName = wiredName;
    }
    function run(command) {
        runner.connectSource(command);
    }
    function toggleBluetooth() {
        const off = bluetoothOn;
        BluezQt.Manager.bluetoothBlocked = off;
        const adapters = BluezQt.Manager.adapters;
        for (let i = 0; i < adapters.length; i++) {
            adapters[i].powered = !off;
        }
    }
    function toggleDnd() {
        // A year is "until I turn it off". A past date ends it.
        notificationSettings.notificationsInhibitedUntil = new Date(dndOn ? 0 : Date.now() + 365 * 86400000);
        notificationSettings.save();
        now = new Date();
    }

    PlasmaNM.Handler { id: networkHandler }
    PlasmaNM.EnabledConnections { id: enabledConnections }
    PlasmaNM.NetworkStatus {
        onActiveConnectionsChanged: root.run(root.wifiQuery)
    }
    Brightness.ScreenBrightnessControl { id: screenBrightness; isSilent: false }
    readonly property var nightLight: Brightness.NightLightInhibitor
    Mpris.Mpris2Model { id: players }
    NotificationManager.Settings { id: notificationSettings }
    Sessions.SessionManagement { id: session }
    Helper { id: helperRunner }
    SystemTray.StatusNotifierModel { id: trayModel }
    Instantiator {
        id: attentionWatcher
        model: trayModel
        delegate: QtObject {
            required property var model
            readonly property bool wants: model.Status === 3
        }
    }

    PlasmaBattery.BatteryControlModel {
        id: batteryModel
    }
    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery"]
        interval: 0
    }
    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => {
            const out = data.stdout.trim();
            if (out.indexOf("net=") === 0) {
                root.readDevices(out.split("\n").slice(1));
            } else if (out.indexOf("night=") === 0) {
                root.nightEnabled = out.indexOf("night=true") === 0;
                root.nightRunning = out.endsWith(",true");
            } else if (out === "normal" || out === "focus") {
                root.layoutMode = out;
            } else if (root.tilingOrder.indexOf(out) >= 0) {
                root.tiling = out;
            }
            disconnectSource(source);
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = new Date();
            root.run("uzunyx-mode status");
            root.run("uzunyx-tiling status");
            root.run(root.nightQuery);
            root.run(root.wifiQuery);
        }
    }

    // Listens for changes in the timers, as the clock does: «wait» ends with each
    // one and starts again. It only stops if the command fails (no uzunyx-timer).
    P5Support.DataSource {
        id: timerSource
        engine: "executable"
        Component.onCompleted: connectSource("uzunyx-timer list")
        onNewData: (source, data) => {
            disconnectSource(source);
            if (data["exit code"] === 0) {
                // Out of the engine's signal: starting a source again from
                // inside it overflows the JS stack.
                Qt.callLater(root.showTimers, data.stdout);
            }
        }
    }
    Timer {
        running: root.expanded && root.timers.length > 0
        repeat: true
        interval: 1000
        triggeredOnStart: true
        onTriggered: root.timerNow = new Date()
    }

    component PillIcon: Kirigami.Icon {
        implicitWidth: Kirigami.Units.iconSizes.small
        implicitHeight: implicitWidth
        isMask: true
        color: Kirigami.Theme.textColor
    }

    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: pill.implicitWidth
        Layout.preferredWidth: pill.implicitWidth
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Item {
            id: pill
            anchors.centerIn: parent
            height: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing * 3
            implicitWidth: row.implicitWidth + Kirigami.Units.largeSpacing * 2
            width: implicitWidth

            Glass {
                anchors.fill: parent
                radius: height / 2
                tint: root.expanded ? Kirigami.Theme.focusColor : "#aeb3bf"
                strength: root.expanded ? 0.7 : compact.containsMouse ? 0.4 : 0.15
            }
            Glass {
                anchors.fill: parent
                radius: height / 2
                tint: "#ff1a0a"
                strength: 0.7
                visible: root.batteryLow
                SequentialAnimation on opacity {
                    running: root.batteryLow
                    loops: Animation.Infinite
                    NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
                }
            }

            // One beat when a charger is plugged in, whatever the charge.
            Glass {
                anchors.fill: parent
                radius: height / 2
                tint: "#4cd964"
                strength: 0.7
                opacity: 0
                SequentialAnimation on opacity {
                    id: chargerBeat
                    running: false
                    NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
                }
                Connections {
                    target: batteryModel
                    function onPluggedInChanged() {
                        if (batteryModel.pluggedIn && root.batteryKnown) {
                            chargerBeat.restart();
                        }
                    }
                }
            }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 2
                LockKeys {}
                Rectangle {
                    visible: root.attention
                    implicitWidth: Kirigami.Units.smallSpacing * 2
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: "#ff1a0a"
                }
                PillIcon { visible: root.networkIcon !== ""; source: root.networkIcon }
                PillIcon { visible: root.bluetoothConnected; source: "bluetooth-active-symbolic" }
                PillIcon { source: root.volumeIcon }
                // Red on the red beat can't be read: orange, chosen by the user.
                // Kora's, with its outline on whole pixels: the theme's is a dim
                // smear next to the volume icon (gen-battery-icons.py).
                PillIcon {
                    visible: root.hasBattery
                    source: Qt.resolvedUrl("../icons/" + root.batteryIcon.replace("-symbolic", "") + ".svg")
                    color: root.batteryLow ? "#ff9500" : root.batteryColor
                }
                PlasmaComponents.Label {
                    id: batteryFigure
                    visible: root.hasBattery
                    text: root.batteryPercent + "%"
                    color: root.batteryLow ? "#ff9500" : root.batteryColor
                    font.weight: Font.Bold
                    // Centered by the ink of the figures, not by the font's box:
                    // Nunito leaves more room above than below.
                    transform: Translate {
                        y: Math.round(batteryFigure.height / 2 - (batteryFigure.baselineOffset
                            + batteryInk.tightBoundingRect.y + batteryInk.tightBoundingRect.height / 2))
                    }
                    TextMetrics {
                        id: batteryInk
                        font: batteryFigure.font
                        text: batteryFigure.text
                    }
                }
            }
        }
    }

    fullRepresentation: Item {
        readonly property int margin: Kirigami.Units.smallSpacing * 2
        Layout.minimumWidth: Kirigami.Units.gridUnit * 21 + margin * 2
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21 + margin * 2
        readonly property int pageHeight: root.page === "main" ? content.implicitHeight : Kirigami.Units.gridUnit * 21
        Layout.minimumHeight: pageHeight + margin * 2
        Layout.preferredHeight: pageHeight + margin * 2

    // The lists only exist while open: they scan and watch devices.
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "battery"
        sourceComponent: BatteryPage {
            batteries: batteryModel
            percent: root.batteryPercent
            stateName: root.batteryState
            iconName: root.batteryIcon
            tint: root.batteryColor
            onBack: root.page = "main"
            onSettings: { root.expanded = false; root.run("systemsettings kcm_powerdevilprofilesconfig"); }
            onEnergyInfo: { root.expanded = false; root.run("kinfocenter kcm_energyinfo"); }
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "wifi"
        sourceComponent: WifiPage {
            handler: networkHandler
            onBack: root.page = "main"
            onSettings: { root.expanded = false; root.run("systemsettings kcm_networkmanagement"); }
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "bluetooth"
        sourceComponent: BluetoothPage {
            onBack: root.page = "main"
            onAddDevice: { root.expanded = false; PlasmaBt.LaunchApp.launchWizard(); }
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "traymenu"
        sourceComponent: TrayMenuPage {
            source: root.menuSource
            appTitle: root.menuTitle
            helper: helperRunner
            onDone: root.page = "main"
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "more"
        sourceComponent: TrayWidgetsPage {
            tray: root.tray
            onDone: root.page = "main"
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "clipboard"
        sourceComponent: ClipboardPage {
            onBack: root.page = "main"
            onDone: root.page = "main"
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "usb"
        sourceComponent: UsbPage {
            helper: helperRunner
            onBack: root.page = "main"
            onOpen: folder => { root.expanded = false; Qt.openUrlExternally("file://" + folder); }
        }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: parent.margin
        active: root.page === "audio"
        sourceComponent: AudioPage {
            onBack: root.page = "main"
        }
    }

    ColumnLayout {
        id: content
        visible: root.page === "main"
        anchors.fill: parent
        anchors.margins: parent.margin
        spacing: Kirigami.Units.smallSpacing * 2

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.timers.length > 0
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: root.timers

                Rectangle {
                    id: timerPill
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: timerRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                    radius: height / 2
                    color: Qt.rgba(Kirigami.Theme.focusColor.r, Kirigami.Theme.focusColor.g, Kirigami.Theme.focusColor.b, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)

                    RowLayout {
                        id: timerRow
                        anchors {
                            fill: parent
                            leftMargin: Kirigami.Units.smallSpacing * 3
                            rightMargin: Kirigami.Units.smallSpacing
                        }
                        spacing: Kirigami.Units.smallSpacing * 2

                        PillIcon {
                            source: "chronometer-symbolic"
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: timerPill.modelData.label || "Temporizador"
                        }
                        PlasmaComponents.Label {
                            text: root.timeLeft(timerPill.modelData)
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            font.features: { "tnum": 1 }
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: "dialog-close"
                            text: "Cancelar"
                            display: PlasmaComponents.AbstractButton.IconOnly
                            PlasmaComponents.ToolTip.text: text
                            PlasmaComponents.ToolTip.visible: hovered
                            onClicked: root.run("uzunyx-timer cancel " + timerPill.modelData.id)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: root.sink !== null
            PlasmaComponents.ToolButton {
                icon.name: root.volumeIcon
                onClicked: root.sink.muted = !root.sink.muted
            }
            GlassSlider {
                Layout.fillWidth: true
                from: 0
                to: root.normalVolume
                stepSize: root.normalVolume / 100
                value: root.sink ? root.sink.volume : 0
                onMoved: root.sink.volume = value
            }
            PlasmaComponents.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2
                horizontalAlignment: Text.AlignRight
                text: root.volumePercent + "%"
            }
            PlasmaComponents.ToolButton {
                icon.name: "go-next-symbolic"
                onClicked: root.page = "audio"
                PlasmaComponents.ToolTip { text: i18n("Sound devices") }
            }
        }

        Repeater {
            model: screenBrightness.displays
            delegate: RowLayout {
                required property string displayName
                required property int brightness
                required property int maxBrightness
                Layout.fillWidth: true
                PlasmaComponents.ToolButton {
                    icon.name: "brightness-high-symbolic"
                    enabled: false
                }
                GlassSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: parent.maxBrightness
                    value: parent.brightness
                    onMoved: screenBrightness.setBrightness(parent.displayName, Math.round(value))
                }
                PlasmaComponents.Label {
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 2
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(parent.brightness / parent.maxBrightness * 100) + "%"
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Kirigami.Units.smallSpacing * 2
            columnSpacing: Kirigami.Units.smallSpacing * 2

            Tile {
                visible: root.hasWifi
                iconName: "network-wireless-symbolic"
                title: i18n("Wi-Fi")
                subtitle: root.wifiOn ? root.networkName : i18n("Off")
                on: root.wifiOn
                more: true
                onClicked: networkHandler.enableWireless(!root.wifiOn)
                onMoreClicked: root.page = "wifi"
            }
            // The cable: alone without Wi-Fi, and next to it while plugged in.
            Tile {
                visible: root.hasWired && (root.wiredOn || !root.hasWifi)
                iconName: root.wiredOn ? "network-wired-symbolic" : "network-wired-disconnected-symbolic"
                title: i18n("Wired")
                subtitle: root.wiredOn ? root.wiredName : i18n("Disconnected")
                on: root.wiredOn
                onClicked: root.run("systemsettings kcm_networkmanagement")
            }
            Tile {
                iconName: "network-bluetooth-symbolic"
                title: i18n("Bluetooth")
                subtitle: root.bluetoothOn ? "" : i18n("Off")
                on: root.bluetoothOn
                more: true
                onClicked: root.toggleBluetooth()
                onMoreClicked: root.page = "bluetooth"
            }
            Tile {
                iconName: "view-fullscreen-symbolic"
                title: i18n("Focus")
                subtitle: root.layoutMode === "focus" ? i18n("On") : i18n("Normal")
                on: root.layoutMode === "focus"
                onClicked: {
                    root.layoutMode = root.layoutMode === "focus" ? "normal" : "focus";
                    root.run("uzunyx-mode " + root.layoutMode);
                }
            }
            Tile {
                layout: root.tiling
                title: i18n("Tiling")
                subtitle: root.tilingNames[root.tiling]
                on: root.tiling !== "off"
                onClicked: {
                    const next = root.tilingOrder[(root.tilingOrder.indexOf(root.tiling) + 1) % root.tilingOrder.length];
                    root.tiling = next;
                    root.run("uzunyx-tiling " + next);
                }
            }
            Tile {
                iconName: "notifications-disabled-symbolic"
                title: i18n("Do not disturb")
                on: root.dndOn
                onClicked: root.toggleDnd()
            }
            Tile {
                iconName: "edit-paste-symbolic"
                title: i18n("Clipboard")
                onClicked: root.page = "clipboard"
            }
            Tile {
                iconName: "drive-removable-media-usb-symbolic"
                title: i18n("Devices")
                onClicked: root.page = "usb"
            }
            Tile {
                iconName: "night-light-symbolic"
                title: i18n("Night light")
                subtitle: root.nightEnabled ? "" : i18n("Not set up")
                on: root.nightEnabled && root.nightRunning && !root.nightLight.inhibited
                onClicked: {
                    if (root.nightEnabled) {
                        root.nightLight.toggleInhibition();
                    } else {
                        root.expanded = false;
                        root.run("systemsettings kcm_nightlight");
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            visible: players.currentPlayer !== null && players.currentPlayer !== undefined
            implicitHeight: playerRow.implicitHeight + Kirigami.Units.smallSpacing * 2

            Glass {
                anchors.fill: parent
                strength: 0.1
            }

            RowLayout {
                id: playerRow
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    text: players.currentPlayer?.track ?? ""
                    elide: Text.ElideRight
                }
                PlasmaComponents.ToolButton {
                    icon.name: "media-skip-backward-symbolic"
                    enabled: players.currentPlayer?.canGoPrevious ?? false
                    onClicked: players.currentPlayer.Previous()
                }
                PlasmaComponents.ToolButton {
                    icon.name: players.currentPlayer?.playbackStatus === Mpris.PlaybackStatus.Playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                    onClicked: players.currentPlayer.PlayPause()
                }
                PlasmaComponents.ToolButton {
                    icon.name: "media-skip-forward-symbolic"
                    enabled: players.currentPlayer?.canGoNext ?? false
                    onClicked: players.currentPlayer.Next()
                }
            }
        }

        TrayApps {
            Layout.fillWidth: true
            model: trayModel
            onMenuRequested: (source, title) => {
                root.menuSource = source;
                root.menuTitle = title;
                root.page = "traymenu";
            }
            onMore: root.page = "more"
            onActivated: source => {
                root.expanded = false;
                const parts = source.split("/");
                helperRunner.call(["tray-activate", parts[0], "/" + parts.slice(1).join("/")], () => {});
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
                implicitHeight: footerBattery.implicitHeight
                RowLayout {
                    id: footerBattery
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.hasBattery
                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: implicitWidth
                        source: root.batteryIcon
                        isMask: true
                        color: root.batteryColor
                    }
                    PlasmaComponents.Label {
                        text: root.batteryPercent + " %"
                        color: root.batteryColor
                    }
                }
                MouseArea {
                    anchors.fill: footerBattery
                    enabled: root.hasBattery
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.page = "battery"
                }
            }
            BallButton {
                iconName: "configure-symbolic"
                text: i18n("System settings")
                onClicked: { root.expanded = false; root.run("systemsettings"); }
            }
            BallButton {
                iconName: "system-lock-screen-symbolic"
                text: i18n("Lock")
                onClicked: { root.expanded = false; session.lock(); }
            }
            BallButton {
                iconName: "system-shutdown-symbolic"
                text: i18n("Leave…")
                danger: true
                onClicked: { root.expanded = false; session.requestLogoutPrompt(); }
            }
        }
    }
    }
}
