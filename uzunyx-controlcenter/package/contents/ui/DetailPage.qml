/*
 * A page of the control center that replaces the main one, with a way back: a
 * title and a scrolling list.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: page

    property string title
    default property alias rows: list.data
    signal back()

    spacing: Kirigami.Units.smallSpacing * 2

    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.ToolButton {
            icon.name: "go-previous-symbolic"
            onClicked: page.back()
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: page.title
            elide: Text.ElideRight
        }
    }

    PlasmaComponents.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        contentHeight: list.implicitHeight
        PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff

        ColumnLayout {
            id: list
            width: page.width - Kirigami.Units.gridUnit
            spacing: Kirigami.Units.smallSpacing
        }
    }
}
