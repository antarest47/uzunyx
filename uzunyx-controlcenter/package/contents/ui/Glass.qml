/*
 * The glass of the task manager's buttons and the pager: a vertical gradient, a
 * glow from below, a reflection on the upper half and the 1 px border.
 */
import QtQuick

Item {
    id: glass

    property color tint: "#aeb3bf"
    // How lit it is: 0 quiet, 1 full colour.
    property real strength: 0.15
    property real radius: 8

    Behavior on strength {
        NumberAnimation { duration: 120 }
    }

    function shade(color, factor, alpha) {
        return Qt.rgba(color.r * factor, color.g * factor, color.b * factor, alpha);
    }

    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        gradient: Gradient {
            GradientStop { position: 0; color: glass.shade(glass.tint, 1, 0.30 + 0.45 * glass.strength) }
            GradientStop { position: 1; color: glass.shade(glass.tint, 0.45, 0.35 + 0.45 * glass.strength) }
        }
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * 0.45
        bottomLeftRadius: glass.radius
        bottomRightRadius: glass.radius
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: glass.shade(Qt.lighter(glass.tint, 1.5), 1, 0.15 + 0.4 * glass.strength) }
        }
    }
    Rectangle {
        x: 1
        y: 1
        width: parent.width - 2
        height: parent.height * 0.46
        topLeftRadius: Math.max(glass.radius - 1, 0)
        topRightRadius: Math.max(glass.radius - 1, 0)
        bottomLeftRadius: Math.min(3, glass.radius)
        bottomRightRadius: Math.min(3, glass.radius)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.10 + 0.24 * glass.strength) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.02 + 0.06 * glass.strength) }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15 + 0.2 * glass.strength + 0.05)
    }
}
