/*
 * Uzunyx's window view, instead of KWin's Overview (variant B of the mockups,
 * chosen by the user on 2026-11-20): every window of the current desktop as a
 * live thumbnail, laid out in a grid over the blurred wallpaper, with a search
 * field on top and the panel still in sight. Meta+Tab or four fingers up.
 *
 * Opening and closing as Uzunyx's Alt+Tab: the first frame is a copy of the
 * desktop, every window where it really is; from there each one flies to its
 * place in the grid while the wallpaper blurs. Choosing one (click, or Enter on
 * the selected one) makes it active and it grows back to its place, the others
 * back to theirs; Esc, a click on the background or on the panel go back
 * without changing anything.
 *
 * One window per screen: desktops are only on the primary one (uzunyxdesktops),
 * so each screen shows its own windows. The search field is on the screen the
 * view was opened from, and filters on every screen.
 *
 * The panel is a live copy (the view's window is above everything, panels
 * included): a click on it goes back, like Esc.
 */
import QtQuick
import QtQuick.Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin

Item {
    id: root

    readonly property int duration: 300
    // The view's own windows, left out of it.
    readonly property string viewTitle: "Uzunyx window view"
    // One per screen while the view is open.
    property var stages: []
    property bool closing: false
    property string filter: ""

    function toggle() {
        if (stages.length === 0) {
            open();
        } else if (!closing) {
            close(null);
        }
    }

    function open() {
        closing = false;
        filter = "";
        const focused = KWin.Workspace.activeScreen;
        // Taken before the view's own windows exist.
        const screens = KWin.Workspace.screens.map(output => ({ output: output, windows: windowsOn(output) }));
        const list = [];
        for (const screen of screens) {
            // Created without a parent: a Window inside an Item would only show
            // while that Item's window does, and a script's root has none.
            list.push(stageComponent.createObject(null, {
                output: screen.output,
                windows: screen.windows,
                hasSearch: focused && screen.output.name === focused.name,
            }));
        }
        stages = list;
    }

    // chosen: the window to make active, or null to go back as it was.
    function close(chosen) {
        if (closing || stages.length === 0) {
            return;
        }
        closing = true;
        if (chosen) {
            if (chosen.minimized) {
                chosen.minimized = false;
            }
            KWin.Workspace.activeWindow = chosen;
        }
        for (const stage of stages) {
            stage.leave(chosen);
        }
        finished.start();
    }

    Timer {
        id: finished
        interval: root.duration + 40
        onTriggered: {
            for (const stage of root.stages) {
                stage.destroy();
            }
            root.stages = [];
            root.closing = false;
        }
    }

    KWin.ShortcutHandler {
        name: "UzunyxWindowView"
        text: "Vista de ventanas de Uzunyx"
        sequence: "Meta+Tab"
        onActivated: root.toggle()
    }

    KWin.SwipeGestureHandler {
        direction: KWin.SwipeGestureHandler.Direction.Up
        fingerCount: 4
        onActivated: {
            if (root.stages.length === 0) {
                root.open();
            }
        }
    }

    KWin.SwipeGestureHandler {
        direction: KWin.SwipeGestureHandler.Direction.Down
        fingerCount: 4
        onActivated: root.close(null)
    }

    // The windows of a screen shown in the view: those of the task manager, on
    // the current desktop (or all of them), minimized ones included.
    function windowsOn(output) {
        const current = KWin.Workspace.currentDesktop.id;
        const list = [];
        for (const w of KWin.Workspace.stackingOrder) {
            if (w.deleted || !(w.normalWindow || w.dialog) || w.skipTaskbar || w.specialWindow
                    || w.resourceClass === "org.kde.plasmashell" || String(w.caption).startsWith(viewTitle)) {
                continue;
            }
            if (!w.output || w.output.name !== output.name) {
                continue;
            }
            if (!w.onAllDesktops && !w.desktops.some(d => d.id === current)) {
                continue;
            }
            list.push(w);
        }
        // Read like a page, so that each one moves as little as it can.
        list.sort((a, b) => {
            const fa = a.frameGeometry, fb = b.frameGeometry;
            const rowA = Math.floor((fa.y + fa.height / 2) / 300), rowB = Math.floor((fb.y + fb.height / 2) / 300);
            return rowA !== rowB ? rowA - rowB : (fa.x + fa.width / 2) - (fb.x + fb.width / 2);
        });
        return list;
    }

    function matches(w) {
        if (filter.length === 0) {
            return true;
        }
        const text = filter.toLowerCase();
        return String(w.caption).toLowerCase().indexOf(text) >= 0
            || String(w.resourceClass).toLowerCase().indexOf(text) >= 0
            || String(w.resourceName).toLowerCase().indexOf(text) >= 0;
    }

    // The grid: tries every number of columns and keeps the one where the
    // windows end up biggest (never bigger than they are). Rows are centred.
    // Returns one rect (or null, filtered out) for each window, in order.
    function layout(windows, shown, area, gap, label) {
        const visible = [];
        for (let i = 0; i < windows.length; i++) {
            if (shown[i]) {
                visible.push(i);
            }
        }
        const result = windows.map(() => null);
        const n = visible.length;
        if (n === 0 || area.width <= 0 || area.height <= 0) {
            return result;
        }
        let best = null;
        for (let cols = 1; cols <= n; cols++) {
            const rows = Math.ceil(n / cols);
            const cw = (area.width - gap * (cols - 1)) / cols;
            const ch = (area.height - gap * (rows - 1)) / rows - label;
            if (cw <= 0 || ch <= 0) {
                continue;
            }
            let total = 0;
            for (const i of visible) {
                const f = windows[i].frameGeometry;
                const s = Math.min(cw / f.width, ch / f.height, 1);
                total += s * s * f.width * f.height;
            }
            if (!best || total > best.total) {
                best = { cols: cols, rows: rows, cw: cw, ch: ch, total: total };
            }
        }
        if (!best) {
            return result;
        }
        const gridHeight = best.rows * (best.ch + label) + (best.rows - 1) * gap;
        const top = area.y + (area.height - gridHeight) / 2;
        for (let r = 0; r < best.rows; r++) {
            const row = visible.slice(r * best.cols, (r + 1) * best.cols);
            const sizes = row.map(i => {
                const f = windows[i].frameGeometry;
                const s = Math.min(best.cw / f.width, best.ch / f.height, 1);
                return { w: f.width * s, h: f.height * s };
            });
            // Each window in a cell as wide as the column, the row centred.
            const rowWidth = row.length * best.cw + (row.length - 1) * gap;
            let x = area.x + (area.width - rowWidth) / 2;
            const y = top + r * (best.ch + label + gap);
            row.forEach((i, k) => {
                result[i] = Qt.rect(Math.round(x + (best.cw - sizes[k].w) / 2), Math.round(y + (best.ch - sizes[k].h) / 2),
                                    Math.round(sizes[k].w), Math.round(sizes[k].h));
                x += best.cw + gap;
            });
        }
        return result;
    }

    Component {
        id: stageComponent

        Window {
            id: stage

            required property var output
            required property var windows
            property bool hasSearch: false

            readonly property rect geo: output.geometry
            readonly property int gap: Kirigami.Units.gridUnit * 2
            readonly property int label: Kirigami.Units.gridUnit * 2

            // False for the first frames: everything where it really is.
            property bool opened: false
            property bool animate: false
            property int frames: 0
            readonly property bool ready: frames >= 3
            readonly property bool showing: opened && !root.closing
            property var chosen: null

            // {window, from}: from is where it is on screen, null if minimized.
            property var entries: []
            property var panels: []
            // Where the windows go below the search field and above the panel.
            property rect area: Qt.rect(0, 0, 0, 0)
            readonly property var shown: entries.map(e => root.matches(e.window))
            readonly property var places: root.layout(entries.map(e => e.window), shown, area, gap, label)
            // The selected one, for Enter and the arrows: the first shown at start.
            property int selected: -1
            readonly property int firstShown: shown.indexOf(true)
            onFirstShownChanged: if (selected < 0 || !shown[selected]) selected = firstShown

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
            Timer {
                interval: 150
                running: true
                onTriggered: {
                    stage.frames = Math.max(stage.frames, 4);
                    stage.start();
                }
            }

            function leave(window) {
                chosen = window;
                animate = true;
                opened = false;
            }

            function inScreen(f) {
                return Qt.rect(f.x - geo.x, f.y - geo.y, f.width, f.height);
            }

            Component.onCompleted: {
                const list = windows.map(w => ({
                    window: w,
                    from: w.minimized ? null : inScreen(w.frameGeometry),
                }));
                const docks = [];
                let bottom = Kirigami.Units.gridUnit * 2;
                for (const w of KWin.Workspace.stackingOrder) {
                    if (w.dock && !w.minimized && w.output && w.output.name === output.name) {
                        const f = inScreen(w.frameGeometry);
                        docks.push({ id: w.internalId, rect: f });
                        if (f.y + f.height / 2 > geo.height / 2) {
                            bottom = Math.max(bottom, geo.height - f.y + Kirigami.Units.gridUnit);
                        }
                    }
                }
                const top = Kirigami.Units.gridUnit * (hasSearch ? 5 : 2);
                const side = Kirigami.Units.gridUnit * 2;
                area = Qt.rect(side, top, geo.width - 2 * side, geo.height - top - bottom);
                panels = docks;
                entries = list;
                const active = KWin.Workspace.activeWindow;
                const index = list.findIndex(e => e.window === active);
                selected = index >= 0 ? index : (list.length > 0 ? 0 : -1);
                if (hasSearch) {
                    requestActivate();
                    search.forceActiveFocus();
                }
            }

            // A window closed while the view is open goes out of it.
            Connections {
                target: KWin.Workspace
                function onWindowRemoved(window) {
                    if (stage.entries.some(e => e.window === window)) {
                        stage.entries = stage.entries.filter(e => e.window !== window);
                    }
                }
            }

            function move(step) {
                const order = [];
                for (let i = 0; i < entries.length; i++) {
                    if (shown[i] && places[i]) {
                        order.push(i);
                    }
                }
                if (order.length === 0) {
                    return;
                }
                const at = order.indexOf(selected);
                selected = order[((at < 0 ? 0 : at + step) + order.length) % order.length];
            }

            x: geo.x
            y: geo.y
            width: geo.width
            height: geo.height
            title: root.viewTitle
            flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
            color: "transparent"
            visible: true

            Item {
                anchors.fill: parent
                // Not invisible (nothing would be drawn, thumbnails included):
                // just not seen until they have a picture.
                opacity: stage.ready ? 1 : 0.001

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
                        outputName: stage.output.name
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blurMax: 64
                            blur: stage.showing ? 1 : 0
                            Behavior on blur { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                        opacity: stage.showing ? 0.3 : 0
                        Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: stage.showing
                        onClicked: root.close(null)
                    }
                }

                // The panels, live and where they are: a click goes back.
                Repeater {
                    model: stage.panels
                    delegate: KWin.WindowThumbnail {
                        required property var modelData
                        wId: modelData.id
                        x: modelData.rect.x
                        y: modelData.rect.y
                        width: modelData.rect.width
                        height: modelData.rect.height
                        z: 50
                        MouseArea {
                            anchors.fill: parent
                            enabled: stage.showing
                            onClicked: root.close(null)
                        }
                    }
                }

                // The search field, on the screen the view was opened from.
                Rectangle {
                    id: searchBox
                    visible: stage.hasSearch
                    z: 60
                    readonly property int boxWidth: Math.min(Kirigami.Units.gridUnit * 22, stage.width - Kirigami.Units.gridUnit * 4)
                    width: boxWidth
                    height: Kirigami.Units.gridUnit * 2.2
                    x: Math.round((stage.width - width) / 2)
                    y: Kirigami.Units.gridUnit * 1.5 + (stage.showing ? 0 : -Kirigami.Units.gridUnit)
                    radius: height / 2
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.8)
                    border.width: 1
                    border.color: search.activeFocus ? Kirigami.Theme.focusColor : Qt.rgba(1, 1, 1, 0.25)
                    opacity: stage.showing ? 1 : 0
                    Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }
                    Behavior on y { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }

                    Kirigami.Icon {
                        id: lens
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: "search"
                        color: Kirigami.Theme.textColor
                    }
                    TextInput {
                        id: search
                        anchors.left: lens.right
                        anchors.right: parent.right
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        color: Kirigami.Theme.textColor
                        selectionColor: Kirigami.Theme.highlightColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        clip: true
                        onTextChanged: root.filter = text
                        Keys.onEscapePressed: root.close(null)
                        Keys.onReturnPressed: root.close(stage.selected >= 0 && stage.shown[stage.selected] ? stage.entries[stage.selected].window : null)
                        Keys.onEnterPressed: root.close(stage.selected >= 0 && stage.shown[stage.selected] ? stage.entries[stage.selected].window : null)
                        Keys.onLeftPressed: event => { if (text.length === 0) stage.move(-1); else event.accepted = false; }
                        Keys.onRightPressed: event => { if (text.length === 0) stage.move(1); else event.accepted = false; }
                        Keys.onTabPressed: stage.move(1)
                        Keys.onBacktabPressed: stage.move(-1)

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: search.text.length === 0
                            text: "Buscar ventanas…"
                            color: Kirigami.Theme.disabledTextColor
                            font: search.font
                        }
                    }
                }

                Repeater {
                    model: stage.entries

                    delegate: Item {
                        id: tile

                        required property var modelData
                        required property int index
                        readonly property var window: modelData.window
                        readonly property var from: modelData.from
                        readonly property var place: stage.places[index] || null
                        readonly property bool isShown: stage.shown[index] === true && place !== null
                        readonly property bool isChosen: stage.chosen === window
                        readonly property bool isSelected: stage.selected === index && isShown
                        // Its last place in the grid, for fading out when filtered.
                        property var lastPlace: place
                        onPlaceChanged: if (place) lastPlace = place

                        // Where it is: its real place before opening and after
                        // closing (the chosen one where it is now), the grid between.
                        readonly property var target: {
                            if (!stage.opened) {
                                if (isChosen && !window.deleted) {
                                    return stage.inScreen(window.frameGeometry);
                                }
                                return from;
                            }
                            return place || lastPlace;
                        }
                        // Minimized ones have no place on screen: they grow in the grid.
                        readonly property var rect: target || (lastPlace ? Qt.rect(lastPlace.x + lastPlace.width / 2,
                            lastPlace.y + lastPlace.height / 2, 1, 1) : Qt.rect(stage.width / 2, stage.height / 2, 1, 1))

                        x: rect.x
                        y: rect.y
                        width: rect.width
                        height: rect.height
                        z: isChosen ? 300 : (hover.containsMouse ? 200 : 100 + index)
                        opacity: !stage.opened ? (target ? 1 : 0) : (isShown ? (window.minimized ? 0.7 : 1) : 0)
                        visible: opacity > 0

                        Behavior on x { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                        Behavior on y { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                        Behavior on width { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                        Behavior on height { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                        Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }

                        // The ring: in the accent on the selected one, a lighter
                        // line on the one under the pointer.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            radius: 10
                            color: "transparent"
                            border.width: tile.isSelected ? 3 : (hover.containsMouse ? 2 : 0)
                            border.color: tile.isSelected ? Kirigami.Theme.focusColor : Qt.rgba(1, 1, 1, 0.5)
                            opacity: stage.showing ? 1 : 0
                            Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }
                        }

                        KWin.WindowThumbnail {
                            anchors.fill: parent
                            wId: tile.window.internalId
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: stage.showing
                            onEntered: stage.selected = tile.index
                            onClicked: root.close(tile.window)
                        }

                        // Close, the ball of the window decoration.
                        Item {
                            visible: stage.showing && hover.containsMouse || closeMouse.containsMouse
                            width: 24
                            height: 24
                            x: parent.width - width / 2 - 2
                            y: -height / 2 + 2
                            z: 10
                            Rectangle {
                                anchors.centerIn: parent
                                visible: closeMouse.containsMouse
                                width: 26
                                height: 26
                                radius: width / 2
                                color: "#fe919d"
                            }
                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                sourceSize: Qt.size(44, 44)
                                source: "file:///usr/share/kwin/decorations/uzunyx/contents/buttons/close-"
                                    + (closeMouse.pressed ? "active" : closeMouse.containsMouse ? "hover" : "normal") + ".svg"
                            }
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: tile.window.closeWindow()
                            }
                        }

                        // Icon and title below.
                        Row {
                            anchors.top: parent.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Kirigami.Units.smallSpacing * 2
                            opacity: stage.showing ? 1 : 0
                            Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }
                            Kirigami.Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                source: tile.window.icon
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, Math.max(tile.width - Kirigami.Units.iconSizes.small - Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 6))
                                text: tile.window.caption
                                color: Kirigami.Theme.textColor
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
