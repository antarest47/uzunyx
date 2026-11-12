/*
 * Sometimes on Wayland the panel window keeps its old size after Plasma asked
 * for a new one (seen when a task leaves a fit-to-content panel: empty space
 * at the end). Plasma doesn't notice, so it never asks again. Compare the
 * window with the geometry Plasma wants and, if they differ twice in a row,
 * ask again by moving the length one pixel and back.
 */
import QtQuick
import org.kde.kwindowsystem

Timer {
    property int misses: 0

    interval: 2000
    repeat: true
    running: KWindowSystem.isPlatformWayland

    onTriggered: {
        const wanted = panel.geometryByDistance(0);
        if (wanted.width <= 0 || panel.userConfiguring
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
        const length = panel.length;
        panel.length = length - 1;
        panel.length = length;
    }
}
