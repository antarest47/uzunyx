/*
 * Uzunyx's window view, instead of KWin's Overview (variant B of the mockups,
 * chosen by the user on 2026-11-20): every window of the current desktop as a
 * live thumbnail, laid out in a grid over the blurred wallpaper, with a search
 * field on top and the panel still in sight. Meta+Tab or four fingers up.
 *
 * Desktops (variant C, chosen by the user on 2026-11-21): on the primary screen,
 * below the search field, a strip with every desktop (its wallpaper and its
 * windows, small) and a «+» at the end. The grid is one page per desktop; going
 * to another one (a click on the strip, the wheel over it, Ctrl+← →) slides the
 * pages without closing the view. KWin's own desktop stays as it was until the
 * view closes: then it goes to the desktop in view, or to the chosen window's
 * (the view hides it switching). If KWin's desktop changes anyway (three
 * fingers, Alt+A/D), the view follows it. The search looks in every desktop:
 * the windows of the desktop in view first, then the others, each with the
 * number of its desktop. A thumbnail dragged to the strip moves the window to
 * that desktop; onto «+», to a new one.
 *
 * Opening and closing as Uzunyx's Alt+Tab: the first frame is a copy of the
 * desktop, every window where it really is; from there each one flies to its
 * place in the grid while the wallpaper blurs. Choosing one (click, or Enter on
 * the selected one) makes it active and it grows back to its place, the others
 * back to theirs (those of other desktops fade); Esc, a click on the background
 * or on the panel go back without changing anything but the desktop.
 *
 * One window per screen: desktops are only on the primary one (uzunyxdesktops),
 * so each screen shows its own windows, and only the primary has the strip. The
 * search field is on the screen the view was opened from, and filters on every
 * screen.
 *
 * The panel stays real and works: a script's windows are always in KWin's top
 * layer, above the panel, so the view leaves a hole where the panel is drawn
 * (its window less the 8 px of floating margin): one window above it and pieces
 * at its sides and below, each with the same blurred wallpaper. When another
 * window becomes active (a task clicked in the panel, Tsunyx) the view goes.
 * The main window isn't bypassing the window manager, so KWin can give it the
 * keyboard (the search field); all are kept out of the task manager, Alt+Tab
 * and the pager, on all desktops, and Uzunyx's other scripts leave them alone
 * by their title.
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
    // The desktop shown on the primary screen; KWin's changes when closing.
    property var viewDesktop: null
    // The desktop KWin ends on, while closing.
    property var closingDesktop: null
    // The keyboard helper's window while the view is open.
    property var keysWindow: null
    // macfullscreen's own desktops.
    readonly property string fullscreenPrefix: "⛶ "

    function sameDesktop(a, b) {
        return !!a && !!b && a.id === b.id;
    }
    function onDesktop(w, desktop) {
        return !!w && !w.deleted && (w.onAllDesktops || (!!desktop && w.desktops.some(d => d.id === desktop.id)));
    }
    function isFullscreenDesktop(desktop) {
        return !!desktop && String(desktop.name).indexOf(fullscreenPrefix) === 0;
    }
    // What the strip and the badges call a desktop: its number among the usual
    // ones, or the name of a fullscreen one.
    function desktopLabel(desktop) {
        if (!desktop) {
            return "";
        }
        if (isFullscreenDesktop(desktop)) {
            return String(desktop.name);
        }
        let n = 0;
        for (const d of KWin.Workspace.desktops) {
            if (!isFullscreenDesktop(d)) {
                n += 1;
            }
            if (d.id === desktop.id) {
                return String(n);
            }
        }
        return "";
    }
    function desktopOf(w) {
        if (!w || w.onAllDesktops || w.desktops.length === 0) {
            return null;
        }
        return w.desktops[w.desktops.length - 1];
    }
    function primaryOutput() {
        const order = KWin.Workspace.screenOrder;
        return order && order.length > 0 ? order[0] : KWin.Workspace.activeScreen;
    }

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
        viewDesktop = KWin.Workspace.currentDesktop;
        closingDesktop = null;
        const focused = KWin.Workspace.activeScreen;
        const primary = primaryOutput();
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
                isPrimary: !!primary && screen.output.name === primary.name,
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

    // chosen: the window to make active, or null to go back as it was (on the
    // desktop in view). elsewhere: another window became active on its own;
    // leave it so.
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
        // KWin goes to the desktop now, while the view still hides it.
        let target = elsewhere === true ? KWin.Workspace.currentDesktop : (desktopOf(chosen) || viewDesktop);
        if (!target || !KWin.Workspace.desktops.some(d => d.id === target.id)) {
            target = KWin.Workspace.currentDesktop;
        }
        closingDesktop = target;
        // KWin slides between desktops (500 ms): the view stays, still, until
        // that is over, so the slide isn't seen.
        finished.interval = root.duration + 40;
        if (!sameDesktop(target, KWin.Workspace.currentDesktop)) {
            KWin.Workspace.currentDesktop = target;
            finished.interval = 540;
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
            let target = root.chosen || (root.keepActive ? null : root.previous);
            // The window that was active, only if it is on the desktop left.
            if (!root.chosen && target && !root.onDesktop(target, KWin.Workspace.currentDesktop)) {
                target = null;
            }
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
            root.keysWindow = null;
            root.closingDesktop = null;
        }
    }

    // The keyboard: KWin never gives it to a script's windows, so a helper
    // (uzunyx-windowview-keys, a 1 px window that takes it) keeps what is
    // typed, read here every 40 ms while the view is open.
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
        if (name === "desktop-left" || name === "desktop-right") {
            stepDesktop(name === "desktop-left" ? -1 : 1);
            return;
        }
        const stage = stages.find(s => s.hasSearch) || stages[0];
        const page = stage ? stage.page : null;
        if (name === "escape") {
            close(null);
        } else if (name === "enter") {
            const i = page ? page.selected : -1;
            close(i >= 0 && page.shown[i] ? page.entries[i].window : null);
        } else if (!page) {
            return;
        } else if (name === "next" || name === "right" || name === "down") {
            page.move(1);
        } else if (name === "previous" || name === "left" || name === "up") {
            page.move(-1);
        }
    }

    // The desktop in view, one to the left or right (no wrapping around).
    function stepDesktop(step) {
        const list = KWin.Workspace.desktops;
        const at = list.findIndex(d => sameDesktop(d, viewDesktop));
        const next = at + step;
        if (at >= 0 && next >= 0 && next < list.length) {
            viewDesktop = list[next];
        }
    }

    // «+»: a new desktop at the end (as Alt+D names it), unless the last one is
    // empty already. A window given goes to it.
    function newDesktop(window) {
        const list = KWin.Workspace.desktops;
        const last = list[list.length - 1];
        const empty = last && !isFullscreenDesktop(last) && !KWin.Workspace.stackingOrder.some(w =>
            (w.normalWindow || w.dialog) && !w.skipTaskbar && !w.onAllDesktops && w !== window
            && w.desktops.some(d => d.id === last.id));
        let desktop = last;
        if (!empty) {
            KWin.Workspace.createDesktop(list.length, "Escritorio " + (list.length + 1));
            const now = KWin.Workspace.desktops;
            desktop = now[now.length - 1];
        }
        if (window && !window.deleted) {
            window.desktops = [desktop];
        }
        viewDesktop = desktop;
    }

    function isView(window) {
        return window && String(window.caption).startsWith(viewTitle);
    }

    // The view's windows as KWin sees them: out of the task manager, Alt+Tab
    // and the pager, on their screen, above the other windows, on every
    // desktop (KWin's changes under it); the one with the search field gets
    // the keyboard.
    Connections {
        target: KWin.Workspace
        function onWindowAdded(window) {
            if (!root.isView(window)) {
                return;
            }
            window.skipTaskbar = true;
            window.skipSwitcher = true;
            window.skipPager = true;
            window.onAllDesktops = true;
            // The keyboard helper's window: invisible, under the view, active.
            if (window.caption === root.viewTitle + " keys") {
                root.keysWindow = window;
                window.opacity = 0;
                const screen = KWin.Workspace.activeScreen.geometry;
                window.frameGeometry = Qt.rect(screen.x, screen.y, 1, 1);
                KWin.Workspace.activeWindow = window;
                return;
            }
            const place = root.geometries[window.caption];
            if (place) {
                window.frameGeometry = place;
                // KWin may still place it on its own right after. And it moves
                // the windows touching the edges of the work area when that
                // changes (a fullscreen desktop has no panel strut, edge-gaps
                // goes away there): the view's slid down or up, showing the
                // screen under it (seen by the user on 2026-11-21). Put back,
                // a few times at most per opening, in case KWin insists.
                let fixes = 0;
                const putBack = () => {
                    const f = window.frameGeometry;
                    if (window.deleted || root.stages.length === 0 || fixes >= 20
                            || (f.x === place.x && f.y === place.y && f.width === place.width && f.height === place.height)) {
                        return;
                    }
                    fixes += 1;
                    window.frameGeometry = place;
                };
                Qt.callLater(putBack);
                window.frameGeometryChanged.connect(() => Qt.callLater(putBack));
            }
        }
        function onWindowActivated(window) {
            if (root.stages.length === 0 || root.closing || root.isView(window)) {
                return;
            }
            // Going to a desktop the helper's window has never been on (a new
            // one: Alt+D, three fingers on the last desktop), KWin gives the
            // focus to the desktop itself, or to nothing: the view stays, and
            // the helper takes the keyboard back.
            if (!window || window.desktopWindow) {
                Qt.callLater(() => {
                    const keys = root.keysWindow;
                    if (keys && !keys.deleted && root.stages.length > 0 && !root.closing) {
                        KWin.Workspace.activeWindow = keys;
                    }
                });
                return;
            }
            root.close(null, true);
        }
        // KWin changed desktop with the view open (three fingers, Alt+A/D).
        function onCurrentDesktopChanged() {
            if (root.stages.length > 0 && !root.closing) {
                root.viewDesktop = KWin.Workspace.currentDesktop;
            }
        }
        // The desktop in view went away (uzunyxdesktops took an empty one).
        function onDesktopsChanged() {
            if (root.stages.length > 0 && !KWin.Workspace.desktops.some(d => root.sameDesktop(d, root.viewDesktop))) {
                root.viewDesktop = KWin.Workspace.currentDesktop;
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

    // The windows of a screen the view can show: those of the task manager, on
    // any desktop, minimized ones included, in stacking order.
    function windowsOn(output) {
        const list = [];
        for (const w of KWin.Workspace.stackingOrder) {
            if (w.deleted || !(w.normalWindow || w.dialog) || w.skipTaskbar || w.specialWindow
                    || w.resourceClass === "org.kde.plasmashell" || isView(w)) {
                continue;
            }
            if (!w.output || w.output.name !== output.name) {
                continue;
            }
            list.push(w);
        }
        return list;
    }

    // The order of a page: its desktop's windows read like a page (so each
    // one moves as little as it can), then the others, desktop by desktop.
    function pageOrder(windows, desktop) {
        const desktops = KWin.Workspace.desktops;
        const rank = w => {
            if (!desktop || onDesktop(w, desktop)) {
                return -1;
            }
            const d = desktopOf(w);
            return d ? desktops.findIndex(x => x.id === d.id) : desktops.length;
        };
        return windows.slice().sort((a, b) => {
            const ra = rank(a), rb = rank(b);
            if (ra !== rb) {
                return ra - rb;
            }
            const fa = a.frameGeometry, fb = b.frameGeometry;
            const rowA = Math.floor((fa.y + fa.height / 2) / 300), rowB = Math.floor((fb.y + fb.height / 2) / 300);
            return rowA !== rowB ? rowA - rowB : (fa.x + fa.width / 2) - (fb.x + fb.width / 2);
        });
    }

    function matches(w) {
        if (!w) {
            return false;
        }
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

    // A small number in a pill: the desktop of a window found while searching,
    // or how many were found on a desktop of the strip. In the accent, or grey.
    component Badge: Rectangle {
        property alias text: badgeText.text
        property bool accent: true
        width: Math.max(height, badgeText.implicitWidth + Kirigami.Units.smallSpacing * 3)
        height: Math.round(badgeText.implicitHeight + 2)
        radius: height / 2
        color: accent ? Qt.rgba(Kirigami.Theme.focusColor.r, Kirigami.Theme.focusColor.g, Kirigami.Theme.focusColor.b, 0.85)
                      : Qt.rgba(1, 1, 1, 0.18)
        Text {
            id: badgeText
            anchors.centerIn: parent
            color: "white"
            font.bold: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
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
            // Every window it can show, in stacking order.
            required property var windows
            property bool hasSearch: false
            // Only the primary screen has desktops, and the strip.
            property bool isPrimary: false
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

            // One page per desktop on the primary screen; one, of every window
            // (all on all desktops), on the others.
            readonly property var desktops: isPrimary ? KWin.Workspace.desktops : [null]
            readonly property int pageIndex: isPrimary ? Math.max(0, desktops.findIndex(d => root.sameDesktop(d, root.viewDesktop))) : 0
            // The page in view (set by the page itself).
            property var page: null

            // Where the windows go below the search field (and the strip) and
            // above the panel.
            property rect area: Qt.rect(0, 0, 0, 0)
            // Ids of the windows closed while the view is open: they stay in the
            // lists (replacing them would rebuild every tile, with no animation),
            // fade out, and the others move to the new grid.
            property var removed: ({})
            // Ids of the ones being closed from the view, out of the grid already.
            property var leaving: ({})
            function setLeaving(id, value) {
                const copy = Object.assign({}, leaving);
                if (value) {
                    copy[id] = true;
                } else {
                    delete copy[id];
                }
                leaving = copy;
            }
            function gone(w) {
                const id = w.internalId.toString();
                return w.deleted || removed[id] === true || leaving[id] === true;
            }

            // The strip: thumbnails as tall as 9 % of the screen, narrower if
            // there are many desktops; the «+» is a square of the same height.
            readonly property real aspect: geo.width / Math.max(1, geo.height)
            readonly property int stripTop: hasSearch ? Math.round(Kirigami.Units.gridUnit * 4.7) : Math.round(Kirigami.Units.gridUnit * 1.5)
            readonly property int stripMaxHeight: Math.round(geo.height * 0.09)
            readonly property int stripSpacing: Kirigami.Units.gridUnit
            readonly property int plusWidth: Math.round(stripMaxHeight * 0.65)
            readonly property int thumbWidth: Math.floor(Math.min(stripMaxHeight * aspect,
                (geo.width - Kirigami.Units.gridUnit * 4 - plusWidth - stripSpacing * desktops.length) / Math.max(1, desktops.length)))
            readonly property int thumbHeight: Math.round(thumbWidth / aspect)
            readonly property int stripLabel: Math.round(Kirigami.Units.gridUnit * 1.4)

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
                cancelDrag();
            }

            function inScreen(f) {
                return Qt.rect(f.x - geo.x, f.y - geo.y, f.width, f.height);
            }

            Component.onCompleted: {
                let bottom = Kirigami.Units.gridUnit * 2;
                for (const w of KWin.Workspace.stackingOrder) {
                    if (w.dock && !w.minimized && w.output && w.output.name === output.name) {
                        const f = inScreen(w.frameGeometry);
                        if (f.y + f.height / 2 > geo.height / 2) {
                            bottom = Math.max(bottom, geo.height - f.y + Kirigami.Units.gridUnit);
                        }
                    }
                }
                const top = isPrimary ? stripTop + stripMaxHeight + stripLabel + Kirigami.Units.gridUnit * 1.5
                                      : Kirigami.Units.gridUnit * (hasSearch ? 5 : 2);
                const side = Kirigami.Units.gridUnit * 2;
                area = Qt.rect(side, top, geo.width - 2 * side, geo.height - top - bottom);
            }

            // A window closed while the view is open goes out of it.
            Connections {
                target: KWin.Workspace
                function onWindowRemoved(window) {
                    if (stage.windows.indexOf(window) < 0) {
                        return;
                    }
                    const id = window.internalId.toString();
                    if (!stage.removed[id]) {
                        const removed = Object.assign({}, stage.removed);
                        removed[id] = true;
                        stage.removed = removed;
                    }
                }
            }

            // Dragging a thumbnail to the strip: a copy of it follows the
            // pointer, smaller over the strip; the desktop under it is marked.
            property var dragWindow: null
            property point dragPoint: Qt.point(0, 0)
            property size dragSize: Qt.size(0, 0)
            // Index on the strip under the pointer: a desktop, desktops.length
            // for «+», or -1.
            readonly property int dropIndex: dragWindow ? stripIndexAt(dragPoint) : -1
            function startDrag(window, size) {
                dragSize = size;
                dragWindow = window;
            }
            function dragTo(point) {
                dragPoint = point;
            }
            function cancelDrag() {
                dragWindow = null;
            }
            function endDrag() {
                const window = dragWindow;
                const index = dropIndex;
                dragWindow = null;
                if (!window || window.deleted) {
                    return;
                }
                if (index >= 0 && index < desktops.length) {
                    const desktop = desktops[index];
                    if (window.onAllDesktops || !root.onDesktop(window, desktop)) {
                        window.desktops = [desktop];
                    }
                } else if (index === desktops.length) {
                    // Into a new desktop, which the view goes to.
                    root.newDesktop(window);
                }
            }
            function stripIndexAt(point) {
                if (!isPrimary) {
                    return -1;
                }
                for (let i = 0; i < thumbs.count; i++) {
                    const item = thumbs.itemAt(i);
                    if (item && item.contains(item.mapFromItem(content, point.x, point.y))) {
                        return i;
                    }
                }
                return plus.contains(plus.mapFromItem(content, point.x, point.y)) ? desktops.length : -1;
            }

            x: geo.x
            y: geo.y
            width: geo.width
            height: hole ? hole.y : geo.height
            flags: Qt.FramelessWindowHint
            color: "transparent"
            visible: false

            Item {
                id: content
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
                    // What is typed, from the keyboard helper (see keyboard above).
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
                        text: root.filter.length > 0 ? root.filter
                            : (KWin.Workspace.desktops.length > 1 ? "Buscar en todos los escritorios…" : "Buscar ventanas…")

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

                // The strip of desktops, on the primary screen.
                Row {
                    id: strip
                    visible: stage.isPrimary
                    z: 60
                    spacing: stage.stripSpacing
                    x: Math.round((stage.width - width) / 2)
                    y: stage.stripTop + (stage.showing ? 0 : -Kirigami.Units.gridUnit)
                    opacity: stage.showing ? 1 : 0
                    Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }
                    Behavior on y { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }

                    WheelHandler {
                        enabled: stage.showing
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        property real pending: 0
                        onWheel: event => {
                            const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                            pending += delta;
                            if (Math.abs(pending) >= 120) {
                                root.stepDesktop(pending > 0 ? -1 : 1);
                                pending = 0;
                            }
                        }
                    }

                    Repeater {
                        id: thumbs
                        model: stage.isPrimary ? stage.desktops : []

                        delegate: Item {
                            id: thumb
                            required property var modelData
                            required property int index
                            readonly property var desktop: modelData
                            readonly property bool isCurrent: index === stage.pageIndex
                            readonly property bool isDrop: stage.dropIndex === index
                            // While searching, how many it found here.
                            readonly property int found: {
                                if (root.filter.length === 0) {
                                    return 0;
                                }
                                let n = 0;
                                for (const w of stage.windows) {
                                    if (!stage.gone(w) && root.matches(w) && root.onDesktop(w, desktop)) {
                                        n += 1;
                                    }
                                }
                                return n;
                            }
                            width: stage.thumbWidth
                            height: stage.thumbHeight + stage.stripLabel

                            // The ring: the accent on the desktop in view, white
                            // where a window would be dropped or under the pointer.
                            Rectangle {
                                x: -3
                                y: -3
                                width: stage.thumbWidth + 6
                                height: stage.thumbHeight + 6
                                radius: 9
                                color: "transparent"
                                border.width: thumb.isCurrent || thumb.isDrop ? 2 : (thumbMouse.containsMouse ? 1 : 0)
                                border.color: thumb.isDrop ? "white" : thumb.isCurrent ? Kirigami.Theme.focusColor : Qt.rgba(1, 1, 1, 0.6)
                            }
                            Item {
                                id: picture
                                width: stage.thumbWidth
                                height: stage.thumbHeight
                                clip: true
                                // Fullscreen desktops, dimmer.
                                opacity: root.isFullscreenDesktop(thumb.desktop) && !thumb.isCurrent ? 0.6 : 1
                                readonly property real ratio: width / Math.max(1, stage.geo.width)

                                KWin.DesktopBackground {
                                    anchors.fill: parent
                                    activity: KWin.Workspace.currentActivity
                                    desktop: thumb.desktop
                                    outputName: stage.output.name
                                }
                                Repeater {
                                    model: stage.windows
                                    delegate: KWin.WindowThumbnail {
                                        required property var modelData
                                        readonly property var window: modelData
                                        readonly property rect frame: window.frameGeometry
                                        visible: !window.minimized && !stage.gone(window) && root.onDesktop(window, thumb.desktop)
                                        // Searching: the ones not found go dim.
                                        opacity: root.matches(window) ? 1 : 0.3
                                        x: Math.round((frame.x - stage.geo.x) * picture.ratio)
                                        y: Math.round((frame.y - stage.geo.y) * picture.ratio)
                                        width: Math.round(frame.width * picture.ratio)
                                        height: Math.round(frame.height * picture.ratio)
                                        wId: window.internalId
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    radius: 6
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.25)
                                    visible: !thumb.isCurrent && !thumb.isDrop
                                }
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: stage.thumbHeight + Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, stage.thumbWidth - (foundBadge.visible ? foundBadge.width + Kirigami.Units.smallSpacing : 0))
                                    elide: Text.ElideRight
                                    text: root.desktopLabel(thumb.desktop)
                                    color: thumb.isCurrent ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                    font.bold: thumb.isCurrent
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                                Badge {
                                    id: foundBadge
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: thumb.found > 0
                                    text: thumb.found
                                }
                            }
                            MouseArea {
                                id: thumbMouse
                                width: stage.thumbWidth
                                height: stage.thumbHeight
                                hoverEnabled: true
                                enabled: stage.showing
                                onClicked: root.viewDesktop = thumb.desktop
                            }
                        }
                    }

                    // «+»: a new desktop at the end.
                    Item {
                        id: plus
                        width: stage.plusWidth
                        height: stage.thumbHeight + stage.stripLabel
                        readonly property bool isDrop: stage.dropIndex === stage.desktops.length
                        Rectangle {
                            width: parent.width
                            height: stage.thumbHeight
                            radius: 6
                            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.55)
                            border.width: plus.isDrop ? 2 : 1
                            border.color: plus.isDrop ? "white" : Qt.rgba(1, 1, 1, plusMouse.containsMouse ? 0.6 : 0.3)
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: Kirigami.Units.iconSizes.smallMedium
                                height: width
                                source: "list-add"
                                color: Kirigami.Theme.textColor
                                opacity: plusMouse.containsMouse || plus.isDrop ? 1 : 0.6
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: stage.thumbHeight + Kirigami.Units.smallSpacing
                            text: "Nuevo"
                            color: Kirigami.Theme.disabledTextColor
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                        MouseArea {
                            id: plusMouse
                            width: parent.width
                            height: stage.thumbHeight
                            hoverEnabled: true
                            enabled: stage.showing
                            onClicked: root.newDesktop(null)
                        }
                    }
                }

                // The pages, side by side; the one in view at x = 0.
                Repeater {
                    model: stage.desktops

                    delegate: Item {
                        id: page

                        required property var modelData
                        required property int index
                        // Null on a screen without desktops: every window.
                        readonly property var desktop: modelData
                        readonly property bool isCurrent: index === stage.pageIndex
                        onIsCurrentChanged: if (isCurrent) stage.page = page
                        Component.onDestruction: if (stage.page === page) stage.page = null

                        width: stage.geo.width
                        height: stage.geo.height
                        x: (index - stage.pageIndex) * (stage.geo.width + stage.gap)
                        Behavior on x { enabled: stage.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                        // The ones away from view aren't drawn.
                        visible: Math.abs(x) < width + stage.gap

                        // {window, from}: from is where it is on screen, null if
                        // minimized. Once: a window moved to another desktop
                        // stays in the list (onPage changes), its tile with it.
                        property var entries: []
                        // On this page's desktop (it changes if a window is moved).
                        readonly property var onPage: entries.map(e => desktop === null || root.onDesktop(e.window, desktop))
                        readonly property bool searching: root.filter.length > 0
                        readonly property var shown: entries.map((e, i) => !stage.removed[e.id] && !stage.leaving[e.id]
                            && (onPage[i] || searching) && root.matches(e.window))
                        readonly property var places: root.layout(entries.map(e => e.window), shown, stage.area, stage.gap, stage.label)
                        // The selected one, for Enter and the arrows: the active
                        // one, or the first shown.
                        property int selected: -1
                        readonly property int firstShown: shown.indexOf(true)
                        onFirstShownChanged: if (selected < 0 || !shown[selected]) selected = firstShown
                        onShownChanged: if (selected >= 0 && !shown[selected]) selected = firstShown
                        Component.onCompleted: {
                            entries = root.pageOrder(stage.windows, desktop).map(w => ({
                                window: w,
                                id: w.internalId.toString(),
                                wid: w.internalId,
                                from: w.minimized ? null : stage.inScreen(w.frameGeometry),
                            }));
                            if (isCurrent) {
                                stage.page = page;
                            }
                            const active = KWin.Workspace.activeWindow;
                            const i = entries.findIndex(e => e.window === active);
                            selected = i >= 0 && shown[i] ? i : firstShown;
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

                        // An empty desktop says so.
                        Text {
                            anchors.centerIn: parent
                            visible: page.desktop !== null && page.firstShown < 0 && stage.showing
                            text: page.searching ? "Sin resultados" : "Escritorio vacío"
                            color: Kirigami.Theme.disabledTextColor
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                        }

                        Repeater {
                            model: page.entries

                            delegate: Item {
                                id: tile

                                required property var modelData
                                required property int index
                                readonly property var window: modelData.window
                                readonly property var from: modelData.from
                                readonly property var place: page.places[index] || null
                                readonly property bool isShown: page.shown[index] === true && place !== null
                                readonly property bool isChosen: stage.chosen === window
                                readonly property bool isSelected: page.selected === index && isShown
                                readonly property bool isDragged: stage.dragWindow !== null && stage.dragWindow === window
                                // While searching, the desktop it is on (if not this one).
                                readonly property var otherDesktop: page.onPage[index] ? null : root.desktopOf(window)
                                // Closing it from here: the thumbnail fades out while the
                                // others move to the new grid; then the real window, made
                                // invisible first (see the top), is closed. If it is still
                                // there a moment later (it asked something), it comes back.
                                property bool going: false
                                function closeIt() {
                                    going = true;
                                    stage.setLeaving(modelData.id, true);
                                    closeLater.start();
                                }
                                Timer {
                                    id: closeLater
                                    interval: root.duration
                                    onTriggered: {
                                        if (tile.window && !tile.window.deleted) {
                                            tile.window.opacity = 0;
                                            tile.window.closeWindow();
                                            stillThere.start();
                                        }
                                    }
                                }
                                Timer {
                                    id: stillThere
                                    interval: 1500
                                    onTriggered: {
                                        if (tile.window && !tile.window.deleted) {
                                            tile.window.opacity = 1;
                                            tile.going = false;
                                            stage.setLeaving(tile.modelData.id, false);
                                        }
                                    }
                                }

                                // Its last place in the grid, for fading out when filtered.
                                property var lastPlace: place
                                onPlaceChanged: if (place) lastPlace = place

                                // Where it is: its real place before opening and after
                                // closing (the chosen one where it is now), the grid
                                // between. Those of other desktops have no real place
                                // in view: they fade. Pages away from view, the grid.
                                readonly property var target: {
                                    if (stage.opened) {
                                        return place || lastPlace;
                                    }
                                    if (!page.isCurrent) {
                                        return place || lastPlace;
                                    }
                                    if (root.closing) {
                                        if (isChosen && window && !window.deleted) {
                                            return stage.inScreen(window.frameGeometry);
                                        }
                                        return page.desktop === null || root.onDesktop(window, root.closingDesktop) ? from : null;
                                    }
                                    return page.onPage[index] ? from : null;
                                }
                                // Minimized ones have no place on screen: they grow in the grid.
                                readonly property var rect: target || (lastPlace ? Qt.rect(lastPlace.x + lastPlace.width / 2,
                                    lastPlace.y + lastPlace.height / 2, 1, 1) : Qt.rect(stage.width / 2, stage.height / 2, 1, 1))

                                x: rect.x
                                y: rect.y
                                width: rect.width
                                height: rect.height
                                z: isChosen ? 300 : (hover.containsMouse ? 200 : 100 + index)
                                readonly property bool gone: going || stage.removed[modelData.id] === true
                                opacity: gone ? 0 : !stage.opened ? (target ? 1 : 0)
                                    : (isShown ? (isDragged ? 0.25 : window && window.minimized ? 0.7 : 1) : 0)
                                scale: gone ? 0.85 : 1
                                Behavior on scale { NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
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
                                    wId: tile.modelData.wid
                                }

                                // A click chooses it; dragging it (on the primary
                                // screen) takes it to a desktop of the strip.
                                MouseArea {
                                    id: hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: stage.showing
                                    property point pressedAt: Qt.point(0, 0)
                                    property bool dragging: false
                                    onEntered: if (!stage.dragWindow) page.selected = tile.index
                                    onPressed: mouse => {
                                        pressedAt = Qt.point(mouse.x, mouse.y);
                                        dragging = false;
                                    }
                                    onPositionChanged: mouse => {
                                        if (!pressed) {
                                            return;
                                        }
                                        if (!dragging && stage.isPrimary
                                                && Math.abs(mouse.x - pressedAt.x) + Math.abs(mouse.y - pressedAt.y) > 12) {
                                            dragging = true;
                                            stage.startDrag(tile.window, Qt.size(tile.width, tile.height));
                                        }
                                        if (dragging) {
                                            stage.dragTo(mapToItem(content, mouse.x, mouse.y));
                                        }
                                    }
                                    onReleased: {
                                        if (dragging) {
                                            dragging = false;
                                            stage.endDrag();
                                        } else if (containsMouse) {
                                            root.close(tile.window);
                                        }
                                    }
                                    onCanceled: {
                                        if (dragging) {
                                            dragging = false;
                                            stage.cancelDrag();
                                        }
                                    }
                                }

                                // Close, the ball of the window decoration.
                                Item {
                                    visible: stage.showing && !stage.dragWindow && (hover.containsMouse || closeMouse.containsMouse)
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

                                // Icon and title below; while searching, the number
                                // of its desktop (grey for the one in view).
                                Row {
                                    anchors.top: parent.bottom
                                    anchors.topMargin: Kirigami.Units.smallSpacing * 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Kirigami.Units.smallSpacing * 2
                                    opacity: stage.showing ? 1 : 0
                                    Behavior on opacity { enabled: stage.animate; NumberAnimation { duration: root.duration } }
                                    readonly property bool badged: page.searching && page.desktop !== null
                                        && KWin.Workspace.desktops.length > 1 && !!tile.window && !tile.window.onAllDesktops
                                    Kirigami.Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                        source: tile.window ? tile.window.icon : ""
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(implicitWidth, Math.max(tile.width - Kirigami.Units.iconSizes.small - Kirigami.Units.smallSpacing * 2
                                            - (desktopBadge.visible ? desktopBadge.width + Kirigami.Units.smallSpacing * 2 : 0), Kirigami.Units.gridUnit * 6))
                                        text: tile.window ? tile.window.caption : ""
                                        color: Kirigami.Theme.textColor
                                        elide: Text.ElideRight
                                    }
                                    Badge {
                                        id: desktopBadge
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.badged
                                        accent: tile.otherDesktop !== null
                                        text: {
                                            const d = tile.otherDesktop || page.desktop;
                                            return root.isFullscreenDesktop(d) ? "⛶" : root.desktopLabel(d);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // The thumbnail being dragged, under the pointer: smaller over
                // the strip, as big as a desktop there.
                Loader {
                    z: 500
                    active: stage.dragWindow !== null
                    sourceComponent: Item {
                        id: ghost
                        readonly property bool small: stage.dragPoint.y < stage.area.y
                        readonly property real factor: {
                            const s = stage.dragSize;
                            if (s.width <= 0 || s.height <= 0) {
                                return 1;
                            }
                            return small ? Math.min(stage.thumbWidth * 0.9 / s.width, stage.thumbHeight * 0.9 / s.height)
                                         : Math.min(1, Math.max(stage.thumbWidth * 2 / s.width, 0.5));
                        }
                        width: stage.dragSize.width * factor
                        height: stage.dragSize.height * factor
                        x: stage.dragPoint.x - width / 2
                        y: stage.dragPoint.y - height / 2
                        opacity: 0.9
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        KWin.WindowThumbnail {
                            anchors.fill: parent
                            wId: stage.dragWindow ? stage.dragWindow.internalId : undefined
                        }
                        // A light line, so a dark window is seen over the strip.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: 6
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(1, 1, 1, 0.8)
                        }
                    }
                }
            }
        }
    }
}
