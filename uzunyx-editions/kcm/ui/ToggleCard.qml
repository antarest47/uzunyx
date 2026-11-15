import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// A card with a drawn preview, a title and a subtitle that is turned on or
// off (or picked, with exclusive) by clicking it; checked is bound by the
// caller, which changes it in onClicked. On: ring in the highlight color and
// a check in the corner; off: the preview dimmed.
QQC2.AbstractButton {
    id: card

    property string subtitle
    // Small icon before the subtitle (e.g. the lock: asks for the password).
    property string subtitleIcon
    property bool exclusive: false
    // Height of the preview relative to its width.
    property real previewRatio: 0.5
    default property alias preview: previewContent.data

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: Kirigami.Units.gridUnit * 9

    Accessible.role: exclusive ? Accessible.RadioButton : Accessible.CheckBox
    Accessible.name: text
    Accessible.description: subtitle
    Accessible.checkable: true
    Accessible.checked: checked

    background: Rectangle {
        radius: 8
        color: Kirigami.Theme.alternateBackgroundColor
        border.width: card.checked || card.visualFocus ? 2 : 1
        border.color: card.checked || card.visualFocus ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.textColor, card.hovered ? 0.4 : 0.15)

        Behavior on border.color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        Item {
            id: previewBox
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(width * card.previewRatio)
            opacity: card.checked ? 1 : 0.4

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }

            // Drawn content, clipped to rounded corners.
            Item {
                id: previewContent
                anchors.fill: parent
                visible: false
                layer.enabled: true
            }
            Rectangle {
                id: previewMask
                anchors.fill: parent
                radius: 5
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: previewContent
                maskEnabled: true
                maskSource: previewMask
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            text: card.text
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: card.subtitle !== ""
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Icon {
                visible: card.subtitleIcon !== ""
                source: card.subtitleIcon
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                color: Kirigami.Theme.disabledTextColor
                isMask: true
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: card.subtitle
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
            }
        }

        // A card without subtitle next to one with it: the extra height goes
        // here, not to the preview.
        Item {
            Layout.fillHeight: true
        }
    }

    // The check in the corner: filled when on, an empty ring when off.
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            margins: card.padding + Kirigami.Units.smallSpacing
        }
        width: Kirigami.Units.iconSizes.small + 2
        height: width
        radius: width / 2
        color: card.checked ? Kirigami.Theme.highlightColor : Qt.alpha("black", 0.35)
        border.width: card.checked ? 0 : 1
        border.color: Qt.alpha("white", 0.7)

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small - 4
            height: width
            visible: card.checked
            source: "checkmark"
            color: Kirigami.Theme.highlightedTextColor
            isMask: true
        }
    }
}
