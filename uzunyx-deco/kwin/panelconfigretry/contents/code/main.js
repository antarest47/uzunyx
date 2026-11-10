/*
 * Panel configuration retry: "Show Panel Configuration" in Plasma's own menus
 * starts right as the menu closes. The focus then returns to the window on
 * top, and the configuration window, which hides when it loses the focus,
 * opens and closes within a millisecond, leaving the panel wider than it
 * should be. When a window of Plasma's goes away that fast, ask for the
 * configuration again once the focus has settled.
 */

const SHORT_LIVED_MS = 50;
const RETRY_DELAY_MS = 300;
const RETRY_GUARD_MS = 3000;

const addedAt = new Map();
let lastPanel = null;
let lastRetry = 0;

// Which panel it is, by the edge its window is on: the last one clicked.
function edgeOf(w) {
    const screen = workspace.clientArea(KWin.FullScreenArea, w);
    const f = w.frameGeometry;
    if (f.height >= f.width) {
        return f.x <= screen.x + screen.width / 2 ? "left" : "right";
    }
    return f.y <= screen.y + screen.height / 2 ? "top" : "bottom";
}

const retryTimer = new QTimer();
retryTimer.singleShot = true;
retryTimer.interval = RETRY_DELAY_MS;
retryTimer.timeout.connect(() => {
    const edge = lastPanel || "bottom";
    print("panelconfigretry: reopening the " + edge + " panel's configuration");
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript",
        "var all = panels().filter(function (p) { return p.location === '" + edge + "'; });"
        + "if (all.length === 0) { all = panels(); }"
        + "if (all.length > 0) { all[0].showConfigurationInterface(); }");
});

workspace.windowActivated.connect(w => {
    if (w && w.dock && w.resourceClass === "plasmashell") {
        lastPanel = edgeOf(w);
    }
});

workspace.windowAdded.connect(w => {
    if (w.resourceClass === "org.kde.plasmashell" && w.caption === "plasmashell" && w.layer === 2) {
        addedAt.set(w.internalId.toString(), Date.now());
    }
});

workspace.windowRemoved.connect(w => {
    const key = w.internalId.toString();
    if (!addedAt.has(key)) {
        return;
    }
    const lived = Date.now() - addedAt.get(key);
    addedAt.delete(key);
    if (lived < SHORT_LIVED_MS && Date.now() - lastRetry > RETRY_GUARD_MS) {
        lastRetry = Date.now();
        retryTimer.start();
    }
});
