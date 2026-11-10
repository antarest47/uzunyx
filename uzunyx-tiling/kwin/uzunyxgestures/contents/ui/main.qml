/*
 * Touchpad gestures. KWin already switches desktops with three fingers left and
 * right (the fingers carry the desktop: left goes to the next one), and up and down
 * only with more than one row, so:
 * - three fingers up open the panel's launcher (Tsunyx), as Super does, and down
 *   close it if it's open;
 * - three fingers left on the last desktop do what Alt+D does there: make a new one.
 * Both are global shortcuts, invoked through kglobalaccel, so they behave the same.
 */
import QtQuick
import org.kde.kwin

Item {
    DBusCall {
        id: invoke
        service: "org.kde.kglobalaccel"
        dbusInterface: "org.kde.kglobalaccel.Component"
        method: "invokeShortcut"
    }

    function shortcut(component, name) {
        invoke.path = "/component/" + component;
        invoke.arguments = [name];
        invoke.call();
    }

    // Tsunyx's window only exists while it's open; its title ends in "(closing)"
    // while it goes, and goes on with the button's position in lamp mode.
    function launcherOpen() {
        return Workspace.stackingOrder.some(w => w.caption === "Tsunyx Launcher"
            || w.caption.startsWith("Tsunyx Launcher (lamp)"));
    }

    SwipeGestureHandler {
        direction: SwipeGestureHandler.Direction.Up
        fingerCount: 3
        onActivated: {
            if (!launcherOpen()) {
                shortcut("plasmashell", "activate application launcher");
            }
        }
    }

    SwipeGestureHandler {
        direction: SwipeGestureHandler.Direction.Down
        fingerCount: 3
        onActivated: {
            if (launcherOpen()) {
                shortcut("plasmashell", "activate application launcher");
            }
        }
    }

    SwipeGestureHandler {
        // The desktop the gesture started on, if it was the last one. KWin's own
        // gesture ends first: with wrapping on it goes to the first desktop.
        property var lastDesktop: null
        property bool started: false

        direction: SwipeGestureHandler.Direction.Left
        fingerCount: 3
        onProgressChanged: {
            if (!started && progress > 0) {
                started = true;
                const desktops = Workspace.desktops;
                lastDesktop = Workspace.currentDesktop === desktops[desktops.length - 1] ? Workspace.currentDesktop : null;
            }
        }
        onActivated: {
            if (lastDesktop && Workspace.currentDesktop === lastDesktop) {
                shortcut("kwin", "UzunyxDesktopNext");
            }
            started = false;
            lastDesktop = null;
        }
        onCancelled: {
            started = false;
            lastDesktop = null;
        }
    }
}
