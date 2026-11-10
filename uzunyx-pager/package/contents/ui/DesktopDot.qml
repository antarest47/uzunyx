/*
 * One desktop: a dot, or a longer pill in the accent if it's the current one.
 * Hovering shows a little picture of the desktop with its windows live.
 */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.pipewire as PipeWire
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

PlasmaCore.ToolTipArea {
    id: dot

    required property var desktopId
    required property string desktopName
    required property bool current
    required property bool vertical
    required property int size
    required property color accent

    signal activated()

    width: vertical ? size : (current ? size * 2 : size)
    height: vertical ? (current ? size * 2 : size) : size
    Behavior on width {
        NumberAnimation { duration: Kirigami.Units.shortDuration }
    }
    Behavior on height {
        NumberAnimation { duration: Kirigami.Units.shortDuration }
    }

    location: Plasmoid.location
    mainItem: previewLoader

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: dot.current ? dot.accent : Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.95 : 0.6)
        border.width: dot.current ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, 0.35)
    }

    // Easier to hit than the dot itself.
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        onClicked: dot.activated()
    }

    Loader {
        id: previewLoader
        active: dot.containsMouse || status === Loader.Ready
        visible: false
        sourceComponent: Column {
            id: preview
            padding: Kirigami.Units.smallSpacing * 2
            spacing: Kirigami.Units.smallSpacing

            readonly property rect screen: Plasmoid.containment.screenGeometry
            readonly property real scale: 280 / Math.max(screen.width, 1)

            Kirigami.Heading {
                level: 5
                text: dot.desktopName
            }

            Rectangle {
                width: 280
                height: preview.screen.height * preview.scale
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)
                clip: true

                Repeater {
                    model: TaskManager.TasksModel {
                        groupMode: TaskManager.TasksModel.GroupDisabled
                        filterByVirtualDesktop: true
                        virtualDesktop: dot.desktopId
                        filterHidden: true
                    }

                    Item {
                        id: window
                        required property var model
                        readonly property rect frame: model.Geometry
                        x: frame.x * preview.scale
                        y: frame.y * preview.scale
                        width: frame.width * preview.scale
                        height: frame.height * preview.scale
                        z: model.StackingOrder
                        visible: model.IsWindow === true && !model.IsMinimized

                        TaskManager.ScreencastingRequest {
                            id: cast
                            uuid: window.visible && dot.containsMouse && model.WinIdList?.length ? String(model.WinIdList[0]) : ""
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            color: "#343944"
                        }
                        PipeWire.PipeWireSourceItem {
                            anchors.fill: parent
                            nodeId: cast.nodeId
                            visible: nodeId > 0
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.5
                            height: width
                            source: window.model.decoration
                            visible: cast.nodeId === 0
                        }
                    }
                }
            }
        }
    }
}
