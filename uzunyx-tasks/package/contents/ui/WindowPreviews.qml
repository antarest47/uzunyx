/*
 * What the tooltip of a running app shows: a live thumbnail per window, with
 * its title and a button to close it. Clicking a thumbnail goes to the window.
 * Below them, the app's media and volume controls, if it has any.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.pipewire as PipeWire
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris
import org.kde.taskmanager as TaskManager

// Bordered like the panel, around all the thumbnails.
Rectangle {
    id: previews

    required property var host
    required property var task
    readonly property var tasks: host.tasks
    required property int row
    required property int windows
    required property bool pointerOverTask

    signal done()

    property var entries: []
    readonly property var player: pointerOverTask || visible
        ? host.playerFor(task.model.LauncherUrlWithoutIcon, task.model.AppPid) : null
    readonly property bool playing: player !== null && player.playbackStatus === Mpris.PlaybackStatus.Playing

    // A snapshot of the windows, taken when the tooltip is about to show.
    function refresh() {
        if (!tasks) {
            return;
        }
        const list = [];
        const count = tasks.data(tasks.makeModelIndex(row), TaskManager.AbstractTasksModel.ChildCount);
        const grouped = tasks.data(tasks.makeModelIndex(row), TaskManager.AbstractTasksModel.IsGroupParent);
        for (let child = 0; child < (grouped ? count : 1); child++) {
            const ix = grouped ? tasks.makePersistentModelIndex(row, child) : tasks.makePersistentModelIndex(row);
            const ids = tasks.data(ix, TaskManager.AbstractTasksModel.WinIdList);
            list.push({
                task: ix,
                title: tasks.data(ix, Qt.DisplayRole) || "",
                icon: tasks.data(ix, Qt.DecorationRole),
                uuid: ids && ids.length ? String(ids[0]) : "",
            });
        }
        entries = list;
    }

    onPointerOverTaskChanged: if (pointerOverTask) refresh()
    onWindowsChanged: refresh()
    Component.onCompleted: refresh()

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    radius: 8
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)

    Column {
        id: content

    Row {
        id: thumbnails
        padding: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing * 2

    Repeater {
        model: previews.entries

        Item {
            id: entry
            required property var modelData

            width: 220
            height: 150

            // Only stream while the tooltip is really on screen.
            readonly property bool shown: Window.visibility !== Window.Hidden

            TaskManager.ScreencastingRequest {
                id: cast
                uuid: entry.shown ? entry.modelData.uuid : ""
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Qt.rgba(1, 1, 1, hover.containsMouse ? 0.16 : 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, hover.containsMouse ? 0.3 : 0.12)
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: previews.host.highlight(containsMouse ? [entry.modelData.uuid] : [])
                onClicked: {
                    previews.host.highlight([]);
                    previews.tasks.requestActivate(entry.modelData.task);
                    previews.done();
                }
            }

            Kirigami.Heading {
                id: title
                x: Kirigami.Units.smallSpacing
                y: Kirigami.Units.smallSpacing
                width: parent.width - 2 * x - closeButton.width
                level: 5
                elide: Text.ElideRight
                text: entry.modelData.title
            }

            PlasmaComponents.ToolButton {
                id: closeButton
                anchors.right: parent.right
                anchors.top: parent.top
                icon.name: "window-close-symbolic"
                visible: hover.containsMouse || hovered
                onClicked: {
                    previews.host.highlight([]);
                    previews.tasks.requestClose(entry.modelData.task);
                    previews.done();
                }
            }

            Item {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: title.bottom; margins: Kirigami.Units.smallSpacing }

                PipeWire.PipeWireSourceItem {
                    id: stream
                    anchors.fill: parent
                    nodeId: cast.nodeId
                    visible: nodeId > 0
                }
                // Until the stream starts, or if the window can't be captured.
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: entry.modelData.icon
                    visible: !stream.visible
                }
            }
        }
    }
    }

    RowLayout {
        id: controls
        visible: Plasmoid.configuration.tooltipControls && (previews.player !== null || previews.task.audioStreams.length > 0)
        x: Kirigami.Units.smallSpacing * 2
        width: thumbnails.implicitWidth - x * 2
        height: visible ? implicitHeight + Kirigami.Units.smallSpacing * 2 : 0
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.ToolButton {
            visible: previews.player !== null
            enabled: previews.player?.canGoPrevious ?? false
            icon.name: "media-skip-backward"
            onClicked: previews.player.Previous()
        }
        PlasmaComponents.ToolButton {
            visible: previews.player !== null
            enabled: (previews.playing ? previews.player?.canPause : previews.player?.canPlay) ?? false
            icon.name: previews.playing ? "media-playback-pause" : "media-playback-start"
            onClicked: previews.playing ? previews.player.Pause() : previews.player.Play()
        }
        PlasmaComponents.ToolButton {
            visible: previews.player !== null
            enabled: previews.player?.canGoNext ?? false
            icon.name: "media-skip-forward"
            onClicked: previews.player.Next()
        }
        PlasmaComponents.Label {
            // Without this its text's width pushes the row out of the frame.
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: previews.player?.track ?? ""
        }
        PlasmaComponents.ToolButton {
            visible: previews.task.audioStreams.length > 0
            icon.name: previews.task.muted ? "audio-volume-muted" : "audio-volume-high"
            onClicked: previews.task.toggleMuted()
        }
    }
    }
}
