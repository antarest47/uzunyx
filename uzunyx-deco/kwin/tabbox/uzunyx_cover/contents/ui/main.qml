/*
 * Alt+Tab in the style of Cover Switch: live previews, the chosen window facing
 * the viewer and the others turned away at its sides. Rotation around the Y axis
 * gives the perspective; the windows on each side are stacked towards the centre.
 *
 * When it opens, every window on screen starts where it really is and flies to
 * its place in the row, so the current one seems to shrink into the middle,
 * while the wallpaper behind blurs like in KWin's Overview (DesktopBackground,
 * the same item it uses). Windows that aren't on screen (minimized, on another
 * desktop) fade in at their place in the row.
 */
import QtQuick
import QtQuick.Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    Instantiator {
        active: tabBox.visible
        delegate: Window {
            id: stage

            readonly property int duration: 300
            readonly property real coverWidth: Math.round(width * 0.46)
            readonly property real coverHeight: Math.round(height * 0.56)
            readonly property int count: covers.count
            // False for the first frame: everything where it really is.
            property bool opened: false

            // The windows by id, to know where each one is on screen. Built on
            // first use: the covers ask before the window's own bindings run.
            property var windowMap: null
            function windowOf(windowId) {
                if (!windowMap) {
                    const map = {};
                    for (const w of KWin.Workspace.stackingOrder) {
                        map[w.internalId.toString()] = w;
                    }
                    windowMap = map;
                }
                return windowMap[windowId.toString()];
            }
            readonly property var output: KWin.Workspace.screenAt(Qt.point(
                tabBox.screenGeometry.x + tabBox.screenGeometry.width / 2,
                tabBox.screenGeometry.y + tabBox.screenGeometry.height / 2))

            // Where a window is now, in this screen's coordinates; null if it
            // isn't visible on it.
            function placeOf(windowId) {
                const w = windowOf(windowId);
                if (!w || w.minimized || !w.output || !output || w.output.name !== output.name) {
                    return null;
                }
                if (!w.onAllDesktops && w.desktops.indexOf(KWin.Workspace.currentDesktop) === -1) {
                    return null;
                }
                const f = w.frameGeometry;
                return Qt.rect(f.x - tabBox.screenGeometry.x, f.y - tabBox.screenGeometry.y, f.width, f.height);
            }

            x: tabBox.screenGeometry.x
            y: tabBox.screenGeometry.y
            width: tabBox.screenGeometry.width
            height: tabBox.screenGeometry.height
            flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
            color: "transparent"
            visible: true

            // One frame as the desktop looks, then everything moves.
            Timer {
                interval: 16
                running: true
                onTriggered: stage.opened = true
            }

            KWin.DesktopBackground {
                anchors.fill: parent
                activity: KWin.Workspace.currentActivity
                desktop: KWin.Workspace.currentDesktop
                outputName: stage.output ? stage.output.name : ""

                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 64
                    blur: stage.opened ? 1 : 0
                    Behavior on blur { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.backgroundColor
                opacity: stage.opened ? 0.3 : 0
                Behavior on opacity { NumberAnimation { duration: stage.duration } }
            }

            Item {
                id: scene
                anchors.fill: parent
                focus: true

                Keys.onLeftPressed: tabBox.currentIndex = (tabBox.currentIndex - 1 + stage.count) % stage.count
                Keys.onRightPressed: tabBox.currentIndex = (tabBox.currentIndex + 1) % stage.count

                Repeater {
                    id: covers
                    model: tabBox.model

                    delegate: Item {
                        id: cover

                        required property int index
                        required property var model

                        // Shortest way around from the chosen window: negative on the left.
                        readonly property int offset: {
                            const half = stage.count / 2;
                            let d = (index - tabBox.currentIndex + stage.count) % stage.count;
                            return d > half ? d - stage.count : d;
                        }
                        readonly property int distance: Math.abs(offset)
                        readonly property int side: offset === 0 ? 0 : (offset > 0 ? 1 : -1)
                        readonly property bool chosen: offset === 0
                        // Where it starts: its real place, if it's on screen.
                        // Taken once, before the first frame.
                        property var from: null
                        Component.onCompleted: from = stage.placeOf(model.windowId)
                        readonly property bool fromScreen: from != null
                        readonly property bool inRow: stage.opened || !fromScreen

                        width: inRow ? stage.coverWidth : from.width
                        height: inRow ? stage.coverHeight : from.height
                        y: inRow ? Math.round((stage.height - stage.coverHeight) / 2 - stage.height * 0.03) : from.y
                        x: inRow ? Math.round((stage.width - stage.coverWidth) / 2 + side * (stage.width * 0.27 + (distance - 1) * stage.width * 0.055)) : from.x
                        // The model is in focus order, the first one on top: as on screen.
                        z: stage.opened ? 100 - distance : 100 - index
                        scale: stage.opened ? (chosen ? 1 : 0.8) : 1
                        opacity: !stage.opened ? (fromScreen ? 1 : 0) : (distance > 3 ? 0 : (distance > 2 ? 0.45 : 1))

                        Behavior on x { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: stage.duration } }

                        transform: Rotation {
                            origin.x: cover.width / 2
                            origin.y: cover.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: stage.opened ? -cover.side * 58 : 0
                            Behavior on angle { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        }

                        // The frame hugs the window, whatever its shape.
                        readonly property real fit: thumbnail.implicitWidth > 0 && thumbnail.implicitHeight > 0
                            ? Math.min(width / thumbnail.implicitWidth, height / thumbnail.implicitHeight) : 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: cover.fit > 0 ? thumbnail.implicitWidth * cover.fit + 6 : parent.width
                            height: cover.fit > 0 ? thumbnail.implicitHeight * cover.fit + 6 : parent.height
                            radius: 8
                            color: Kirigami.Theme.alternateBackgroundColor
                            border.width: cover.chosen ? 2 : 1
                            border.color: cover.chosen ? Kirigami.Theme.focusColor : Qt.rgba(1, 1, 1, 0.25)
                            opacity: stage.opened ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: stage.duration } }
                        }

                        KWin.WindowThumbnail {
                            id: thumbnail
                            anchors.fill: parent
                            anchors.margins: stage.opened ? 3 : 0
                            wId: cover.model.windowId
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: tabBox.model.activate(cover.index)
                        }
                    }
                }

                Row {
                    id: title
                    readonly property var current: covers.count > 0 ? covers.itemAt(tabBox.currentIndex) : null
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height / 2 + stage.coverHeight / 2 + parent.height * 0.015)
                    spacing: Kirigami.Units.largeSpacing
                    visible: current !== null
                    opacity: stage.opened ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: stage.duration } }

                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        source: title.current ? title.current.model.icon : ""
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, stage.width * 0.6)
                        text: title.current ? title.current.model.caption : ""
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
