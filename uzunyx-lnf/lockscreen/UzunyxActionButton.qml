/*
 * A button of the lock screen, like the window buttons and the logout screen:
 * a glossy black ball with a moon-like highlight and a sparkle, and a halo in
 * the edition's accent.
 */
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.AbstractButton {
    id: button

    readonly property color glow: Kirigami.Theme.focusColor
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
                border.color: Qt.rgba(button.glow.r, button.glow.g, button.glow.b, modelData[1])
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
            // A file: the lock screen blocks data: URLs.
            source: "ball.svg"
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
            color: "#ffffff"
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
}
