// Calamares' sidebar (sidebar: qml in branding.desc): numbered steps, all
// the same size, the ones done with a tick in the accent and the current one
// in a soft accent pill. The widget sidebar shrank the text that didn't fit
// and cut "Primeros pasos". Variant A of the mockup, chosen by the user on
// 2026-11-08.
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sideBar
    color: Branding.styleString(Branding.SidebarBackground)
    anchors.fill: parent

    readonly property color accent: "#e62967"
    readonly property color text: Branding.styleString(Branding.SidebarText)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 3

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.bottomMargin: 14
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            source: "file:/" + Branding.imagePath(Branding.ProductLogo)
            sourceSize.width: 144
            sourceSize.height: 144
            fillMode: Image.PreserveAspectFit
        }

        Repeater {
            model: ViewManager
            Rectangle {
                id: step
                required property int index
                required property string display
                readonly property bool current: index === ViewManager.currentStepIndex
                readonly property bool done: index < ViewManager.currentStepIndex

                Layout.fillWidth: true
                implicitHeight: 34
                radius: height / 2
                color: current ? Qt.rgba(sideBar.accent.r, sideBar.accent.g, sideBar.accent.b, 0.18) : "transparent"
                border.width: current ? 1 : 0
                border.color: Qt.rgba(sideBar.accent.r, sideBar.accent.g, sideBar.accent.b, 0.6)

                Rectangle {
                    id: number
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: step.done ? sideBar.accent : "transparent"
                    border.width: 2
                    border.color: step.done || step.current ? sideBar.accent : "#4a505d"
                    Text {
                        anchors.centerIn: parent
                        text: step.done ? "✓" : step.index + 1
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.weight: Font.ExtraBold
                    }
                }
                Text {
                    anchors.left: number.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: step.display
                    elide: Text.ElideRight
                    font.pixelSize: 14
                    font.weight: step.current ? Font.Bold : Font.Normal
                    color: step.current ? "#ffffff" : step.done ? "#d9dce4" : "#9aa0ad"
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
