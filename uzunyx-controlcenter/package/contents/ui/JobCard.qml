/*
 * A job running (a copy, a download), on top of the control center like the timers:
 * in the accent, with its progress, pause and cancel.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Rectangle {
    id: card

    property string summary
    property string body
    property string iconName
    property int percentage: 0
    property bool suspended: false
    property bool suspendable: false
    property bool killable: false
    signal pauseClicked()
    signal cancelClicked()

    readonly property color ink: Kirigami.Theme.textColor

    implicitHeight: column.implicitHeight + Kirigami.Units.smallSpacing * 3
    radius: Kirigami.Units.cornerRadius * 2
    color: Qt.rgba(Kirigami.Theme.focusColor.r, Kirigami.Theme.focusColor.g, Kirigami.Theme.focusColor.b, 0.35)
    border.width: 1
    border.color: Qt.rgba(ink.r, ink.g, ink.b, 0.25)

    ColumnLayout {
        id: column
        anchors {
            fill: parent
            leftMargin: Kirigami.Units.smallSpacing * 3
            rightMargin: Kirigami.Units.smallSpacing
            topMargin: Kirigami.Units.smallSpacing * 1.5
            bottomMargin: Kirigami.Units.smallSpacing * 1.5
        }
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing * 2
            Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: implicitWidth
                source: card.iconName
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: card.summary
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: card.body
                    textFormat: Text.StyledText
                    opacity: 0.85
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
            PlasmaComponents.Label {
                text: card.percentage + " %"
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.ToolButton {
                visible: card.suspendable
                icon.name: card.suspended ? "media-playback-start-symbolic" : "media-playback-pause-symbolic"
                onClicked: card.pauseClicked()
                PlasmaComponents.ToolTip { text: card.suspended ? i18n("Resume") : i18n("Pause") }
            }
            PlasmaComponents.ToolButton {
                visible: card.killable
                icon.name: "dialog-close"
                onClicked: card.cancelClicked()
                PlasmaComponents.ToolTip { text: i18n("Cancel") }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Units.smallSpacing * 2
            implicitHeight: 5
            radius: height / 2
            color: Qt.rgba(card.ink.r, card.ink.g, card.ink.b, 0.15)
            Rectangle {
                width: parent.width * Math.min(100, Math.max(0, card.percentage)) / 100
                height: parent.height
                radius: height / 2
                color: card.ink
                opacity: card.suspended ? 0.5 : 1
                Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration } }
            }
        }
    }
}
