/*
 * A button like the window buttons (uzunyx-buttons): a glossy black ball with a
 * moon-like highlight and a sparkle, white ring and symbol, or red when it ends
 * something. On hover, a 2 px ring outside it.
 */
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: button

    property string iconName
    property string text
    property bool danger: false
    signal clicked()

    implicitWidth: Kirigami.Units.iconSizes.medium + 4
    implicitHeight: implicitWidth

    readonly property int ball: width - 4

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: button.danger ? "#fe919d" : "#c2b6b0"
        visible: mouse.containsMouse
    }
    Image {
        id: core
        anchors.centerIn: parent
        width: button.ball
        height: button.ball
        sourceSize: Qt.size(width * 2, height * 2)
        source: "data:image/svg+xml;utf8," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
            <defs>
                <radialGradient id="c" cx="50" cy="36" r="70" gradientUnits="userSpaceOnUse">
                    <stop offset="0" stop-color="#2a2e34"/><stop offset="1" stop-color="#030405"/></radialGradient>
                <linearGradient id="r" x1="0" y1="0" x2="0" y2="100" gradientUnits="userSpaceOnUse">
                    <stop offset="0" stop-color="${button.danger ? "#FF5A4E" : "#ffffff"}"/><stop offset="1" stop-color="${button.danger ? "#A3100C" : "#8d9099"}"/></linearGradient>
            </defs>
            <circle cx="50" cy="50" r="46" fill="url(#c)"/>
            <ellipse cx="68" cy="20" rx="13" ry="4" transform="rotate(24 68 20)" fill="#fff" opacity="0.55"/>
            <path d="M24 17l1.2 4.3 4.3 1.2-4.3 1.2-1.2 4.3-1.2-4.3-4.3-1.2 4.3-1.2z" fill="#fff" opacity="0.85"/>
            <circle cx="50" cy="50" r="46" fill="none" stroke="url(#r)" stroke-width="5"/>
        </svg>`)
    }
    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(button.ball * 0.55)
        height: width
        source: button.iconName
        isMask: true
        color: button.danger ? "#ffb3ad" : "#ffffff"
        roundToIconSize: false
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
    QQC2.ToolTip.text: button.text
    QQC2.ToolTip.visible: mouse.containsMouse
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
