/*
 * Motion for uzunyx-tiling, which loads this effect while tiling is on and
 * unloads it when off. Like Hyprland: a window whose place changes glides from
 * the old one (the new content stretched, as KWin's Stretch does for maximize),
 * and a new window, kept invisible by the script until the others made room,
 * grows in when it shows up.
 *
 * Left alone: windows being moved or resized with the mouse (the script moves
 * the others along live), all of them while that lasts; maximize, which has its
 * own effect; fullscreen; and windows just opened, whose first places belong to
 * the open animation.
 */
"use strict";

const MOVE_MS = 220;
const SHOW_MS = 200;
const NEW_WINDOW_MS = 600;

class TileMotion {
    constructor() {
        effects.windowAdded.connect(window => this.manage(window, true));
        for (const window of effects.stackingOrder) {
            this.manage(window, false);
        }
    }

    manage(window, isNew) {
        if (isNew) {
            window.tileMotionBorn = Date.now();
        }
        window.windowFrameGeometryChanged.connect(this.moved.bind(this));
        window.windowOpacityChanged.connect(this.shown.bind(this));
        window.windowMaximizedStateAboutToChange.connect(w => w.tileMotionSkip = Date.now());
        window.windowFullScreenChanged.connect(w => w.tileMotionSkip = Date.now());
    }

    quiet(window) {
        return !window.normalWindow || !window.visible || window.minimized || window.fullScreen
            || Date.now() - (window.tileMotionBorn || 0) < NEW_WINDOW_MS
            || Date.now() - (window.tileMotionSkip || 0) < 100
            || effects.stackingOrder.some(w => w.move || w.resize);
    }

    moved(window, old) {
        const now = window.geometry;
        if (this.quiet(window) || old.width <= 0 || old.height <= 0
            || (old.x === now.x && old.y === now.y && old.width === now.width && old.height === now.height)) {
            return;
        }
        if (window.tileMotion) {
            cancel(window.tileMotion);
        }
        window.tileMotion = animate({
            window: window,
            duration: animationTime(MOVE_MS),
            animations: [{
                type: Effect.Size,
                from: { value1: old.width, value2: old.height },
                to: { value1: now.width, value2: now.height },
                curve: QEasingCurve.OutCubic
            }, {
                type: Effect.Translation,
                from: {
                    value1: old.x - now.x - (now.width / 2 - old.width / 2),
                    value2: old.y - now.y - (now.height / 2 - old.height / 2)
                },
                to: { value1: 0, value2: 0 },
                curve: QEasingCurve.OutCubic
            }]
        });
    }

    // The script's hidden new window becomes visible: it grows in.
    shown(window, oldOpacity) {
        if (oldOpacity > 0 || window.opacity < 1 || !window.normalWindow || !window.visible) {
            return;
        }
        animate({
            window: window,
            duration: animationTime(SHOW_MS),
            animations: [{
                type: Effect.Opacity,
                from: 0,
                to: 1,
                curve: QEasingCurve.OutCubic
            }, {
                type: Effect.Scale,
                from: 0.94,
                to: 1,
                curve: QEasingCurve.OutCubic
            }]
        });
    }
}

new TileMotion();
