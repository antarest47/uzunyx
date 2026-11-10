/*
 * The panel's button for the logout screen, like that screen's buttons: a
 * glossy black ball with a moon-like highlight, with its ring and halo in the
 * edition's accent colour, which follows the colour scheme.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: Plasmoid.title
    toolTipSubText: Plasmoid.metaData.description

    function openLogoutScreen() {
        DBus.SessionBus.asyncCall({
            service: "org.kde.LogoutPrompt",
            path: "/LogoutPrompt",
            iface: "org.kde.LogoutPrompt",
            member: "promptAll",
            arguments: [],
        });
    }

    fullRepresentation: Item {
        id: area

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        readonly property color accent: Kirigami.Theme.focusColor
        readonly property int ball: Math.round(Math.min(width, height) * 0.72)

        Layout.minimumWidth: Math.round(Kirigami.Units.iconSizes.medium * 1.2)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: Layout.minimumWidth

        Rectangle {
            anchors.centerIn: core
            width: area.ball + 8
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 4
            border.color: Qt.rgba(area.accent.r, area.accent.g, area.accent.b, 0.5)
            visible: mouse.containsMouse
        }
        Image {
            id: core
            anchors.centerIn: parent
            width: area.ball
            height: area.ball
            sourceSize: Qt.size(width * 2, height * 2)
            source: "data:image/svg+xml;utf8," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                <defs>
                    <radialGradient id="c" cx="50" cy="36" r="70" gradientUnits="userSpaceOnUse">
                        <stop offset="0" stop-color="#2a2e34"/><stop offset="1" stop-color="#030405"/></radialGradient>
                    <linearGradient id="r" x1="0" y1="0" x2="0" y2="100" gradientUnits="userSpaceOnUse">
                        <stop offset="0" stop-color="${Qt.lighter(area.accent, 1.5)}"/><stop offset="1" stop-color="${Qt.darker(area.accent, 1.7)}"/></linearGradient>
                </defs>
                <circle cx="50" cy="50" r="46" fill="url(#c)"/>
                <ellipse cx="68" cy="20" rx="13" ry="4" transform="rotate(24 68 20)" fill="#fff" opacity="0.55"/>
                <path d="M24 17l1.2 4.3 4.3 1.2-4.3 1.2-1.2 4.3-1.2-4.3-4.3-1.2 4.3-1.2z" fill="#fff" opacity="0.85"/>
                <circle cx="50" cy="50" r="46" fill="none" stroke="url(#r)" stroke-width="5"/>
            </svg>`)
        }
        Kirigami.Icon {
            anchors.centerIn: core
            width: Math.round(area.ball * 0.55)
            height: width
            source: "system-log-out-symbolic"
            isMask: true
            color: Qt.lighter(area.accent, 1.35)
            roundToIconSize: false
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.openLogoutScreen()
        }
    }
}
