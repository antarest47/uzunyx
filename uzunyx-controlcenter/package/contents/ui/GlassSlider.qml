/*
 * A slider in the style of the window buttons: a sunken groove, filled with the
 * edition's accent, and a glossy ball.
 */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.Slider {
    id: slider

    background: Item {
        x: slider.leftPadding
        y: slider.topPadding + (slider.availableHeight - height) / 2
        implicitWidth: Kirigami.Units.gridUnit * 8
        implicitHeight: 8
        width: slider.availableWidth
        height: 8

        Rectangle {
            anchors.fill: parent
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.25) }
            }
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
        }
        Glass {
            width: Math.max(8, slider.visualPosition * parent.width)
            height: parent.height
            radius: 4
            tint: Kirigami.Theme.focusColor
            strength: 1
        }
    }

    handle: Item {
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + (slider.availableHeight - height) / 2
        // Implicit too: the slider takes its height from them, and it only
        // takes the mouse inside that height.
        implicitWidth: 18
        implicitHeight: 18
        width: 18
        height: 18

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "#4a4e57" }
                GradientStop { position: 1; color: "#14161a" }
            }
            border.width: 1
            border.color: slider.pressed || slider.hovered ? Kirigami.Theme.focusColor : Qt.rgba(1, 1, 1, 0.4)
        }
        Rectangle {
            x: 4
            y: 2
            width: parent.width - 8
            height: parent.height * 0.4
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.5) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.03) }
            }
        }
    }
}
