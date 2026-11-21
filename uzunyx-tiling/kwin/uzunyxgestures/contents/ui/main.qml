/*
 * Touchpad gestures. KWin already switches desktops with three fingers left and
 * right (the fingers carry the desktop: left goes to the next one), and up and down
 * only with more than one row, so:
 * - three fingers up open the panel's launcher (Tsunyx) and down close it, and its
 *   icons follow the fingers: the progress goes, while they move, to
 *   uzunyx-gesture-relay (a script can't emit D-Bus signals), which repeats it to
 *   Tsunyx Launcher (1.14 or newer), and that decides on lifting them;
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

    DBusCall {
        id: relay
        service: "org.uzunyx.GestureRelay"
        path: "/org/uzunyx/GestureRelay"
        dbusInterface: "org.uzunyx.GestureRelay"
        method: "Send"
    }

    // The launcher's own: kind "open" or "close", state "move", "done" or
    // "cancel", the progress and the screen, which says which launcher (one per
    // panel) it is for.
    function send(kind, state, progress) {
        const screen = Workspace.activeScreen;
        relay.arguments = [kind, state, progress, screen ? screen.name : ""];
        relay.call();
    }

    component LauncherGesture: SwipeGestureHandler {
        required property string kind
        fingerCount: 3
        onProgressChanged: {
            if (progress > 0) {
                send(kind, "move", progress);
            }
        }
        onActivated: send(kind, "done", progress)
        onCancelled: send(kind, "cancel", progress)
    }
    LauncherGesture {
        direction: SwipeGestureHandler.Direction.Up
        kind: "open"
    }
    LauncherGesture {
        direction: SwipeGestureHandler.Direction.Down
        kind: "close"
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
