/*
 * One application in the panel: a glass background in the edition's accent
 * colour for anything with windows (none for a pinned app that isn't running),
 * its icon and a dot per window, up to three.
 */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

PlasmaCore.ToolTipArea {
    id: button

    required property var model
    required property int index
    required property var host
    required property int size
    required property int gap
    required property int rows
    required property bool vertical

    readonly property var tasks: host.tasks
    readonly property bool reversed: Plasmoid.configuration.reverseMode
    readonly property int slot: reversed ? tasks.count - 1 - index : index

    readonly property int windows: model.IsLauncher || model.IsStartup ? 0
        : model.IsGroupParent ? model.ChildCount : 1
    readonly property bool focused: model.IsActive === true
    readonly property bool minimized: model.IsMinimized === true
    readonly property bool attention: model.IsDemandingAttention === true || launcherEntry["urgent"] === true
    readonly property bool hovered: mouse.containsMouse

    // Audio of this app, while it has any.
    property var audioStreams: []
    readonly property bool playingAudio: audioStreams.some(s => !s.corked)
    readonly property bool muted: audioStreams.length > 0 && audioStreams.every(s => s.muted)

    function updateAudioStreams() {
        const audio = host.pulseAudio;
        audioStreams = audio && model.IsWindow !== false && windows > 0
            ? audio.streamsFor(String(model.AppId).replace(/\.desktop$/, ""), model.AppPid, model.AppName) : [];
    }
    function toggleMuted() {
        const target = !muted;
        audioStreams.forEach(s => s.model.Muted = target);
    }
    function adjustVolume(step) {
        const audio = host.pulseAudio;
        if (audio) {
            const change = (audio.normalVolume - audio.minimalVolume) * 0.05 * -step;
            audioStreams.forEach(s => s.model.Volume = Math.round(
                Math.max(audio.minimalVolume, Math.min(audio.normalVolume, s.volume + change))));
        }
    }
    Connections {
        target: button.host.pulseAudio
        function onStreamsChanged() {
            button.updateAudioStreams();
        }
    }

    // What the app announces for its launcher (see main.qml).
    readonly property var launcherEntry: {
        const id = String(model.LauncherUrlWithoutIcon).replace(/^applications:/, "");
        return host.launcherEntries["application://" + id] || {};
    }
    readonly property int badgeCount: launcherEntry["count-visible"] ? launcherEntry["count"] : 0
    // Announced by the app, or else from its running jobs.
    readonly property real progress: {
        if (launcherEntry["progress-visible"]) {
            return launcherEntry["progress"];
        }
        const job = host.jobProgress[String(model.AppId).replace(/\.desktop$/, "")];
        return job === undefined ? -1 : job;
    }

    // How lit the glass is: 0 barely there (minimized), 1 the active window.
    property real strength: focused ? 1 : hovered ? 0.5 : minimized ? 0.03 : 0.15
    Behavior on strength {
        NumberAnimation { duration: Kirigami.Units.shortDuration }
    }

    // The edition's colour, which changes by itself with the colour scheme,
    // only where it matters: as in the window buttons, the rest is neutral.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    readonly property color accent: Kirigami.Theme.focusColor
    property color tint: focused ? accent : minimized ? "#3a3d45" : "#aeb3bf"
    Behavior on tint {
        ColorAnimation { duration: Kirigami.Units.shortDuration }
    }

    function shade(color, factor, alpha) {
        return Qt.rgba(color.r * factor, color.g * factor, color.b * factor, alpha);
    }

    readonly property real along: Math.floor(slot / rows) * (size + gap)
    readonly property real across: (slot % rows) * size
    x: vertical ? across : along
    y: vertical ? along : across
    width: size
    height: size

    active: Plasmoid.configuration.showToolTips
    location: Plasmoid.location
    interactive: windows > 0
    mainText: windows > 0 ? "" : (model.AppName || model.display || "")
    subText: windows > 0 ? "" : (model.GenericName || "")
    mainItem: windows > 0 ? previewLoader : null

    Loader {
        id: previewLoader
        // Once created it stays: it must survive the mouse going into the tooltip.
        active: button.containsMouse || status === Loader.Ready
        visible: false
        sourceComponent: WindowPreviews {
            host: button.host
            task: button
            row: button.index
            windows: button.windows
            pointerOverTask: button.containsMouse
            onDone: button.hideImmediately()
        }
    }

    // The window manager moves the minimize animations to this rectangle, kept
    // relative to the panel. The panel is centered and fits its contents: when a
    // task comes or goes, everything shifts while this button keeps its x in the
    // row, so it's also published when the count changes and checked each second.
    property point published: Qt.point(-1, -1)
    function publishGeometry() {
        if (!model.IsWindow && !model.IsGroupParent) {
            return;
        }
        published = mapToItem(null, 0, 0);
        const p = mapToGlobal(0, 0);
        const rect = Qt.rect(p.x, p.y, width, height);
        tasks.requestPublishDelegateGeometry(tasks.makeModelIndex(index), rect, button);
        for (let child = 0; child < model.ChildCount; child++) {
            tasks.requestPublishDelegateGeometry(tasks.makeModelIndex(index, child), rect, button);
        }
    }
    Timer {
        id: publishTimer
        interval: 100
        onTriggered: button.publishGeometry()
    }
    Timer {
        id: settleTimer
        interval: 600
        onTriggered: button.publishGeometry()
    }
    Timer {
        interval: 1000
        running: model.IsWindow || model.IsGroupParent
        repeat: true
        onTriggered: {
            const p = button.mapToItem(null, 0, 0);
            if (p.x !== button.published.x || p.y !== button.published.y) {
                button.publishGeometry();
            }
        }
    }
    Connections {
        target: button.tasks
        function onCountChanged() {
            publishTimer.restart();
            settleTimer.restart();
        }
    }
    onXChanged: publishTimer.restart()
    onYChanged: publishTimer.restart()
    onWidthChanged: publishTimer.restart()
    onWindowsChanged: {
        publishTimer.restart();
        updateAudioStreams();
    }
    Component.onCompleted: publishTimer.restart()

    Item {
        id: glass
        anchors.fill: parent
        anchors.margins: 2
        visible: button.windows > 0 || button.hovered
        opacity: button.windows > 0 ? 1 : 0.6

        // Base: vertical gradient of the accent.
        Rectangle {
            anchors.fill: parent
            radius: 8
            gradient: Gradient {
                GradientStop { position: 0; color: button.shade(button.tint, 1, 0.30 + 0.45 * button.strength) }
                GradientStop { position: 1; color: button.shade(button.tint, 0.45, 0.35 + 0.45 * button.strength) }
            }
        }
        // Glow from below.
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * 0.45
            bottomLeftRadius: 8
            bottomRightRadius: 8
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: button.shade(Qt.lighter(button.tint, 1.5), 1, 0.15 + 0.4 * button.strength) }
            }
        }
        // Reflection on the upper half, inside the border.
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 2
            height: parent.height * 0.46
            topLeftRadius: 7
            topRightRadius: 7
            bottomLeftRadius: 3
            bottomRightRadius: 3
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, (button.minimized ? 0.03 : 0.10) + 0.24 * button.strength) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.02 + 0.06 * button.strength) }
            }
        }
        // Asks for attention: the whole glass pulses in the accent.
        Rectangle {
            anchors.fill: parent
            radius: 8
            visible: button.attention
            color: button.accent
            SequentialAnimation on opacity {
                running: button.attention
                loops: Animation.Infinite
                NumberAnimation { from: 0.15; to: 0.8; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.8; to: 0.15; duration: 500; easing.type: Easing.InOutSine }
            }
        }
        // Border, as on the panel and the windows.
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, button.focused ? 0.35 : button.minimized ? 0.12 : 0.25)
        }
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: button.windows > 0 ? -2 : 0
        width: Math.round(button.size * 0.66)
        height: width
        // Without this it snaps down to a standard size (22 px instead of 30).
        roundToIconSize: false
        source: button.model.decoration
        opacity: button.minimized ? 0.5 : 1
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        spacing: 3
        Repeater {
            model: Math.min(button.windows, 3)
            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: "#ffffff"
                opacity: button.focused ? 1 : button.minimized ? 0.45 : 0.8
            }
        }
    }

    // Progress the app announces, above the dots.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 6
            bottomMargin: 10
        }
        height: 3
        radius: 1.5
        visible: button.progress >= 0
        color: Qt.rgba(0, 0, 0, 0.55)

        Rectangle {
            width: parent.width * Math.min(1, Math.max(0, button.progress))
            height: parent.height
            radius: parent.radius
            color: "#ffffff"
        }
    }

    // Count the app announces (unread messages...), in the accent.
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            margins: 1
        }
        visible: button.badgeCount > 0
        height: 15
        width: Math.max(height, badgeText.implicitWidth + 6)
        radius: height / 2
        color: Qt.darker(button.accent, 1.2)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.35)

        Text {
            id: badgeText
            anchors.centerIn: parent
            color: "#ffffff"
            font.pixelSize: 10
            font.bold: true
            text: button.badgeCount > 99 ? "99+" : button.badgeCount
        }
    }

    // Drag files over a window to bring it up; drop them to open them with the
    // app, or drop a .desktop file to pin it.
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
        onEntered: if (button.windows > 0) dragActivation.restart()
        onExited: dragActivation.stop()
        onDropped: drop => {
            dragActivation.stop();
            const urls = drop.urls.map(String);
            if (urls.length > 0 && urls.every(u => u.endsWith(".desktop"))) {
                urls.forEach(u => button.tasks.requestAddLauncher(u));
            } else if (urls.length > 0) {
                button.tasks.requestOpenUrls(button.tasks.makeModelIndex(button.index), drop.urls);
            }
            drop.accept(Qt.CopyAction);
        }

        Timer {
            id: dragActivation
            interval: 500
            onTriggered: button.tasks.requestActivate(button.tasks.makeModelIndex(button.index))
        }
    }

    MouseArea {
        id: mouse

        property point pressPos
        property bool dragging: false
        property int wheelDelta: 0

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onPressed: event => {
            pressPos = Qt.point(event.x, event.y);
            dragging = false;
        }
        onPositionChanged: event => {
            if (!(event.buttons & Qt.LeftButton)) {
                return;
            }
            if (Plasmoid.configuration.sortingStrategy !== TaskManager.TasksModel.SortManual) {
                return;
            }
            if (!dragging && Math.hypot(event.x - pressPos.x, event.y - pressPos.y) < Qt.styleHints.startDragDistance) {
                return;
            }
            if (!dragging) {
                dragging = true;
                button.hideImmediately();
            }
            // Moving the task moves this button, so go by the position in the row.
            const p = mapToItem(button.parent, event.x, event.y);
            const row = Math.max(0, Math.min(button.rows - 1, Math.floor((button.vertical ? p.x : p.y) / button.size)));
            const slot = Math.floor((button.vertical ? p.y : p.x) / (button.size + button.gap)) * button.rows + row;
            const target = Math.max(0, Math.min(button.tasks.count - 1, button.reversed ? button.tasks.count - 1 - slot : slot));
            if (target !== button.index) {
                button.tasks.move(button.index, target);
            }
        }
        onReleased: {
            if (dragging) {
                button.tasks.syncLaunchers();
            }
        }
        onClicked: event => {
            if (dragging) {
                return;
            }
            if (event.button === Qt.LeftButton && (event.modifiers & Qt.ControlModifier)) {
                button.tasks.requestNewInstance(button.tasks.makeModelIndex(button.index));
            } else if (event.button === Qt.MiddleButton) {
                button.middleClick();
            } else if (event.button === Qt.RightButton) {
                button.hideImmediately();
                contextMenu.popup();
            } else {
                button.leftClick();
            }
        }
        onWheel: event => {
            wheelDelta += event.angleDelta.y;
            const steps = Math.trunc(wheelDelta / 120);
            if (steps !== 0) {
                wheelDelta -= steps * 120;
                button.scroll(steps > 0 ? -1 : 1);
            }
        }
    }

    // Audio indicator, above the rest so it takes its own clicks.
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            margins: 3
        }
        width: 16
        height: 16
        radius: 8
        visible: Plasmoid.configuration.indicateAudioStreams && (button.playingAudio || button.muted)
        color: Qt.rgba(0, 0, 0, 0.6)

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 12
            height: 12
            source: button.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
            isMask: true
            color: "#ffffff"
        }
        MouseArea {
            anchors.fill: parent
            enabled: Plasmoid.configuration.interactiveMute
            onClicked: button.toggleMuted()
        }
    }

    function leftClick() {
        const task = tasks.makeModelIndex(index);
        if (model.IsGroupParent) {
            switch (Plasmoid.configuration.groupedTaskVisualization) {
            case 0:
                activateChild(1, false);
                return;
            case 2:
                if (host.windowViewAvailable) {
                    host.showWindowView(childIds());
                    return;
                }
                break;
            case 1:
                if (Plasmoid.configuration.showToolTips) {
                    showToolTip();
                    return;
                }
                break;
            }
            hideImmediately();
            showWindowList();
        } else if (focused && !minimized && Plasmoid.configuration.minimizeActiveTaskOnClick) {
            tasks.requestToggleMinimized(task);
        } else {
            tasks.requestActivate(task);
        }
    }

    function middleClick() {
        const task = tasks.makeModelIndex(index);
        switch (Plasmoid.configuration.middleClickAction) {
        case 1:
            tasks.requestClose(task);
            break;
        case 2:
            tasks.requestNewInstance(task);
            break;
        case 3:
            tasks.requestToggleMinimized(task);
            break;
        case 4:
            tasks.requestToggleGrouping(task);
            break;
        case 5:
            tasks.requestVirtualDesktops(task, [host.desktopInfo.currentDesktop]);
            break;
        }
    }

    function scroll(step) {
        const skip = Plasmoid.configuration.wheelSkipMinimized;
        const mode = Plasmoid.configuration.wheelEnabled;
        if (mode === 3) {
            adjustVolume(step);
            return;
        }
        if (mode === 2) {
            if (model.IsGroupParent) {
                activateChild(step, skip);
            } else if (windows > 0) {
                tasks.requestActivate(tasks.makeModelIndex(index));
            }
        } else if (mode === 1) {
            const Roles = TaskManager.AbstractTasksModel;
            let current = 0;
            for (let i = 0; i < tasks.count; i++) {
                if (tasks.data(tasks.makeModelIndex(i), Roles.IsActive)) {
                    current = i;
                }
            }
            for (let n = 1; n <= tasks.count; n++) {
                const ix = tasks.makeModelIndex((current + step * n + tasks.count * n) % tasks.count);
                if (!tasks.data(ix, Roles.IsLauncher) && !(skip && tasks.data(ix, Roles.IsMinimized))) {
                    tasks.requestActivate(ix);
                    return;
                }
            }
        }
    }

    // Goes to the next or previous window of the group.
    function activateChild(step, skipMinimized) {
        const Roles = TaskManager.AbstractTasksModel;
        const count = model.ChildCount;
        let current = -1;
        for (let child = 0; child < count; child++) {
            if (tasks.data(tasks.makeModelIndex(index, child), Roles.IsActive)) {
                current = child;
            }
        }
        for (let n = 1; n <= count; n++) {
            const child = (Math.max(current, 0) + step * n + count * n) % count;
            const ix = tasks.makeModelIndex(index, child);
            if (!(skipMinimized && tasks.data(ix, Roles.IsMinimized))) {
                tasks.requestActivate(ix);
                return;
            }
        }
    }

    function childIds() {
        const ids = [];
        for (let child = 0; child < model.ChildCount; child++) {
            const list = tasks.data(tasks.makeModelIndex(index, child), TaskManager.AbstractTasksModel.WinIdList);
            for (let i = 0; i < list.length; i++) {
                ids.push(String(list[i]));
            }
        }
        return ids;
    }

    function showWindowList() {
        windowList.clearMenuItems();
        for (let child = 0; child < model.ChildCount; child++) {
            const ix = tasks.makePersistentModelIndex(index, child);
            contextMenu.newItem(windowList, tasks.data(ix, Qt.DisplayRole) || "", () => tasks.requestActivate(ix));
        }
        windowList.openRelative();
    }

    PlasmaExtras.Menu {
        id: windowList
        visualParent: button
        placement: contextMenu.placement
    }

    TaskContextMenu {
        id: contextMenu
        host: button.host
        button: button
        visualParent: button
        placement: button.vertical ? PlasmaExtras.Menu.RightPosedTopAlignedPopup
                                   : PlasmaExtras.Menu.TopPosedLeftAlignedPopup
    }
}
