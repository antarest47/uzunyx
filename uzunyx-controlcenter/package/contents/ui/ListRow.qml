/*
 * A row of a list in the control center: glass, in the accent when current.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: row

    property var iconSource
    property string title
    property string subtitle
    property bool current: false
    // Icons of apps keep their colours.
    property bool monochrome: true
    signal clicked()
    default property alias trailing: extra.data

    readonly property color ink: !current ? Kirigami.Theme.textColor
        : Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.focusColor) === Kirigami.ColorUtils.Light ? "#111318" : "#ffffff"

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 2.6

    Glass {
        anchors.fill: parent
        tint: row.current ? Kirigami.Theme.focusColor : "#aeb3bf"
        strength: row.current ? 1 : mouse.containsMouse ? 0.4 : 0.08
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.clicked()
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing * 2

        Kirigami.Icon {
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: implicitWidth
            visible: source !== "" && source !== undefined
            source: row.iconSource
            isMask: row.monochrome
            color: row.ink
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: row.title
                color: row.ink
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: row.subtitle
                color: row.ink
                opacity: 0.85
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
            }
        }
        RowLayout {
            id: extra
            spacing: 0
        }
    }
}
