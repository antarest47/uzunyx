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
 * The panel stays real and works: a script's windows are always in KWin's top
 * layer, above the panel, so the view leaves a hole where the panel is drawn
 * (its window less the 8 px of floating margin): one window above it and pieces
 * at its sides and below, each with the same blurred wallpaper. When another
 * window becomes active (a task clicked in the panel, Tsunyx) the view goes.
 * The main window isn't bypassing the window manager, so KWin can give it the
 * keyboard (the search field); all are kept out of the task manager, Alt+Tab
 * and the pager, and Uzunyx's other scripts leave them alone by their title.
 *
 * Closing a window from the view: it is made transparent first, so the closing
 * animation (uzunyx-openclose draws it on top of everything) doesn't flash it at
 * its real size; if it stays (an app asking to save), it comes back.
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
    // The window that was active when the view opened, to give it back.
    property var previous: null
    // Title -> where each of the view's windows goes, for KWin (onWindowAdded).
    property var geometries: ({})
    // Floating margin of the panel's window around what it draws.
    readonly property int panelMargin: 8

    // Where a screen's bottom panel is drawn, in screen coordinates, or null.
    function holeOn(output) {
        const g = output.geometry;
        for (const w of KWin.Workspace.stackingOrder) {
            if (!w.dock || w.minimized || !w.output || w.output.name !== output.name) {
                continue;
            }
            const f = w.frameGeometry;
            // On whole pixels: the panel can sit on half a pixel (centred), and
            // the windows around it would leave a line between them.
            const left = Math.round(f.x - g.x + panelMargin), top = Math.round(f.y - g.y + panelMargin);
            const r = Qt.rect(left, top, Math.round(f.x - g.x + f.width - panelMargin) - left,
                              Math.round(f.y - g.y + f.height - panelMargin) - top);
            if (r.width > 0 && r.height > 0 && r.y + r.height / 2 > g.height / 2 && r.y < g.height) {
                return r;
            }
        }
        return null;
    }

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
        previous = KWin.Workspace.activeWindow;
        const focused = KWin.Workspace.activeScreen;
        // Taken before the view's own windows exist.
        const screens = KWin.Workspace.screens.map(output => ({ output: output, windows: windowsOn(output) }));
        const list = [];
        const places = {};
        for (const screen of screens) {
            const g = screen.output.geometry;
            const hole = holeOn(screen.output);
            const title = viewTitle + " " + screen.output.name;
            places[title] = Qt.rect(g.x, g.y, g.width, hole ? hole.y : g.height);
            // Created without a parent: a Window inside an Item would only show
            // while that Item's window does, and a script's root has none.
            // Not shown yet: the pieces go first, so the main window is KWin's
            // newest internal window, the one that gets the keys.
            const stage = stageComponent.createObject(null, {
                output: screen.output,
                windows: screen.windows,
                hasSearch: focused && screen.output.name === focused.name,
                title: title,
                hole: hole,
            });
            if (hole) {
                const pieces = [
                    Qt.rect(0, hole.y, hole.x, g.height - hole.y),
                    Qt.rect(hole.x + hole.width, hole.y, g.width - hole.x - hole.width, g.height - hole.y),
                    Qt.rect(hole.x, hole.y + hole.height, hole.width, g.height - hole.y - hole.height),
                ].filter(r => r.width > 0 && r.height > 0);
                stage.pieces = pieces.map((r, i) => {
                    const pieceTitle = title + " " + i;
                    places[pieceTitle] = Qt.rect(g.x + r.x, g.y + r.y, r.width, r.height);
                    return pieceComponent.createObject(null, { stage: stage, rect: r, title: pieceTitle });
                });
            }
            list.push(stage);
        }
        geometries = places;
        stages = list;
        keyboard("Start");
        // The searching screen's main window last of all.
        const order = list.slice().sort((a, b) => (a.hasSearch ? 1 : 0) - (b.hasSearch ? 1 : 0));
        for (const stage of order) {
            stage.visible = true;
        }
    }

    // chosen: the window to make active, or null to go back as it was.
    // elsewhere: another window became active on its own; leave it so.
    property var chosen: null
    property bool keepActive: false
    function close(chosen, elsewhere) {
        if (closing || stages.length === 0) {
            return;
        }
        closing = true;
        root.chosen = chosen;
        keepActive = elsewhere === true;
        keyboard("Stop");
        if (chosen && chosen.minimized) {
            chosen.minimized = false;
        }
        for (const stage of stages) {
            stage.leave(chosen);
        }
        finished.start();
    }

    // Once the animation is over: activating a window raises it above the
    // view (both are normal windows), so it is done at the end.
    Timer {
        id: finished
        interval: root.duration + 40
        onTriggered: {
            const target = root.chosen || (root.keepActive ? null : root.previous);
            if (target && !target.deleted) {
                KWin.Workspace.activeWindow = target;
            }
            for (const stage of root.stages) {
                for (const piece of stage.pieces) {
                    piece.destroy();
                }
                stage.destroy();
            }
            root.stages = [];
            root.closing = false;
            root.chosen = null;
            root.previous = null;
        }
    }

    // The keyboard: KWin never gives it to a script's windows, so a helper
    // (uzunyx-windowview-keys, a 1 px layer-shell surface that takes it) keeps
    // what is typed, read here every 40 ms while the view is open.
    KWin.DBusCall {
        id: keyboardCall
        service: "org.uzunyx.WindowViewKeys"
        path: "/org/uzunyx/WindowViewKeys"
        dbusInterface: "org.uzunyx.WindowViewKeys"
    }
    KWin.DBusCall {
        id: pollCall
        property bool waiting: false
        service: "org.uzunyx.WindowViewKeys"
        path: "/org/uzunyx/WindowViewKeys"
        dbusInterface: "org.uzunyx.WindowViewKeys"
        method: "Poll"
        onFinished: returnValue => {
            waiting = false;
            if (root.stages.length === 0 || root.closing || !returnValue || returnValue.length < 2) {
                return;
            }
            root.filter = String(returnValue[0]);
            for (const key of returnValue[1]) {
                root.key(key);
            }
        }
        onFailed: waiting = false
    }
    Timer {
        interval: 40
        repeat: true
        running: root.stages.length > 0 && !root.closing
        onTriggered: {
            if (!pollCall.waiting) {
                pollCall.waiting = true;
                pollCall.call();
            }
        }
    }
    function keyboard(method) {
        keyboardCall.method = method;
        keyboardCall.call();
    }

    // A key from the helper, on the screen with the search field.
    function key(name) {
        const stage = stages.find(s => s.hasSearch) || stages[0];
        if (!stage) {
            return;
        }
        if (name === "escape") {
            close(null);
        } else if (name === "enter") {
            const i = stage.selected;
            close(i >= 0 && stage.shown[i] ? stage.entries[i].window : null);
        } else if (name === "next" || name === "right" || name === "down") {
            stage.move(1);
        } else if (name === "previous" || name === "left" || name === "up") {
            stage.move(-1);
        }
    }

    function isView(window) {
        return window && String(window.caption).startsWith(viewTitle);
    }

    // The view's windows as KWin sees them: out of the task manager, Alt+Tab
    // and the pager, on their screen, above the other windows; the one with
    // the search field gets the keyboard.
    Connections {
        target: KWin.Workspace
        function onWindowAdded(window) {
            if (!root.isView(window)) {
                return;
            }
            window.skipTaskbar = true;
            window.skipSwitcher = true;
            window.skipPager = true;
            // The keyboard helper's window: invisible, under the view, active.
            if (window.caption === root.viewTitle + " keys") {
                window.opacity = 0;
                const screen = KWin.Workspace.activeScreen.geometry;
                window.frameGeometry = Qt.rect(screen.x, screen.y, 1, 1);
                KWin.Workspace.activeWindow = window;
                return;
            }
            const place = root.geometries[window.caption];
            if (place) {
                window.frameGeometry = place;
                // KWin may still place it on its own right after.
                Qt.callLater(() => {
                    if (!window.deleted) {
                        window.frameGeometry = place;
                    }
                });
            }
        }
        function onWindowActivated(window) {
            if (window && !root.isView(window) && root.stages.length > 0 && !root.closing) {
                root.close(null, true);
            }
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
                    || w.resourceClass === "org.kde.plasmashell" || isView(w)) {
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

    // The blurred wallpaper of a screen, darker, at the size of the screen;
    // a click on it goes back.
    component Backdrop: Item {
        id: backdrop
        required property var view
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
        }
        KWin.DesktopBackground {
            anchors.fill: parent
            activity: KWin.Workspace.currentActivity
            desktop: KWin.Workspace.currentDesktop
            outputName: backdrop.view.output.name
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: backdrop.view.showing ? 1 : 0
                Behavior on blur { enabled: backdrop.view.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            opacity: backdrop.view.showing ? 0.3 : 0
            Behavior on opacity { enabled: backdrop.view.animate; NumberAnimation { duration: root.duration } }
        }
        MouseArea {
            anchors.fill: parent
            enabled: backdrop.view.showing
            onClicked: root.close(null)
        }
    }

    // A piece of the view beside or below the panel: only the wallpaper.
    Component {
        id: pieceComponent

        Window {
            id: piece
            required property var stage
            required property rect rect

            x: stage.geo.x + rect.x
            y: stage.geo.y + rect.y
            width: rect.width
            height: rect.height
            flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
            color: "transparent"
            visible: true

            Item {
                x: -piece.rect.x
                y: -piece.rect.y
                width: piece.stage.geo.width
                height: piece.stage.geo.height
                opacity: piece.stage.ready ? 1 : 0.001
                Backdrop {
                    view: piece.stage
                }
            }
        }
    }

    Component {
        id: stageComponent

        Window {
            id: stage

            required property var output
            required property var windows
            property bool hasSearch: false
            // Where the panel is (left to it), and the windows around it.
            property var hole: null
            property var pieces: []

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
                let bottom = Kirigami.Units.gridUnit * 2;
                for (const w of KWin.Workspace.stackingOrder) {
                    if (w.dock && !w.minimized && w.output && w.output.name === output.name) {
                        const f = inScreen(w.frameGeometry);
                        if (f.y + f.height / 2 > geo.height / 2) {
                            bottom = Math.max(bottom, geo.height - f.y + Kirigami.Units.gridUnit);
                        }
                    }
                }
                const top = Kirigami.Units.gridUnit * (hasSearch ? 5 : 2);
                const side = Kirigami.Units.gridUnit * 2;
                area = Qt.rect(side, top, geo.width - 2 * side, geo.height - top - bottom);
                entries = list;
                const active = KWin.Workspace.activeWindow;
                const index = list.findIndex(e => e.window === active);
                selected = index >= 0 ? index : (list.length > 0 ? 0 : -1);

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
            height: hole ? hole.y : geo.height
            flags: Qt.FramelessWindowHint
            color: "transparent"
            visible: false

            Item {
                // The whole screen, clipped by the window when it stops above
                // the panel, so the blur is the same as in the pieces.
                width: stage.geo.width
                height: stage.geo.height
                // Not invisible (nothing would be drawn, thumbnails included):
                // just not seen until they have a picture.
                opacity: stage.ready ? 1 : 0.001

                Backdrop {
                    view: stage
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
                    border.color: Kirigami.Theme.focusColor
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
                    // What is typed, from the keyboard helper (see keyboard below).
                    Text {
                        id: search
                        anchors.left: lens.right
                        anchors.right: parent.right
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.filter.length > 0 ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        elide: Text.ElideLeft
                        text: root.filter.length > 0 ? root.filter : "Buscar ventanas…"

                        Rectangle {
                            id: caret
                            x: root.filter.length > 0 ? Math.min(search.contentWidth, search.width) + 1 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: search.font.pixelSize > 0 ? search.font.pixelSize * 1.2 : Kirigami.Units.gridUnit
                            color: Kirigami.Theme.textColor
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: stage.showing
                                NumberAnimation { to: 1; duration: 0 }
                                PauseAnimation { duration: 530 }
                                NumberAnimation { to: 0; duration: 0 }
                                PauseAnimation { duration: 530 }
                            }
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
                        // Closing it from here: invisible first (see the top), back
                        // if it is still there a moment later (it asked something).
                        property bool going: false
                        function closeIt() {
                            going = true;
                            window.opacity = 0;
                            window.closeWindow();
                            stillThere.start();
                        }
                        Timer {
                            id: stillThere
                            interval: 1500
                            onTriggered: {
                                if (!tile.window.deleted) {
                                    tile.window.opacity = 1;
                                    tile.going = false;
                                }
                            }
                        }

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
                        opacity: going ? 0 : !stage.opened ? (target ? 1 : 0) : (isShown ? (window.minimized ? 0.7 : 1) : 0)
                        scale: going ? 0.85 : 1
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
                                onClicked: tile.closeIt()
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
