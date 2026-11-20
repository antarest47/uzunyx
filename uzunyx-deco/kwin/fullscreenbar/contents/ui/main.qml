/*
 * Title bar for fullscreen windows, like macOS: rest the pointer against the
 * top edge over a fullscreen window and a bar slides down with its title and
 * two buttons, leave fullscreen and close. Minimize isn't there: with
 * macfullscreen the window is alone on its desktop.
 *
 * Meant for apps that keep every key (virtual machines, remote desktops), so
 * Meta+F never reaches KWin. Only the pointer is needed. If the app captures
 * the pointer too (a VM without absolute pointer), it never reaches the edge:
 * then only the app's own release key helps.
 *
 * By watching the pointer, as macfullscreen does for the panel: a registered
 * screen edge would make KWin draw a glow there, in any window. Windows a
 * script creates are KWin's internal windows, always above fullscreen ones.
 */
import QtQuick
import QtQuick.Window
import org.kde.kwin

Item {
    id: root

    // How long the pointer has to rest against the edge: the resistance, so
    // that passing by on the way to the app's own top doesn't open it.
    readonly property int dwell: 300
    // How far below the bar the pointer may go before it hides.
    readonly property int slack: 48
    readonly property int barHeight: 34
    readonly property int buttonSize: 20
    readonly property string buttons: "file:///usr/share/kwin/decorations/uzunyx/contents/buttons/"

    // The fullscreen window the bar is for, while it's shown.
    property var target: null
    property real restingSince: -1

    SystemPalette {
        id: sysPalette
        colorGroup: SystemPalette.Active
    }

    // By id: the desktops come as separate wrappers, not the same object.
    function onCurrentDesktop(w) {
        const current = Workspace.currentDesktop.id;
        return w.onAllDesktops || w.desktops.some(d => d.id === current);
    }

    // The fullscreen window under the pointer, on the current desktop.
    function fullscreenAt(pos) {
        const order = Workspace.stackingOrder;
        for (let i = order.length - 1; i >= 0; i--) {
            const w = order[i];
            if (!w.fullScreen || w.minimized || w.deleted || !w.normalWindow) {
                continue;
            }
            if (!root.onCurrentDesktop(w)) {
                continue;
            }
            const g = w.frameGeometry;
            if (pos.x >= g.x && pos.x < g.x + g.width && pos.y >= g.y && pos.y < g.y + g.height) {
                return w;
            }
        }
        return null;
    }

    // Created without a parent: a Window declared inside an Item is only
    // shown while that Item's window is, and a script's root has none.
    property Window bar: null

    Component.onCompleted: bar = barComponent.createObject(null)
    Component.onDestruction: {
        if (bar) {
            bar.destroy();
        }
    }

    function show(w) {
        target = w;
        const g = w.frameGeometry;
        bar.x = g.x;
        bar.y = g.y;
        bar.width = g.width;
        bar.visible = true;
        // Again once shown: KWin places new windows on its own.
        bar.x = g.x;
        bar.y = g.y;
        bar.content.y = 0;
    }

    function hide() {
        restingSince = -1;
        if (bar.visible) {
            bar.content.y = -root.barHeight;
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            const pos = Workspace.cursorPos;
            if (root.target) {
                const t = root.target;
                const g = t.frameGeometry;
                const gone = t.deleted || !t.fullScreen || t.minimized
                    || !root.onCurrentDesktop(t);
                const away = pos.y > g.y + root.barHeight + root.slack
                    || pos.x < g.x || pos.x >= g.x + g.width;
                if (gone || away) {
                    root.target = null;
                    root.hide();
                }
                return;
            }
            const w = root.fullscreenAt(pos);
            if (!w || pos.y > w.frameGeometry.y + 1) {
                root.restingSince = -1;
                return;
            }
            const now = Date.now();
            if (root.restingSince < 0) {
                root.restingSince = now;
            } else if (now - root.restingSince >= root.dwell) {
                root.restingSince = -1;
                root.show(w);
            }
        }
    }

    Component {
        id: barComponent

    Window {
        id: bar

        readonly property Item content: content

        title: "Uzunyx fullscreen bar"
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus | Qt.BypassWindowManagerHint
        color: "transparent"
        height: root.barHeight
        visible: false

        Rectangle {
            id: content
            width: parent.width
            height: root.barHeight
            y: -root.barHeight
            color: sysPalette.window
            onYChanged: {
                if (y <= -root.barHeight && !root.target) {
                    bar.visible = false;
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            // Bottom line, like the border of the panel and the windows.
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: Qt.rgba(sysPalette.windowText.r, sysPalette.windowText.g, sysPalette.windowText.b, 0.25)
            }

            Text {
                anchors {
                    left: parent.left
                    right: buttonRow.left
                    leftMargin: buttonRow.width + 24
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                text: root.target ? root.target.caption : ""
                color: sysPalette.windowText
                font: Qt.application.font
                elide: Text.ElideMiddle
            }

            Row {
                id: buttonRow
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                BarButton {
                    image: "maximize"
                    onClicked: {
                        const t = root.target;
                        root.target = null;
                        root.hide();
                        if (t) {
                            t.fullScreen = false;
                        }
                    }
                }
                BarButton {
                    image: "close"
                    onClicked: {
                        const t = root.target;
                        root.target = null;
                        root.hide();
                        if (t) {
                            t.closeWindow();
                        }
                    }
                }
            }
        }
    }

    }

    // The ball of the window decoration, with its ring on hover.
    component BarButton: Item {
        id: button

        property string image
        signal clicked

        width: 24
        height: 24

        Rectangle {
            visible: mouse.containsMouse
            anchors.centerIn: parent
            width: 24
            height: 24
            radius: width / 2
            color: button.image === "close" ? "#fe919d" : "#c2b6b0"
        }

        Image {
            anchors.centerIn: parent
            width: root.buttonSize
            height: root.buttonSize
            sourceSize: Qt.size(width * 2, height * 2)
            source: root.buttons + button.image + "-"
                + (mouse.pressed ? "active" : mouse.containsMouse ? "hover" : "normal") + ".svg"
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }
}
