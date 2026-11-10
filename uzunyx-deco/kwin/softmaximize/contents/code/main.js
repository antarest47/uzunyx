/*
 * Soft maximize for client-side decorated windows (Firefox, Electron,
 * libadwaita...): when such a window gets fully maximized, turn it back
 * into a normal window that fills the maximize area instead, so the app
 * keeps drawing its rounded, non-maximized frame. It still respects panels
 * and edge-gaps margins. Maximizing it again restores its previous geometry.
 *
 * Windows with a server-side decoration are left alone: the uzunyx
 * decoration already keeps them rounded while truly maximized.
 */

const MAXIMIZE_FULL = 3;

// internalId -> geometry to restore to
const restoreGeometry = new Map();
// internalId -> maximize areas it was fitted to and may still be on
const fittedAreas = new Map();
// windows we are currently changing ourselves (ignore their signals)
const busy = new Set();

function key(w) {
    return w.internalId.toString();
}

function eligible(w) {
    // Plasma's own windows (e.g. fullscreen launchers like Tsunyx) and
    // windows hidden from the taskbar manage their own maximized state.
    return w.normalWindow && w.maximizable && w.resizeable && !w.fullScreen
        && !w.skipTaskbar && w.resourceClass !== "org.kde.plasmashell";
}

// Client-side decorated: KWin draws no frame, so frame == client geometry.
function drawsOwnFrame(w) {
    const f = w.frameGeometry;
    const c = w.clientGeometry;
    return f.width === c.width && f.height === c.height;
}

function maximizeArea(w) {
    return workspace.clientArea(KWin.MaximizeArea, w);
}

function sameRect(a, b) {
    return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
}

function copyRect(r) {
    return { x: r.x, y: r.y, width: r.width, height: r.height };
}

function softMaximize(w, previous) {
    busy.add(key(w));
    w.setMaximize(false, false);
    restoreGeometry.set(key(w), previous);
    w.frameGeometry = maximizeArea(w);
    fittedAreas.set(key(w), [copyRect(maximizeArea(w))]);
    busy.delete(key(w));
}

function softRestore(w) {
    const previous = restoreGeometry.get(key(w));
    restoreGeometry.delete(key(w));
    busy.add(key(w));
    w.setMaximize(false, false);
    if (previous) {
        w.frameGeometry = previous;
    }
    busy.delete(key(w));
}

function setup(w) {
    if (!eligible(w)) {
        return;
    }
    // Geometry right before a maximize request, used as restore geometry.
    let beforeMaximize = copyRect(w.frameGeometry);

    w.maximizedAboutToChange.connect(mode => {
        if (!busy.has(key(w)) && mode === MAXIMIZE_FULL) {
            beforeMaximize = copyRect(w.frameGeometry);
        }
    });

    w.maximizedChanged.connect(() => {
        if (busy.has(key(w)) || w.maximizeMode !== MAXIMIZE_FULL) {
            return;
        }
        if (restoreGeometry.has(key(w))) {
            // Maximize pressed on a soft-maximized window: toggle back.
            softRestore(w);
        } else if (drawsOwnFrame(w)) {
            softMaximize(w, beforeMaximize);
        }
    });

    // Dragging a soft-maximized window gives it back its previous size, like
    // a truly maximized one. Only the size: KWin keeps the grab point as a
    // fraction of the window size, so the window shrinks around the cursor.
    w.interactiveMoveResizeStarted.connect(() => {
        const previous = restoreGeometry.get(key(w));
        if (!w.move || !previous) {
            return;
        }
        restoreGeometry.delete(key(w));
        const f = w.frameGeometry;
        busy.add(key(w));
        w.frameGeometry = { x: f.x, y: f.y, width: previous.width, height: previous.height };
        busy.delete(key(w));
    });

    // Moving or resizing by hand makes it an ordinary window again.
    w.interactiveMoveResizeFinished.connect(() => {
        restoreGeometry.delete(key(w));
    });

    if (!drawsOwnFrame(w)) {
        return;
    }
    if (w.maximizeMode === MAXIMIZE_FULL) {
        // Opened already maximized.
        softMaximize(w, defaultRestoreGeometry(w));
    } else if (fillsMaximizeArea(w)) {
        // Soft-maximized before this script (re)started, e.g. after a KWin
        // restart or a package upgrade: its restore geometry was lost.
        restoreGeometry.set(key(w), defaultRestoreGeometry(w));
    }
}

function fillsMaximizeArea(w) {
    const a = maximizeArea(w);
    const f = w.frameGeometry;
    return f.x === a.x && f.y === a.y && f.width === a.width && f.height === a.height;
}

// 75% of the maximize area, centered.
function defaultRestoreGeometry(w) {
    const area = maximizeArea(w);
    const width = Math.round(area.width * 0.75);
    const height = Math.round(area.height * 0.75);
    return {
        x: area.x + Math.round((area.width - width) / 2),
        y: area.y + Math.round((area.height - height) / 2),
        width: width,
        height: height,
    };
}

// Keep soft-maximized windows filling the area when it changes (screens
// added/removed, panels or edge-gaps margins changing, e.g. uzunyx-mode).
function refit() {
    for (const w of workspace.windowList()) {
        // Fullscreen (macfullscreen) isn't to be fitted back into the area.
        if (!restoreGeometry.has(key(w)) || w.fullScreen) {
            continue;
        }
        const a = maximizeArea(w);
        const f = w.frameGeometry;
        // Something else gave it another size (the tiling script): no longer ours
        // to fit. By size: when the area changes KWin moves the window itself.
        // Each area it was fitted to counts until it gets there: the area can
        // change in steps (uzunyx-mode) faster than the app follows.
        const fitted = fittedAreas.get(key(w)) || [];
        if (fitted.length > 0 && !fitted.some(r => r.width === f.width && r.height === f.height)) {
            restoreGeometry.delete(key(w));
            fittedAreas.delete(key(w));
            continue;
        }
        fittedAreas.set(key(w), sameRect(a, f) ? [copyRect(a)] : fitted.concat(copyRect(a)));
        if (f.x !== a.x || f.y !== a.y || f.width !== a.width || f.height !== a.height) {
            busy.add(key(w));
            w.frameGeometry = a;
            busy.delete(key(w));
        }
    }
}

// A window that appears already maximized with a KWin decoration sometimes
// gets a decoration that is never painted (transparent title bar and
// borders): System Settings when it reopens maximized. Recreating it once
// (removing and restoring the border) fixes it.
function repaintDecoration(w) {
    if (eligible(w) && w.maximizeMode === MAXIMIZE_FULL && !w.noBorder && !drawsOwnFrame(w)) {
        w.noBorder = true;
        w.noBorder = false;
    }
}

workspace.windowList().forEach(setup);
workspace.windowAdded.connect(w => {
    repaintDecoration(w);
    setup(w);
});
workspace.windowRemoved.connect(w => {
    restoreGeometry.delete(key(w));
    fittedAreas.delete(key(w));
});
workspace.screensChanged.connect(refit);
workspace.virtualScreenGeometryChanged.connect(refit);
// KWin has no signal for the maximize area changing when a panel or
// edge-gaps changes its reserved space, so check it once a second.
const refitTimer = new QTimer();
refitTimer.interval = 1000;
refitTimer.timeout.connect(refit);
refitTimer.start();
