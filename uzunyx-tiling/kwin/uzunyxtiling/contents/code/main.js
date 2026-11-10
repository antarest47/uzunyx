/*
 * Automatic tiling, off until chosen (uzunyx-tiling, the tray widget). Lays
 * out the windows of each desktop and screen inside the maximize area, so it
 * follows the margins of edge-gaps and the panel, and both Uzunyx modes:
 *   normal  2 px between windows, inside the margins;
 *   focus   the area is the whole screen: no separation at all.
 * Tiled windows lose their decoration; uzunyx-outline rounds them and draws
 * their border. Apps that draw their own frame keep it.
 *
 * Scripts cannot receive D-Bus calls, so the mode arrives as one shortcut
 * without keys for each; uzunyx-tiling also saves it for the next login.
 *
 * Shortcuts, all for the left hand: Meta+Shift+W/A/S swap with the neighbour
 * (without tiling, they stick the window to that edge), Meta+E rotates the
 * window through the places, Meta+Shift+E floats, Meta+R brings to the main
 * place, Meta+Z/X resize the main place.
 * Alt+E and Alt+Q, with or without tiling, take the window to the next or
 * previous desktop, and follow it: past the last one a desktop is created, and
 * the one left empty is removed.
 *
 * Resizing a tiled window with the mouse (Meta + right button, or the frame of
 * apps that draw their own) moves the divisions it touches, and its neighbours
 * follow. A new window stays invisible until it has its place.
 */

const GAP = 2;
const MAXIMIZE_NONE = 0;
// The shortcuts window (uzunyx-keys) floats, without a title bar.
const KEYS_WINDOW = "org.uzunyx.keys";
const SHARE_STEP = 0.05;
const SHARE_MIN = 0.1;
const SHARE_MAX = 0.9;
// How long a new window may take to get its size before it's shown anyway.
const REVEAL_TIMEOUT = 500;
// Once placed, a new window waits while the others shrink to make room (the
// uzunyxtilemotion effect animates them), then grows in.
const MAKE_ROOM = 180;
// The motion effect, loaded only while tiling is on.
const MOTION_EFFECT = "uzunyxtilemotion";
// Resize handles over the divisions (uzunyx-tiling-handles): this much wider
// than the gap on each side.
const HANDLE_MARGIN = 2;
const DRAG_TICK = 16;
// Desktops of the macfullscreen script: their windows are left alone.
const FULLSCREEN_DESKTOP = "⛶ ";

// The modes were called "qtile" and "hyprland" before 0.5.0.
const OLD_MODES = { qtile: "stack", hyprland: "spiral" };
let mode = readConfig("Mode", "off");
mode = OLD_MODES[mode] || mode;
// Tile order; a window's place decides its share of the layout.
let order = [];
// internalId -> { geometry, noBorder } to give back
const saved = new Map();
// internalId of the windows floating above the tiling
const floating = new Set();
// By output and desktop (see groupKey()): { count, ratios }, the share of each
// division that was changed, and the divisions as they were last laid out.
const sizes = new Map();
const divisions = new Map();
// Frame of the window being resized, as of the last change.
let resizingFrom = null;
// The handles on screen, and what was last sent for them.
let handleList = [];
let shownHandles = null;
let applying = false;

function key(w) {
    return w.internalId.toString();
}

function eligible(w) {
    return w.normalWindow && !w.transient && w.resizeable && w.moveable && !w.skipTaskbar
        && !w.specialWindow && w.resourceClass !== "org.kde.plasmashell" && w.resourceClass !== KEYS_WINDOW
        && w.desktops.length === 1;
}

function isFullscreen(w) {
    return w.fullScreen || w.desktops.some(d => d.name.indexOf(FULLSCREEN_DESKTOP) === 0);
}

function tileable(w) {
    return eligible(w) && !w.minimized && !isFullscreen(w) && !floating.has(key(w));
}

function groupKey(w) {
    return w.output.name + "|" + w.desktops[0].id;
}

// The tiled windows sharing a layout with w, in order.
function groupOf(w) {
    return order.filter(other => tileable(other) && groupKey(other) === groupKey(w));
}

// Client-side decorated: KWin draws no frame, so frame == client geometry.
function drawsOwnFrame(w) {
    return w.frameGeometry.width === w.clientGeometry.width && w.frameGeometry.height === w.clientGeometry.height;
}

// Every layout is a series of divisions of what the previous one left.
function divide(count, rect, gap, ratios, sideBySide, defaultRatio) {
    const rects = [];
    const made = [];
    let rest = rect;
    for (let i = 0; i < count - 1; i++) {
        const horizontal = sideBySide(rest, i);
        const ratio = ratios[i] !== undefined ? ratios[i] : defaultRatio(i);
        const start = horizontal ? rest.x : rest.y;
        const length = (horizontal ? rest.width : rest.height) - gap;
        const first = Math.floor(length * ratio);
        made.push({ index: i, horizontal: horizontal, start: start, length: length, border: start + first,
                    across: horizontal ? rest.y : rest.x, acrossLength: horizontal ? rest.height : rest.width });
        rects.push(horizontal
            ? { x: rest.x, y: rest.y, width: first, height: rest.height }
            : { x: rest.x, y: rest.y, width: rest.width, height: first });
        rest = horizontal
            ? { x: rest.x + first + gap, y: rest.y, width: rest.width - first - gap, height: rest.height }
            : { x: rest.x, y: rest.y + first + gap, width: rest.width, height: rest.height - first - gap };
    }
    rects.push(rest);
    return { rects: rects, divisions: made };
}

// Spiral (dwindle in Hyprland): each window halves what the previous one left,
// along its longer side, so the shares stay close to the screen's shape.
function dwindle(count, rect, gap, ratios) {
    return divide(count, rect, gap, ratios, rest => rest.width >= rest.height, () => 0.5);
}

// Main and stack (MonadTall in Qtile): the first window on the left, the others
// stacked beside it in equal parts.
function monadTall(count, rect, gap, ratios) {
    return divide(count, rect, gap, ratios, (rest, i) => i === 0, i => i === 0 ? 0.5 : 1 / (count - i));
}

function same(a, b) {
    return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
}

function take(w) {
    if (!saved.has(key(w))) {
        const f = w.frameGeometry;
        saved.set(key(w), { geometry: { x: f.x, y: f.y, width: f.width, height: f.height }, noBorder: w.noBorder });
    }
    if (w.maximizeMode !== MAXIMIZE_NONE) {
        w.setMaximize(false, false);
    }
    if (!w.noBorder && !drawsOwnFrame(w)) {
        w.noBorder = true;
    }
}

function release(w) {
    const previous = saved.get(key(w));
    // A fullscreen window waits: this runs again once it leaves.
    if (!previous || isFullscreen(w)) {
        return;
    }
    saved.delete(key(w));
    w.noBorder = previous.noBorder;
    w.frameGeometry = previous.geometry;
}

function layOut() {
    if (applying) {
        return;
    }
    applying = true;
    if (mode === "off") {
        order.forEach(release);
        showHandles([]);
        applying = false;
        return;
    }
    const groups = new Map();
    for (const w of order) {
        if (!tileable(w)) {
            continue;
        }
        const group = groupKey(w);
        if (!groups.has(group)) {
            groups.set(group, []);
        }
        groups.get(group).push(w);
    }
    const arrange = mode === "stack" ? monadTall : dwindle;
    for (const [group, windows] of groups) {
        const first = windows[0];
        const area = workspace.clientArea(KWin.MaximizeArea, first.output, first.desktops[0]);
        const screen = workspace.clientArea(KWin.FullScreenArea, first.output, first.desktops[0]);
        const gap = same(area, screen) ? 0 : GAP;
        const laid = arrange(windows.length, area, gap, sizesOf(group, windows.length).ratios);
        const rects = laid.rects;
        divisions.set(group, laid.divisions);
        windows.forEach((w, i) => {
            if (w.move || w.resize) {
                return;
            }
            take(w);
            if (!same(w.frameGeometry, rects[i])) {
                w.frameGeometry = rects[i];
            }
        });
    }
    showHandles(handles(groups));
    applying = false;
}

function overlaps(a, b) {
    return a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
}

// What may be on top of a division: windows, menus, Plasma's popups. Not the
// handles themselves, which KWin lists as normal windows: they're told by
// having the geometry of one.
function coverable(w) {
    return (w.normalWindow || w.dialog || w.utility || w.popupWindow || w.appletPopup) && !w.deleted
        && !handleList.some(h => same(w.frameGeometry, h));
}

// Strips over the divisions of the tiles on screen, left out where something
// else is on top of them (a floating window, a menu, Tsunyx).
function handles(groups) {
    const list = [];
    for (const [group, windows] of groups) {
        const first = windows[0];
        if (workspace.currentDesktopForScreen(first.output) !== first.desktops[0]) {
            continue;
        }
        const area = workspace.clientArea(KWin.MaximizeArea, first.output, first.desktops[0]);
        const screen = workspace.clientArea(KWin.FullScreenArea, first.output, first.desktops[0]);
        const gap = same(area, screen) ? 0 : GAP;
        for (const d of divisions.get(group) || []) {
            const strip = d.horizontal
                ? { x: d.border - HANDLE_MARGIN, y: d.across, width: gap + 2 * HANDLE_MARGIN, height: d.acrossLength }
                : { x: d.across, y: d.border - HANDLE_MARGIN, width: d.acrossLength, height: gap + 2 * HANDLE_MARGIN };
            const covered = workspace.stackingOrder.some(w => coverable(w) && !same(w.frameGeometry, strip)
                && !w.minimized && !w.hidden && windows.indexOf(w) < 0 && (w.onAllDesktops || w.desktops.indexOf(first.desktops[0]) >= 0)
                && w.output === first.output && overlaps(w.frameGeometry, strip));
            if (!covered) {
                strip.horizontal = d.horizontal;
                strip.group = group;
                strip.index = d.index;
                list.push(strip);
            }
        }
    }
    return list;
}

function showHandles(list) {
    handleList = list;
    const text = JSON.stringify(list.map(h => ({ x: h.x, y: h.y, width: h.width, height: h.height, horizontal: h.horizontal })));
    if (text !== shownHandles && !(shownHandles === null && list.length === 0)) {
        shownHandles = text;
        callDBus("org.uzunyx.TilingHandles", "/org/uzunyx/TilingHandles", "org.uzunyx.TilingHandles", "Set", text);
    }
}

// A handle pressed: its division follows the pointer until it's released.
let dragging = null;
const dragTimer = new QTimer();
dragTimer.interval = DRAG_TICK;
dragTimer.timeout.connect(() => {
    const division = dragging && (divisions.get(dragging.group) || []).find(d => d.index === dragging.index);
    const windows = dragging && order.filter(w => tileable(w) && groupKey(w) === dragging.group);
    if (!division || !windows.length) {
        return;
    }
    const pointer = workspace.cursorPos;
    const ratio = ((division.horizontal ? pointer.x : pointer.y) - division.start) / division.length;
    sizesOf(dragging.group, windows.length).ratios[division.index] = Math.min(SHARE_MAX, Math.max(SHARE_MIN, ratio));
    layOut();
});

function dragStart() {
    const pointer = workspace.cursorPos;
    const near = 4;
    const handle = handleList.find(h => pointer.x >= h.x - near && pointer.x < h.x + h.width + near
        && pointer.y >= h.y - near && pointer.y < h.y + h.height + near);
    if (mode === "off" || !handle) {
        return;
    }
    dragging = { group: handle.group, index: handle.index };
    // Every step moves the windows: the motion effect would trail behind.
    callDBus("org.kde.KWin", "/Effects", "org.kde.kwin.Effects", "unloadEffect", MOTION_EFFECT);
    dragTimer.start();
}

function dragEnd() {
    if (dragging) {
        dragging = null;
        dragTimer.stop();
        useMotion();
        layOut();
    }
}

// Dropping a window on another one swaps them.
function dropped(w) {
    const index = order.indexOf(w);
    if (mode === "off" || index < 0 || !tileable(w)) {
        return;
    }
    const cursor = workspace.cursorPos;
    const target = order.find(other => {
        const f = other.frameGeometry;
        return other !== w && tileable(other) && other.output === w.output && other.desktops[0] === w.desktops[0]
            && cursor.x >= f.x && cursor.x < f.x + f.width && cursor.y >= f.y && cursor.y < f.y + f.height;
    });
    if (target) {
        swap(w, target);
    }
    layOut();
}

function swap(a, b) {
    const first = order.indexOf(a);
    const second = order.indexOf(b);
    order[first] = b;
    order[second] = a;
}

function sizesOf(group, count) {
    let state = sizes.get(group);
    if (!state) {
        state = { count: count, ratios: [] };
        sizes.set(group, state);
    }
    // With another number of windows only the main place keeps its size.
    if (state.count !== count) {
        state.count = count;
        state.ratios = state.ratios.slice(0, 1);
    }
    return state;
}

// Moves the divisions at the edges of w that changed. A window only touches the
// divisions up to its own place.
function followResize(w, from, to) {
    const group = groupKey(w);
    const made = divisions.get(group) || [];
    const place = groupOf(w).indexOf(w);
    const edges = [
        [true, from.x, to.x], [true, from.x + from.width, to.x + to.width],
        [false, from.y, to.y], [false, from.y + from.height, to.y + to.height],
    ];
    for (const [horizontal, before, after] of edges) {
        const division = before === after ? null : made.find(d => d.horizontal === horizontal
            && d.index <= place && Math.abs(d.border - before) <= GAP + 1);
        if (division) {
            const ratio = (after - division.start) / division.length;
            sizesOf(group, groupOf(w).length).ratios[division.index] = Math.min(SHARE_MAX, Math.max(SHARE_MIN, ratio));
        }
    }
}

function copyOf(f) {
    return { x: f.x, y: f.y, width: f.width, height: f.height };
}

function activeTiled() {
    const w = workspace.activeWindow;
    return mode !== "off" && w && tileable(w) ? w : null;
}

function center(w) {
    const f = w.frameGeometry;
    return { x: f.x + f.width / 2, y: f.y + f.height / 2 };
}

// Swaps with the nearest window in that direction, or sticks a free window to
// that edge. What lies straight ahead counts as nearer than what's off to a side.
function moveWindow(dx, dy, stickToEdge) {
    const w = activeTiled();
    if (!w) {
        if (mode === "off" || (workspace.activeWindow && floating.has(key(workspace.activeWindow)))) {
            stickToEdge();
        }
        return;
    }
    const from = center(w);
    let best = null;
    let bestDistance = Infinity;
    for (const other of groupOf(w)) {
        const to = center(other);
        const ahead = (to.x - from.x) * dx + (to.y - from.y) * dy;
        const aside = Math.abs((to.x - from.x) * dy + (to.y - from.y) * dx);
        if (other !== w && ahead > 0 && ahead + aside * 2 < bestDistance) {
            best = other;
            bestDistance = ahead + aside * 2;
        }
    }
    if (best) {
        swap(w, best);
        layOut();
    }
}

function toggleFloating() {
    const w = workspace.activeWindow;
    if (mode === "off" || !w || !eligible(w) || isFullscreen(w)) {
        return;
    }
    if (floating.delete(key(w))) {
        w.keepAbove = false;
    } else {
        floating.add(key(w));
        w.keepAbove = true;
        release(w);
    }
    layOut();
}

// To the main place; from there, the next window takes it.
function promote() {
    const w = activeTiled();
    if (!w) {
        return;
    }
    const windows = groupOf(w);
    if (windows.length > 1) {
        swap(w, windows[0] === w ? windows[1] : windows[0]);
        layOut();
    }
}

// One place further each time, the others keeping their order: after going
// through them all, everything is where it started.
function rotate() {
    const w = activeTiled();
    if (!w) {
        return;
    }
    const windows = groupOf(w);
    const slots = windows.map(other => order.indexOf(other));
    const place = (windows.indexOf(w) + 1) % windows.length;
    const others = windows.filter(other => other !== w);
    others.splice(place, 0, w);
    others.forEach((other, i) => order[slots[i]] = other);
    layOut();
}

function moveToDesktop(step) {
    const w = workspace.activeWindow;
    if (!w || !eligible(w) || isFullscreen(w)) {
        return;
    }
    const from = w.desktops[0];
    const index = workspace.desktops.indexOf(from);
    const next = index + step;
    if (next < 0) {
        return;
    }
    if (next >= workspace.desktops.length) {
        // Alone on the last desktop, a new one would only replace it.
        if (workspace.windowList().filter(other => other !== w && other.normalWindow && !other.skipTaskbar
                && !other.onAllDesktops && other.desktops.indexOf(from) >= 0).length === 0) {
            return;
        }
        workspace.createDesktop(next, "Escritorio " + (next + 1));
    }
    const target = workspace.desktops[next];
    w.desktops = [target];
    workspace.currentDesktop = target;
    workspace.activeWindow = w;
    // The one left empty goes away by uzunyxdesktops.
    layOut();
}

function resizeMain(change) {
    const w = activeTiled();
    if (w) {
        const state = sizesOf(groupKey(w), groupOf(w).length);
        const share = (state.ratios[0] !== undefined ? state.ratios[0] : 0.5) + change;
        state.ratios[0] = Math.min(SHARE_MAX, Math.max(SHARE_MIN, share));
        layOut();
    }
}

// Back to the sizes of the layout, undoing the mouse and Super+Z/X.
function resetSizes() {
    const w = activeTiled();
    if (w) {
        sizes.delete(groupKey(w));
        layOut();
    }
}

function add(w) {
    if (eligible(w) && order.indexOf(w) < 0) {
        order.push(w);
    }
}

function setup(w) {
    if (w.resourceClass === KEYS_WINDOW) {
        w.noBorder = true;
    }
    add(w);
    w.minimizedChanged.connect(layOut);
    w.fullScreenChanged.connect(layOut);
    w.desktopsChanged.connect(layOut);
    w.outputChanged.connect(layOut);
    w.interactiveMoveResizeStarted.connect(() => resizingFrom = copyOf(w.frameGeometry));
    w.frameGeometryChanged.connect(() => {
        if (w.resize && resizingFrom && mode !== "off" && tileable(w)) {
            followResize(w, resizingFrom, w.frameGeometry);
            resizingFrom = copyOf(w.frameGeometry);
            layOut();
        }
    });
    w.interactiveMoveResizeFinished.connect(() => {
        resizingFrom = null;
        dropped(w);
    });
}

// A new window is first drawn with its own size: it stays invisible until it has
// the one of its place, and then until the others made room, if there are any.
function hideUntilPlaced(w) {
    let shown = false;
    const timer = new QTimer();
    const reveal = () => {
        if (!shown) {
            shown = true;
            timer.stop();
            w.opacity = 1;
        }
    };
    const placed = () => {
        w.frameGeometryChanged.disconnect(placed);
        if (groupOf(w).length > 1) {
            timer.interval = MAKE_ROOM;
            timer.start();
        } else {
            reveal();
        }
    };
    w.opacity = 0;
    timer.singleShot = true;
    timer.interval = REVEAL_TIMEOUT;
    timer.timeout.connect(reveal);
    timer.start();
    w.frameGeometryChanged.connect(placed);
}

function useMotion() {
    callDBus("org.kde.KWin", "/Effects", "org.kde.kwin.Effects", mode === "off" ? "unloadEffect" : "loadEffect",
             MOTION_EFFECT);
}

function setMode(next) {
    mode = next;
    // The divisions of one layout mean nothing in the other: only the main place stays.
    sizes.forEach(state => state.ratios = state.ratios.slice(0, 1));
    if (mode !== "off") {
        workspace.windowList().forEach(add);
    } else {
        order.filter(w => floating.has(key(w))).forEach(w => w.keepAbove = false);
        floating.clear();
    }
    useMotion();
    layOut();
}

workspace.windowList().forEach(setup);
workspace.windowAdded.connect(w => {
    setup(w);
    if (mode !== "off" && tileable(w)) {
        hideUntilPlaced(w);
    }
    layOut();
});
// The handles are those of the desktop on screen, and something may now cover them.
workspace.currentDesktopChanged.connect(layOut);
workspace.windowActivated.connect(layOut);
workspace.windowRemoved.connect(w => {
    order = order.filter(other => other !== w);
    saved.delete(key(w));
    floating.delete(key(w));
    layOut();
});

registerShortcut("UzunyxTilingOff", "Mosaico: apagado", "", () => setMode("off"));
registerShortcut("UzunyxTilingStack", "Mosaico: principal y pila", "", () => setMode("stack"));
registerShortcut("UzunyxTilingSpiral", "Mosaico: espiral", "", () => setMode("spiral"));
registerShortcut("UzunyxTilingMoveUp", "Mosaico: intercambiar o pegar arriba", "Meta+Shift+W",
                 () => moveWindow(0, -1, () => workspace.slotWindowQuickTileTop()));
registerShortcut("UzunyxTilingMoveLeft", "Mosaico: intercambiar o pegar a la izquierda", "Meta+Shift+A",
                 () => moveWindow(-1, 0, () => workspace.slotWindowQuickTileLeft()));
registerShortcut("UzunyxTilingMoveDown", "Mosaico: intercambiar o pegar abajo", "Meta+Shift+S",
                 () => moveWindow(0, 1, () => workspace.slotWindowQuickTileBottom()));
registerShortcut("UzunyxTilingRotate", "Mosaico: rotar la ventana por los lugares", "Meta+E", rotate);
registerShortcut("UzunyxWindowDesktopNext", "Llevar la ventana al escritorio siguiente, creándolo si hace falta", "Alt+E", () => moveToDesktop(1));
registerShortcut("UzunyxWindowDesktopPrevious", "Llevar la ventana al escritorio anterior", "Alt+Q", () => moveToDesktop(-1));
registerShortcut("UzunyxTilingFloat", "Mosaico: flotar la ventana", "Meta+Shift+E", toggleFloating);
registerShortcut("UzunyxTilingPromote", "Mosaico: al lugar principal", "Meta+R", promote);
registerShortcut("UzunyxTilingShrink", "Mosaico: achicar el lugar principal", "Meta+Z", () => resizeMain(-SHARE_STEP));
registerShortcut("UzunyxTilingGrow", "Mosaico: agrandar el lugar principal", "Meta+X", () => resizeMain(SHARE_STEP));
registerShortcut("UzunyxTilingReset", "Mosaico: volver a los tamaños por defecto", "Meta+Shift+Z", resetSizes);
// Invoked by uzunyx-tiling-handles, without keys.
registerShortcut("UzunyxTilingDragStart", "Mosaico: empezar a mover una división", "", dragStart);
registerShortcut("UzunyxTilingDragEnd", "Mosaico: terminar de mover una división", "", dragEnd);

// KWin has no signal for the maximize area changing (uzunyx-mode, panels), and
// other things move windows: check once a second.
const timer = new QTimer();
timer.interval = 1000;
timer.timeout.connect(layOut);
timer.start();
useMotion();
layOut();
