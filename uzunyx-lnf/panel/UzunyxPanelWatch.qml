/*
 * Sometimes on Wayland the panel window keeps its old size after Plasma asked
 * for a new one (seen when a task leaves a fit-to-content panel: empty space
 * at the end). Plasma doesn't notice, so it never asks again. Compare the
 * window with the geometry Plasma wants and, if they differ twice in a row,
 * ask again by moving the length one pixel and back. The way back waits a
 * moment: both changes in the same instant end in the size Plasma thinks it
 * already asked for, so nothing new reaches the compositor.
 */
import QtQuick
import org.kde.kwindowsystem

Timer {
    id: watch

    property int misses: 0
    property int restoreLength: 0

    readonly property Timer restore: Timer {
        interval: 300
        // Unless Plasma set a new length meanwhile (a task came or went).
        onTriggered: {
            if (panel.length === watch.restoreLength - 1) {
                panel.length = watch.restoreLength;
            }
        }
    }

    interval: 2000
    repeat: true
    running: KWindowSystem.isPlatformWayland

    onTriggered: {
        const wanted = panel.geometryByDistance(0);
        if (restore.running || wanted.width <= 0 || panel.userConfiguring
                || (panel.width === wanted.width && panel.height === wanted.height)) {
            misses = 0;
            return;
        }
        if (++misses < 2) {
            return;
        }
        misses = 0;
        console.log("uzunyx: panel window is " + panel.width + "x" + panel.height
                    + ", wanted " + wanted.width + "x" + wanted.height + "; asking again");
        restoreLength = panel.length;
        panel.length = restoreLength - 1;
        restore.start();
    }
}
