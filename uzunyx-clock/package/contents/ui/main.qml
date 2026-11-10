/*
 * Uzunyx Clock: the time in large figures, with the minutes in the edition's
 * accent and a blinking colon, and the date below, without a box. Always 24
 * hours. Clicking it opens Plasma's calendar. Running timers (uzunyx-timer)
 * add a pill with the time left, which opens the control center: it lists them
 * to cancel.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar

PlasmoidItem {
    id: root

    property date now: new Date()
    readonly property string dateText: Qt.locale().toString(now, "ddd, d MMM").replace(/\./g, "")

    // Running timers, soonest first: {id, label, seconds, end (ms)}.
    property var timers: []
    readonly property var nextTimer: timers.length > 0 ? timers[0] : null

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
        // now is up to a second old: it only makes this update each second.
        const left = Math.max(0, Math.ceil((timer.end - Math.max(now.getTime(), Date.now())) / 1000));
        const two = n => String(n).padStart(2, "0");
        const hours = Math.floor(left / 3600);
        const minutes = Math.floor(left / 60) % 60;
        return hours > 0 ? hours + ":" + two(minutes) + ":" + two(left % 60)
            : minutes + ":" + two(left % 60);
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "preferences-system-time"
    toolTipMainText: Qt.locale().toString(now, "dddd")
    toolTipSubText: Qt.locale().toString(now, "d MMMM yyyy")

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Ajustar fecha y hora…"
            icon.name: "clock"
            onTriggered: executable.connectSource("kcmshell6 kcm_clock")
        }
    ]

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    // Listens for changes in the timers: «wait» ends with each one and starts
    // again. It only stops if the command fails, e.g. uzunyx-timer is missing.
    P5Support.DataSource {
        id: timerSource
        engine: "executable"
        Component.onCompleted: connectSource("uzunyx-timer list")
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (data["exit code"] === 0) {
                // Out of the engine's signal: starting a source again from
                // inside it overflows the JS stack.
                Qt.callLater(root.showTimers, data.stdout);
            }
        }
    }

    // The timers are listed in the control center: its pill opens it, like its
    // global shortcut does. Without it, the calendar.
    function openTimers() {
        const applets = Plasmoid.containment ? Plasmoid.containment.applets : [];
        for (let i = 0; i < applets.length; i++) {
            if (applets[i].pluginName === "org.uzunyx.controlcenter") {
                applets[i].activated();
                return;
            }
        }
        root.expanded = !root.expanded;
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.now = new Date()
    }

    compactRepresentation: MouseArea {
        id: compact

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        // The accent itself is too dark for thin figures on the panel.
        readonly property color minutes: Qt.tint(Kirigami.Theme.focusColor, Qt.rgba(1, 1, 1, 0.45))

        Layout.minimumWidth: content.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        onClicked: root.expanded = !root.expanded

        Row {
            id: content
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 2

            // The soonest timer, in the accent; "+1" if there are more.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.nextTimer !== null
                width: pill.implicitWidth + Kirigami.Units.smallSpacing * 3
                height: pill.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: height / 2
                color: Qt.rgba(Kirigami.Theme.focusColor.r, Kirigami.Theme.focusColor.g, Kirigami.Theme.focusColor.b, 0.35)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.openTimers()
                }

                Row {
                    id: pill
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: "chronometer-symbolic"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.nextTimer ? root.timeLeft(root.nextTimer) : ""
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.timers.length > 1
                        text: "+" + (root.timers.length - 1)
                        color: Kirigami.Theme.textColor
                        opacity: 0.8
                        font.pixelSize: 13
                    }
                }
            }

            Column {
                id: column
                anchors.verticalCenter: parent.verticalCenter
                spacing: -4

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter

                    Figures {
                        text: Qt.formatTime(root.now, "HH")
                    }
                    Figures {
                        text: ":"
                        opacity: root.now.getSeconds() % 2 ? 0.3 : 1
                    }
                    Figures {
                        text: Qt.formatTime(root.now, "mm")
                        color: compact.minutes
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.dateText
                    color: Kirigami.Theme.textColor
                    opacity: 0.8
                    font.pixelSize: 13
                    font.features: { "tnum": 1 }
                }
            }
        }
    }

    component Figures: Text {
        color: Kirigami.Theme.textColor
        font.pixelSize: 22
        font.weight: Font.ExtraBold
        font.features: { "tnum": 1 }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        PlasmaCalendar.MonthView {
            id: calendar
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: Kirigami.Units.smallSpacing
            }
            today: root.now
            showWeekNumbers: false
        }

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    calendar.resetToToday();
                }
            }
        }
    }
}
