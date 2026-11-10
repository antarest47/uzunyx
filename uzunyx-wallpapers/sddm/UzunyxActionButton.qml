/*
 * A button of the login screen, like the window buttons and the logout screen:
 * a glossy black ball with a moon-like highlight and a sparkle, and a halo in
 * the edition's accent (config.accent, from theme.conf).
 */
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.AbstractButton {
    id: button

    readonly property color glow: config.accent || "#E62967"
    readonly property bool danger: icon.name === "system-shutdown"
    readonly property color rim: danger ? "#FF5A4E" : "#ffffff"
    readonly property color rimDark: danger ? "#A3100C" : "#9a9aa2"
    readonly property int ball: Kirigami.Units.gridUnit * 3
    property int fontSize: Kirigami.Theme.defaultFont.pointSize

    implicitWidth: Math.max(ball + 28, label.implicitWidth)
    implicitHeight: ball + label.implicitHeight + Kirigami.Units.smallSpacing * 3
    opacity: enabled ? 1 : 0.4

    contentItem: Item {
        Repeater {
            model: [[10, 0.12], [6, 0.22], [3, 0.45]]
            Rectangle {
                required property var modelData
                anchors.centerIn: core
                width: button.ball + modelData[0] * 2
                height: width
                radius: width / 2
                color: "transparent"
                border.width: modelData[0]
                border.color: Qt.rgba(button.lit.r, button.lit.g, button.lit.b, modelData[1])
                visible: button.hovered || button.activeFocus
            }
        }
        Image {
            id: core
            anchors.horizontalCenter: parent.horizontalCenter
            y: Kirigami.Units.smallSpacing
            width: button.ball
            height: button.ball
            sourceSize: Qt.size(width * 2, height * 2)
            source: "data:image/svg+xml;utf8," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                <defs>
                    <radialGradient id="c" cx="50" cy="36" r="70" gradientUnits="userSpaceOnUse">
                        <stop offset="0" stop-color="#2a2e34"/><stop offset="1" stop-color="#030405"/></radialGradient>
                    <linearGradient id="r" x1="0" y1="0" x2="0" y2="100" gradientUnits="userSpaceOnUse">
                        <stop offset="0" stop-color="${button.rim}"/><stop offset="1" stop-color="${button.rimDark}"/></linearGradient>
                </defs>
                <circle cx="50" cy="50" r="47" fill="url(#c)"/>
                <ellipse cx="68" cy="20" rx="13" ry="4" transform="rotate(24 68 20)" fill="#fff" opacity="0.55"/>
                <circle cx="79" cy="31" r="1.8" fill="#fff" opacity="0.55"/>
                <path d="M24 17l1.2 4.3 4.3 1.2-4.3 1.2-1.2 4.3-1.2-4.3-4.3-1.2 4.3-1.2z" fill="#fff" opacity="0.85"/>
                <circle cx="50" cy="50" r="47" fill="none" stroke="url(#r)" stroke-width="3"/>
            </svg>`)
        }
        Kirigami.Icon {
            anchors.centerIn: core
            width: Kirigami.Units.iconSizes.smallMedium + 2
            height: width
            source: {
                const name = button.icon.name;
                // Kora has hibernate only in colour, which as a mask is a blob.
                if (name === "system-suspend-hibernate" || name === "system-hibernate") {
                    return "/usr/share/icons/breeze/actions/24/system-suspend-hibernate-symbolic.svg";
                }
                return name.endsWith("-symbolic") ? name : name + "-symbolic";
            }
            isMask: true
            color: button.danger ? "#ffb4ae" : "#ffffff"
        }
        Text {
            id: label
            anchors.top: core.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#ffffff"
            text: button.text.replace(/&(?!&)/, "")
            font.pointSize: button.fontSize
        }
    }
    background: null
    readonly property color lit: danger ? "#FF5A4E" : glow
}
