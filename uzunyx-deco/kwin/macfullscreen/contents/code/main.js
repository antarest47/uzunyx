/*
 * macOS-like fullscreen: the active window goes fullscreen on a new virtual
 * desktop of its own, and the view slides to it. Coming back (the same shortcut
 * or menu entry, leaving fullscreen some other way, or closing the window) puts
 * it back on its desktops, removes the new one and returns to the first.
 */

// Marks the desktops this script makes, to find the ones left from a session
// that ended while a window was fullscreen.
const NAME_PREFIX = "⛶ ";

// internalId -> { window, desktop, homes (ids of its own desktops) }
const entries = new Map();
let busy = false;

function key(w) {
    return w.internalId.toString();
}

// The panel on a fullscreen desktop: "windows go below", in both Uzunyx modes. A
// hidden panel (focus mode) wouldn't come back, and a normal one sticks to the
// edge when a window touches it. Plasma only rereads whether it floats when
// something else changes, hence the toggle. Elsewhere, what the mode says. The
// script reads "none" for this value, so the state is kept here.
const PANEL_REFLOAT = `
        p.floating = !p.floating;
        p.floating = !p.floating;`;
const PANEL_ABOVE = `panels().forEach(function (p) {
    if (p.location === "bottom") {
        p.hiding = "windowsgobelow";${PANEL_REFLOAT}
    }
});`;
const PANEL_MODE = `var mode = ConfigFile("edge-gapsrc");
mode.group = "General";
panels().forEach(function (p) {
    if (p.location === "bottom") {
        p.hiding = mode.readEntry("Enabled") === "false" ? "dodgewindows" : "none";${PANEL_REFLOAT}
    }
});`;
let panelAbove = false;

function panelScript(script) {
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", script);
}

function updatePanel() {
    const above = workspace.currentDesktop.name.indexOf(NAME_PREFIX) === 0;
    if (above !== panelAbove) {
        panelAbove = above;
        panelScript(above ? PANEL_ABOVE : PANEL_MODE);
    }
}

// A fullscreen window covers the panel. With the pointer against the bottom
// edge it drops below the panel until the pointer goes away. By watching the
// pointer: a registered screen edge makes KWin draw a glow there, in any window.
const PANEL_ZONE = 90;
let revealed = null;
const pointerTimer = new QTimer();
pointerTimer.interval = 150;
pointerTimer.timeout.connect(() => {
    const w = workspace.activeWindow;
    const area = workspace.clientArea(KWin.FullScreenArea, workspace.activeScreen, workspace.currentDesktop);
    const bottom = area.y + area.height;
    const y = workspace.cursorPos.y;
    if (revealed) {
        if (y < bottom - PANEL_ZONE || !entries.has(key(revealed))) {
            hidePanel();
        }
    } else if (w && entries.has(key(w)) && y >= bottom - 2) {
        revealed = w;
        w.keepBelow = true;
        // uzunyx-mode may have changed it meanwhile.
        panelScript(`panels().forEach(function (p) { if (p.location === "bottom") { p.hiding = "windowsgobelow"; } });`);
    }
});

function hidePanel() {
    if (revealed) {
        revealed.keepBelow = false;
        revealed = null;
    }
}

function updateWatching() {
    if (entries.size > 0) {
        pointerTimer.start();
    } else {
        pointerTimer.stop();
    }
}

let pendingFocus = null;
const focusTimer = new QTimer();
focusTimer.singleShot = true;
focusTimer.interval = 150;
focusTimer.timeout.connect(() => {
    if (pendingFocus && !pendingFocus.deleted) {
        workspace.activeWindow = pendingFocus;
    }
    pendingFocus = null;
});

function eligible(w) {
    return w && w.normalWindow && w.fullScreenable && !w.skipTaskbar
        && w.resourceClass !== "org.kde.plasmashell";
}

function removeDesktop(desktop) {
    if (workspace.desktops.length > 1 && workspace.desktops.some(d => d.id === desktop.id)) {
        workspace.removeDesktop(desktop);
    }
}

function enter(w) {
    const position = workspace.desktops.length;
    workspace.createDesktop(position, NAME_PREFIX + w.caption.slice(0, 40));
    const desktop = workspace.desktops[position];
    if (!desktop) {
        return;
    }
    busy = true;
    entries.set(key(w), { window: w, desktop: desktop, homes: w.desktops.map(d => d.id) });
    w.desktops = [desktop];
    w.fullScreen = true;
    workspace.currentDesktop = desktop;
    workspace.activeWindow = w;
    busy = false;
    updateWatching();
}

// The desktops to go back to: its own, or the first ordinary one if they're
// gone. Never one of the fullscreen desktops, or windows pile up there.
function homeDesktops(entry) {
    const ordinary = workspace.desktops.filter(d => d.name.indexOf(NAME_PREFIX) !== 0);
    const own = ordinary.filter(d => entry.homes.indexOf(d.id) >= 0);
    return own.length > 0 ? own : ordinary.slice(0, 1);
}

function leave(w, closing) {
    const entry = entries.get(key(w));
    if (!entry) {
        return;
    }
    if (revealed === w) {
        hidePanel();
    }
    entries.delete(key(w));
    busy = true;
    const homes = homeDesktops(entry);
    if (!closing) {
        w.fullScreen = false;
        if (homes.length > 0) {
            w.desktops = homes;
        }
    }
    if (homes.length > 0) {
        workspace.currentDesktop = homes[0];
    }
    removeDesktop(entry.desktop);
    busy = false;
    if (!closing) {
        // Once the desktop change has settled, or the focus goes to another window.
        pendingFocus = w;
        focusTimer.start();
    }
    updateWatching();
}

function toggle(w) {
    if (entries.has(key(w))) {
        leave(w, false);
    } else if (eligible(w)) {
        enter(w);
    }
}

function watch(w) {
    w.fullScreenChanged.connect(() => {
        if (!busy && !w.fullScreen && entries.has(key(w))) {
            leave(w, false);
        }
    });
    w.closed.connect(() => {
        if (pendingFocus === w) {
            pendingFocus = null;
        }
        leave(w, true);
    });
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);
workspace.currentDesktopChanged.connect(updatePanel);

// Leftovers of an earlier run (session restart, script reloaded): windows go
// back to an ordinary desktop and the fullscreen desktops are removed.
const leftovers = workspace.desktops.filter(d => d.name.indexOf(NAME_PREFIX) === 0);
const ordinary = workspace.desktops.filter(d => d.name.indexOf(NAME_PREFIX) !== 0);
if (leftovers.length > 0 && ordinary.length > 0) {
    workspace.windowList().forEach(w => {
        if (w.normalWindow && !w.onAllDesktops && w.desktops.every(d => d.name.indexOf(NAME_PREFIX) === 0)) {
            w.fullScreen = false;
            w.desktops = [ordinary[0]];
        }
    });
    if (workspace.currentDesktop.name.indexOf(NAME_PREFIX) === 0) {
        workspace.currentDesktop = ordinary[0];
    }
    leftovers.forEach(removeDesktop);
    // The session also left the panel as it was there. At login plasmashell
    // comes after KWin, so also a while later.
    const panelTimer = new QTimer();
    panelTimer.singleShot = true;
    panelTimer.interval = 15000;
    panelTimer.timeout.connect(() => panelScript(PANEL_MODE));
    panelTimer.start();
    panelScript(PANEL_MODE);
}

registerShortcut("UzunyxFullscreen", "Pantalla completa como macOS", "Meta+F", () => {
    if (workspace.activeWindow) {
        toggle(workspace.activeWindow);
    }
});

registerUserActionsMenu(w => {
    if (!entries.has(key(w)) && !eligible(w)) {
        return null;
    }
    return {
        text: "Pantalla completa en su propio escritorio",
        icon: "view-fullscreen",
        checkable: true,
        checked: entries.has(key(w)),
        triggered: () => toggle(w),
    };
});
