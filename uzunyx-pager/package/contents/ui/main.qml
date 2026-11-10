/*
 * Uzunyx Pager: a glass pill with a dot per virtual desktop, the current one a
 * longer pill in the edition's accent. Hidden while there is only one desktop,
 * except when editing the panel. Clicking a dot goes to that desktop, the wheel
 * goes through them, and hovering shows what's on it. The panel's context menu
 * adds and removes desktops.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property string domain: "plasma_applet_org.kde.plasma.pager"
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int count: desktops.numberOfDesktops
    readonly property int currentIndex: desktops.desktopIds.indexOf(desktops.currentDesktop)
    readonly property bool editing: Plasmoid.containment?.corona?.editMode ?? false
    readonly property bool shown: count > 1 || editing

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.status: shown ? PlasmaCore.Types.PassiveStatus : PlasmaCore.Types.HiddenStatus

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18ndc(root.domain, "@action:inmenu widget context menu", "Add Virtual Desktop")
            icon.name: "list-add"
            onTriggered: root.callManager("createDesktop", [new DBus.uint32(root.count), new DBus.string("")], "(us)")
        },
        PlasmaCore.Action {
            text: i18ndc(root.domain, "@action:inmenu widget context menu", "Remove Virtual Desktop")
            icon.name: "list-remove"
            enabled: root.count > 1
            onTriggered: root.callManager("removeDesktop", [new DBus.string(String(desktops.desktopIds[root.count - 1]))], "(s)")
        },
        PlasmaCore.Action {
            text: i18ndc(root.domain, "@action:inmenu widget context menu", "Configure Virtual Desktops…")
            icon.name: "preferences-desktop-virtual"
            onTriggered: executable.connectSource("kcmshell6 kcm_kwin_virtualdesktops")
        }
    ]

    TaskManager.VirtualDesktopInfo {
        id: desktops
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    function callManager(member, args, signature) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/VirtualDesktopManager",
            iface: "org.kde.KWin.VirtualDesktopManager",
            member: member,
            arguments: args,
            signature: signature,
        });
    }

    function goTo(index) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/KWin",
            iface: "org.kde.KWin",
            member: "setCurrentDesktop",
            arguments: [new DBus.int32(index + 1)],
            signature: "(i)",
        });
    }

    fullRepresentation: Item {
        id: area

        readonly property int dot: 8
        readonly property int gap: 6
        readonly property int padding: 10
        readonly property int length: root.shown
            ? padding * 2 + (root.count - 1) * (dot + gap) + dot * 2 : 0

        Layout.minimumWidth: root.vertical ? -1 : length
        Layout.preferredWidth: root.vertical ? -1 : length
        Layout.maximumWidth: root.vertical ? -1 : length
        Layout.minimumHeight: root.vertical ? length : -1
        Layout.preferredHeight: root.vertical ? length : -1
        Layout.maximumHeight: root.vertical ? length : -1
        visible: root.shown

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        readonly property color accent: Kirigami.Theme.focusColor

        // Glass pill, like the task manager's buttons.
        Item {
            id: pill
            anchors.centerIn: parent
            width: root.vertical ? 24 : parent.width
            height: root.vertical ? parent.height : 24

            Rectangle {
                anchors.fill: parent
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0.68, 0.70, 0.75, 0.30) }
                    GradientStop { position: 1; color: Qt.rgba(0.31, 0.32, 0.34, 0.35) }
                }
            }
            Rectangle {
                x: 1
                y: 1
                width: parent.width - 2
                height: parent.height * 0.46
                topLeftRadius: 7
                topRightRadius: 7
                bottomLeftRadius: 3
                bottomRightRadius: 3
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.14) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.03) }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)
            }

            Grid {
                anchors.centerIn: parent
                columns: root.vertical ? 1 : Math.max(root.count, 1)
                spacing: area.gap

                Repeater {
                    model: root.count

                    DesktopDot {
                        required property int index
                        desktopId: desktops.desktopIds[index]
                        desktopName: desktops.desktopNames[index] ?? ""
                        current: index === root.currentIndex
                        vertical: root.vertical
                        size: area.dot
                        accent: area.accent
                        onActivated: root.goTo(index)
                    }
                }
            }
        }

        WheelHandler {
            property real pending: 0
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                pending += event.angleDelta.y;
                const steps = Math.trunc(pending / 120);
                if (steps !== 0) {
                    pending -= steps * 120;
                    const next = root.currentIndex + (steps > 0 ? -1 : 1);
                    root.goTo((next + root.count) % root.count);
                }
            }
        }
    }
}
