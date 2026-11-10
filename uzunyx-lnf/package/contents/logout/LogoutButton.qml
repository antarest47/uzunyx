/*
 * A button of the logout screen, like the window buttons (uzunyx-buttons): a
 * glossy black ball with a moon-like highlight and a sparkle, a white ring and
 * symbol, a red one in the shutdown button. The one in focus glows in the
 * edition's accent; the countdown goes around its ring.
 */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: button

    property string text
    property string iconName
    property bool danger: false
    // 0..1 of the countdown still to go, while it runs on this button.
    property real countdown: -1

    signal clicked()

    readonly property bool lit: activeFocus || mouse.containsMouse
    readonly property int ball: Kirigami.Units.gridUnit * 5
    readonly property color rim: danger ? "#FF5A4E" : "#ffffff"
    readonly property color rimDark: danger ? "#A3100C" : "#9a9aa2"

    implicitWidth: Kirigami.Units.gridUnit * 8
    implicitHeight: ball + label.implicitHeight + Kirigami.Units.largeSpacing * 2

    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()

    // Accent halo: wide translucent rings, no filters, as in the lock keys pill.
    Repeater {
        model: [[14, 0.10], [9, 0.20], [4, 0.45]]
        Rectangle {
            required property var modelData
            anchors.centerIn: core
            width: button.ball + modelData[0] * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: modelData[0]
            border.color: Qt.rgba(glow.r, glow.g, glow.b, modelData[1])
            opacity: button.lit ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }
        }
    }

    readonly property color glow: danger ? "#FF5A4E" : Kirigami.Theme.focusColor

    Image {
        id: core
        anchors.horizontalCenter: parent.horizontalCenter
        y: Kirigami.Units.largeSpacing
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
        width: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
        height: width
        source: button.iconName
        isMask: true
        color: button.danger ? "#ffb4ae" : "#ffffff"
    }

    // Countdown around the ring.
    Canvas {
        anchors.centerIn: core
        width: button.ball + 10
        height: width
        visible: button.countdown >= 0
        readonly property real amount: button.countdown
        onAmountChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.strokeStyle = button.glow;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - 2, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * amount);
            ctx.stroke();
        }
    }

    Text {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: core.bottom
        anchors.topMargin: Kirigami.Units.largeSpacing
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: "#ffffff"
        opacity: button.lit ? 1 : 0.75
        font: Kirigami.Theme.defaultFont
        // No mnemonics: this screen goes by arrows and Enter.
        text: button.text.replace(/&/g, "")
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
