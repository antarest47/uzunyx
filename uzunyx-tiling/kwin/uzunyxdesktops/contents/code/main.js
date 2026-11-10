/*
 * Dynamic virtual desktops. An empty desktop that isn't on screen goes away:
 * checked when the desktop changes and when a window closes or changes desktop,
 * so a desktop stays while you're on it, even if you close its last window.
 * Unlike GNOME, there's no spare one waiting: Alt+D on the last desktop makes it.
 *
 * Minimized windows count; those on all desktops, and Plasma's, don't. With desktops
 * per screen (Plasma 6.7), the one shown on any screen stays. Nothing goes away while
 * macfullscreen has a desktop, because the window goes back to the one it came from.
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
startup.timeout.connect(() => ready = true);
startup.start();

const settle = new QTimer();
settle.singleShot = true;
settle.interval = SETTLE_MS;
settle.timeout.connect(sweep);

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
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);
workspace.windowRemoved.connect(() => settle.start());
workspace.currentDesktopChanged.connect(() => settle.start());

registerShortcut("UzunyxDesktopNext", "Ir al escritorio siguiente, creándolo si hace falta", "Alt+D", next);
