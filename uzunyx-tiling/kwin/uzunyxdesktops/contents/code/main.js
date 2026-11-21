/*
 * Dynamic virtual desktops. An empty desktop that isn't on screen goes away:
 * checked when the desktop changes and when a window closes or changes desktop,
 * so a desktop stays while you're on it, even if you close its last window.
 * Unlike GNOME, there's no spare one waiting: Alt+D on the last desktop makes it.
 *
 * Minimized windows count; those on all desktops, and Plasma's, don't. With desktops
 * per screen (Plasma 6.7), the one shown on any screen stays. Nothing goes away while
 * macfullscreen has a desktop, because the window goes back to the one it came from.
 *
 * Desktops only on the primary screen, as GNOME does: a window on another screen is
 * put on all desktops, so it stays when the primary changes desktop, and comes back
 * to one desktop, the current, when it is moved to the primary. Only the windows this
 * script put on all desktops are given back one (one the user pinned stays pinned).
 * The primary is the first of workspace.screenOrder (the laptop's, unless another
 * screen is set as primary).
 */
const FULLSCREEN_DESKTOP = "⛶ ";
// Windows of the previous session may still be on their way.
const STARTUP_MS = 30000;
// Several changes in a row (moving a window also switches desktop) count as one.
const SETTLE_MS = 150;

let ready = false;
const startup = new QTimer();
startup.singleShot = true;
startup.interval = STARTUP_MS;
// Then once: the empty desktops left from the session before (or emptied in
// the meantime) go now, not at the next change.
startup.timeout.connect(() => {
    ready = true;
    sweep();
});
startup.start();

const settle = new QTimer();
settle.singleShot = true;
settle.interval = SETTLE_MS;
settle.timeout.connect(sweep);

// internalIds of the windows put on all desktops for being on another screen.
const pinned = new Set();

function primary() {
    const order = workspace.screenOrder;
    return order && order.length > 0 ? order[0] : workspace.activeScreen;
}

// The task manager's windows: dialogs that belong to one follow it, and
// fullscreen ones keep what macfullscreen (or the app) decided.
function followsScreen(w) {
    return (w.normalWindow || w.dialog) && !w.transient && !w.skipTaskbar && !w.deleted
        && !w.fullScreen && !w.desktops.some(isFullscreenDesktop)
        && w.resourceClass !== "org.kde.plasmashell"
        // The window view's own windows (uzunyxwindowview, uzunyx-deco).
        && String(w.caption).indexOf("Uzunyx window view") !== 0;
}

function place(w) {
    if (!followsScreen(w)) {
        return;
    }
    const id = w.internalId.toString();
    const elsewhere = workspace.screens.length > 1 && w.output !== primary();
    if (elsewhere && !w.onAllDesktops) {
        pinned.add(id);
        w.onAllDesktops = true;
    } else if (!elsewhere && pinned.has(id)) {
        pinned.delete(id);
        w.onAllDesktops = false;
        w.desktops = [workspace.currentDesktop];
    }
}

function placeAll() {
    workspace.windowList().forEach(place);
}

function isFullscreenDesktop(desktop) {
    return desktop.name.indexOf(FULLSCREEN_DESKTOP) === 0;
}

function isEmpty(desktop) {
    return !workspace.windowList().some(w => (w.normalWindow || w.dialog) && !w.skipTaskbar && !w.onAllDesktops
        && w.desktops.indexOf(desktop) >= 0);
}

function onScreen(desktop) {
    return desktop === workspace.currentDesktop
        || workspace.screens.some(screen => workspace.currentDesktopForScreen(screen) === desktop);
}

function sweep() {
    if (!ready || workspace.desktops.some(isFullscreenDesktop)) {
        return;
    }
    workspace.desktops.filter(d => !onScreen(d) && isEmpty(d)).forEach(d => {
        if (workspace.desktops.length > 1) {
            workspace.removeDesktop(d);
        }
    });
}

function next() {
    const current = workspace.currentDesktop;
    const index = workspace.desktops.indexOf(current);
    if (index === workspace.desktops.length - 1) {
        // An empty one has nothing to extend.
        if (isEmpty(current) || isFullscreenDesktop(current)) {
            return;
        }
        workspace.createDesktop(index + 1, "Escritorio " + (index + 2));
    }
    workspace.currentDesktop = workspace.desktops[index + 1];
}

function watch(w) {
    w.desktopsChanged.connect(() => settle.start());
    w.outputChanged.connect(() => place(w));
    // Leaving fullscreen on another screen: back on all desktops.
    w.fullScreenChanged.connect(() => place(w));
    place(w);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);
workspace.windowRemoved.connect(() => settle.start());
workspace.currentDesktopChanged.connect(() => settle.start());
workspace.screensChanged.connect(placeAll);
if (workspace.screenOrderChanged) {
    workspace.screenOrderChanged.connect(placeAll);
}

registerShortcut("UzunyxDesktopNext", "Ir al escritorio siguiente, creándolo si hace falta", "Alt+D", next);
