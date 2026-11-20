/*
 * Alt+Tab in the style of Cover Switch: live previews, the chosen window facing
 * the viewer and the others turned away at its sides. Rotation around the Y axis
 * gives the perspective; the windows on each side are stacked towards the centre.
 *
 * Opening: the first frame is an exact copy of the desktop (wallpaper and every
 * window where it really is); from there each window flies to its place in the
 * row, the current one shrinking into the middle (selected again: see start()),
 * while the wallpaper blurs like in KWin's Overview (DesktopBackground, the item
 * it uses). Windows that aren't on screen (minimized, on another desktop) fade in.
 *
 * Closing: with automaticallyHide off, KWin only announces it (aboutToHide);
 * the window that ended up active grows back to its place, the others go back
 * to theirs, the blur clears, and then the switcher hides itself.
 */
import QtQuick
import QtQuick.Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    // KWin would hide the switcher (and destroy its window) the moment Alt is
    // released; instead it only says so (aboutToHide), and the switcher hides
    // itself once its closing animation is over (stage.leave()).
    automaticallyHide: false

    Instantiator {
        id: stages
        active: false
        delegate: stageComponent
    }

    // Called by the window itself, which this destroys: runs here.
    function finishLeaving() {
        stages.active = false;
        visible = false;
    }

    onAboutToShow: {
        // Also when it is shown again while still closing: start over.
        stages.active = false;
        stages.active = true;
    }
    onAboutToHide: {
        if (stages.object) {
            stages.object.leave();
        } else {
            tabBox.visible = false;
        }
    }

    Component {
        id: stageComponent

        Window {
            id: stage

            readonly property int duration: 300
            readonly property real coverWidth: Math.round(width * 0.46)
            readonly property real coverHeight: Math.round(height * 0.56)
            readonly property int count: covers.count
            // False for the first frame: everything where it really is.
            property bool opened: false
            // True from the moment KWin hides the switcher.
            property bool closing: false
            // The Behaviors stay off until the first frame, so that setting the
            // starting places (Component.onCompleted of each cover) isn't animated.
            property bool animate: false
            // The window that ends up active, and where it is, once closing.
            property string chosenId: ""
            property var chosenRect: null
            readonly property bool showing: opened && !closing

            // The switcher only shows when Alt is held past a moment; a quick
            // Alt+Tab switches at once without it. Shown, it starts on the
            // current window (index 0), facing the viewer in the middle: it is
            // the one on top on screen, so it shrinks in front while the others
            // come out from behind to the sides; Tab then moves on, and letting
            // go of Alt without it stays on the same window. KWin had already
            // moved the selection to the next one (and may do it a moment after
            // this window exists): put it back until the animation starts.
            //
            // The live thumbnails need a frame or two before they have a picture:
            // until then everything stays invisible (the window is transparent,
            // so the real desktop shows, the same picture), else the current
            // window blinked out and back just before shrinking.
            property int frames: 0
            readonly property bool ready: frames >= 3
            function start() {
                if (!animate && frames >= 4) {
                    animate = true;
                    opened = true;
                }
            }
            onFrameSwapped: {
                frames += 1;
                start();
            }
            Connections {
                target: tabBox
                function onCurrentIndexChanged() {
                    if (!stage.animate && tabBox.currentIndex !== 0) {
                        tabBox.currentIndex = 0;
                    }
                }
            }
            Timer {
                interval: 150
                running: true
                onTriggered: {
                    stage.frames = Math.max(stage.frames, 4);
                    stage.start();
                }
            }

            // The panels of this screen, as they are: the switcher covers them,
            // so live copies of them slide away (and come back when closing)
            // instead of vanishing at once.
            property var panels: []
            Component.onCompleted: {
                tabBox.currentIndex = 0;
                const list = [];
                for (const w of KWin.Workspace.stackingOrder) {
                    if (w.dock && !w.minimized && w.output && output && w.output.name === output.name) {
                        const f = w.frameGeometry;
                        list.push({ id: w.internalId, x: f.x - tabBox.screenGeometry.x, y: f.y - tabBox.screenGeometry.y,
                                    width: f.width, height: f.height });
                    }
                }
                panels = list;
            }

            function leave() {
                // KWin activates the chosen window right after asking the
                // switcher to hide (and none on Esc): read it once that is done.
                Qt.callLater(() => {
                    const active = KWin.Workspace.activeWindow;
                    const current = covers.count > 0 ? covers.itemAt(tabBox.currentIndex) : null;
                    chosenId = active ? active.internalId.toString()
                        : (current ? current.model.windowId.toString() : "");
                    const w = windowOf(chosenId, true);
                    if (w) {
                        const f = w.frameGeometry;
                        chosenRect = Qt.rect(f.x - tabBox.screenGeometry.x, f.y - tabBox.screenGeometry.y, f.width, f.height);
                    }
                    animate = true;
                    closing = true;
                    gone.start();
                });
            }
            Timer {
                id: gone
                interval: stage.duration + 40
                onTriggered: tabBox.finishLeaving()
            }

            // The windows by id, to know where each one is on screen. Built on
            // first use: the covers ask before the window's own bindings run.
            property var windowMap: null
            function windowOf(windowId, fresh) {
                if (!windowMap || fresh) {
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

            Item {
                id: content
                anchors.fill: parent
                // Not invisible (nothing would be drawn, thumbnails included):
                // just not seen until they are ready.
                opacity: stage.ready ? 1 : 0.001

                // Opaque, so nothing shows through (the panel included), also while
                // closing: at the end it matches the desktop, blur gone and every
                // window back in its place, and the real one takes over.
                Item {
                    id: backdrop
                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                    }

                    KWin.DesktopBackground {
                        anchors.fill: parent
                        activity: KWin.Workspace.currentActivity
                        desktop: KWin.Workspace.currentDesktop
                        outputName: stage.output ? stage.output.name : ""

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            // Without padding the edges stay opaque: with it they
                            // faded out and showed the desktop and panel behind.
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blurMax: 64
                            blur: stage.showing ? 1 : 0
                            Behavior on blur { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                        opacity: stage.showing ? 0.3 : 0
                        Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: stage.duration } }
                    }
                }

                Repeater {
                    model: stage.panels
                    delegate: KWin.WindowThumbnail {
                        required property var modelData
                        // Out through the nearest edge: down for a bottom panel.
                        readonly property real away: modelData.y + modelData.height / 2 > stage.height / 2
                            ? modelData.height + 24 : -(modelData.height + 24)
                        wId: modelData.id
                        x: modelData.x
                        y: modelData.y + (stage.showing ? away : 0)
                        width: modelData.width
                        height: modelData.height
                        opacity: stage.showing ? 0 : 1
                        Behavior on y { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: stage.duration } }
                    }
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

                            // Shortest way around from the chosen window: negative on
                            // the left. A tie goes left, so with Alt+Tab the current
                            // window (the one before the chosen) always goes left.
                            readonly property int offset: {
                                const half = stage.count / 2;
                                let d = (index - tabBox.currentIndex + stage.count) % stage.count;
                                return d >= half && d > 0 ? d - stage.count : d;
                            }
                            readonly property int distance: Math.abs(offset)
                            readonly property int side: offset === 0 ? 0 : (offset > 0 ? 1 : -1)
                            readonly property bool chosen: offset === 0
                            readonly property bool leavingOnTop: stage.closing && model.windowId.toString() === stage.chosenId

                            // Its real place, taken once, before the first frame.
                            property var from: null
                            Component.onCompleted: from = stage.placeOf(model.windowId)
                            // Where it is (or goes) outside the row: its real place
                            // before opening and after closing; null means the row.
                            readonly property var place: !stage.opened ? from
                                : (stage.closing ? (leavingOnTop && stage.chosenRect ? stage.chosenRect : from) : null)
                            readonly property bool inRow: place == null

                            width: inRow ? stage.coverWidth : place.width
                            height: inRow ? stage.coverHeight : place.height
                            y: inRow ? Math.round((stage.height - stage.coverHeight) / 2 - stage.height * 0.03) : place.y
                            x: inRow ? Math.round((stage.width - stage.coverWidth) / 2 + side * (stage.width * 0.27 + (distance - 1) * stage.width * 0.055)) : place.x
                            // The model is in focus order, the first one on top: as on screen.
                            z: leavingOnTop ? 300 : (stage.opened ? 100 - distance : 100 - index)
                            scale: inRow ? (chosen ? 1 : 0.8) : 1
                            // In the row: dimmer far away; fading in and out when it
                            // has no place on screen.
                            opacity: !inRow ? 1 : (!stage.showing ? 0 : (distance > 3 ? 0 : (distance > 2 ? 0.45 : 1)))

                            Behavior on x { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                            Behavior on width { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                            Behavior on height { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                            Behavior on scale { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                            Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: stage.duration } }

                            transform: Rotation {
                                origin.x: cover.width / 2
                                origin.y: cover.height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: cover.inRow ? -cover.side * 58 : 0
                                Behavior on angle { enabled: stage.animate; NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
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
                                opacity: stage.showing ? 1 : 0
                                Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: stage.duration } }
                            }

                            KWin.WindowThumbnail {
                                id: thumbnail
                                anchors.fill: parent
                                anchors.margins: stage.showing ? 3 : 0
                                wId: cover.model.windowId
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: stage.showing
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
                        opacity: stage.showing ? 1 : 0
                        Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: stage.duration } }

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
}
