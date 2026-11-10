/*
 * A toggle of the control center: glass, in the edition's accent when on.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: tile

    property string iconName
    // Instead of the icon: a tiling layout, drawn.
    property string layout
    property string title
    property string subtitle
    property bool on: false
    // A second button at the end, with a list behind it, as in GNOME.
    property bool more: false
    signal clicked()
    signal moreClicked()

    // Dark text on a light accent (Sora), light on a dark one (Akane).
    readonly property color ink: !on ? Kirigami.Theme.textColor
        : Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.focusColor) === Kirigami.ColorUtils.Light ? "#111318" : "#ffffff"

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: Kirigami.Units.gridUnit * 3

    Glass {
        anchors.fill: parent
        tint: tile.on ? Kirigami.Theme.focusColor : "#aeb3bf"
        strength: tile.on ? 1 : mouse.containsMouse ? 0.4 : 0.1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: tile.more ? Kirigami.Units.gridUnit * 2 + Kirigami.Units.smallSpacing : Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing * 2

        Kirigami.Icon {
            visible: tile.layout.length === 0
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: implicitWidth
            source: tile.iconName
            isMask: true
            color: tile.ink
        }
        LayoutIcon {
            visible: tile.layout.length > 0
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: implicitWidth
            width: implicitWidth
            height: implicitHeight
            layout: tile.layout
            tint: tile.ink
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.title
                color: tile.ink
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: tile.subtitle
                color: tile.ink
                opacity: 0.85
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: tile.clicked()
    }

    Item {
        visible: tile.more
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: Kirigami.Units.gridUnit * 2

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 6; bottomMargin: 6 }
            width: 1
            color: tile.ink
            opacity: 0.35
        }
        Rectangle {
            anchors { fill: parent; leftMargin: 1 }
            topRightRadius: 8
            bottomRightRadius: 8
            color: Qt.rgba(1, 1, 1, moreMouse.containsMouse ? 0.15 : 0)
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth
            source: "go-next-symbolic"
            isMask: true
            color: tile.ink
        }
        MouseArea {
            id: moreMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tile.moreClicked()
        }
    }
}
