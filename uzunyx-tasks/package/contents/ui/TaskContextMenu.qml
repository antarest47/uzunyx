/*
 * The context menu of a task, with the texts of Plasma's task manager and its
 * translations.
 */
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris
import org.kde.taskmanager as TaskManager

PlasmaExtras.Menu {
    id: menu

    required property var host
    required property var button

    readonly property string domain: "plasma_applet_org.kde.plasma.taskmanager"
    readonly property var tasks: host.tasks
    readonly property var task: button.model
    readonly property var taskIndex: tasks.makeModelIndex(button.index)
    readonly property bool hasWindows: button.windows > 0

    property bool pinned: false

    function newItem(parent, text, action) {
        const item = Qt.createQmlObject(`
            import org.kde.plasma.extras as PlasmaExtras
            PlasmaExtras.MenuItem {}
        `, parent);
        item.text = text;
        item.clicked.connect(action);
        parent.addMenuItem(item);
        return item;
    }

    // Edit mode needs the focus to have settled after the menu closes: if it
    // starts at once, the panel configuration closes as soon as it opens.
    readonly property Timer deferred: Timer {
        property var source
        interval: 300
        onTriggered: source.trigger()
    }

    // Fullscreen on a desktop of its own is uzunyx-deco's macfullscreen script,
    // which acts on the active window through its shortcut: the window is
    // activated first, and the shortcut invoked once it is.
    readonly property Timer fullscreenOwnDesktop: Timer {
        interval: 200
        onTriggered: menu.runner.connectSource("qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut UzunyxFullscreen")
    }
    readonly property P5Support.DataSource runner: P5Support.DataSource {
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    // Menu items that depend on the app, rebuilt each time it opens.
    property var appItems: []

    function addAppItem(properties, action) {
        const item = Qt.createQmlObject(`
            import org.kde.plasma.extras as PlasmaExtras
            PlasmaExtras.MenuItem {}
        `, menu);
        for (const key in properties) {
            item[key] = properties[key];
        }
        if (action) {
            item.clicked.connect(action);
        }
        addMenuItem(item, newWindowItem);
        appItems.push(item);
    }

    function menuText(text) {
        metrics.text = text;
        return metrics.elidedText.replace(/&/g, "&&");
    }

    readonly property TextMetrics metrics: TextMetrics {
        elide: Qt.ElideRight
        elideWidth: 400
    }

    function refreshAppItems() {
        for (const item of appItems) {
            removeMenuItem(item);
            item.destroy();
        }
        appItems = [];

        if (task.AppId === "org.kde.dolphin.desktop") {
            addAppItem({ text: i18ndc(domain, "@title:group for section of menu items", "Places"), section: true });
            for (const place of host.places()) {
                addAppItem({ text: menuText(place.text) }, () => host.openPlace(place.row));
            }
        }

        // Without the launcher's own: edit and uninstall the application.
        let separator = false;
        for (const action of host.actionsOf(task.AppId)) {
            if (action.type === "title") {
                addAppItem({ text: action.text, section: true });
            } else if (action.type === "separator") {
                separator = appItems.length > 0;
            } else if (action.actionId !== "editApplication" && action.actionId !== "manageApplication") {
                if (separator) {
                    addAppItem({ separator: true });
                    separator = false;
                }
                addAppItem({ text: menuText(action.text), icon: action.icon || "" },
                    () => host.triggerAppAction(action.actionId, action.actionArgument));
            }
        }
        refreshMediaItems();
    }

    function refreshMediaItems() {
        const player = host.playerFor(task.LauncherUrlWithoutIcon, task.AppPid);
        if (player) {
            const playing = player.playbackStatus === Mpris.PlaybackStatus.Playing;
            addAppItem({ text: i18ndc(domain, "Play previous track", "Previous Track"), icon: "media-skip-backward",
                         enabled: player.canGoPrevious }, () => player.Previous());
            addAppItem(playing && player.canPause
                ? { text: i18ndc(domain, "Pause playback", "Pause"), icon: "media-playback-pause" }
                : { text: i18ndc(domain, "Start playback", "Play"), icon: "media-playback-start", enabled: player.canPlay },
                () => playing && player.canPause ? player.Pause() : player.Play());
            addAppItem({ text: i18ndc(domain, "Play next track", "Next Track"), icon: "media-skip-forward",
                         enabled: player.canGoNext }, () => player.Next());
            addAppItem({ text: i18ndc(domain, "Stop playback", "Stop"), icon: "media-playback-stop",
                         enabled: player.canStop }, () => player.Stop());
        }
        if (button.audioStreams.length > 0) {
            addAppItem({ text: i18ndc(domain, "@option:check inmenu, no separate unmute action", "Mute"),
                         icon: "audio-volume-muted", checkable: true, checked: button.muted }, () => button.toggleMuted());
        }
        if (player || button.audioStreams.length > 0) {
            addAppItem({ separator: true });
        }
    }

    function refreshDesktops() {
        desktopsMenu.clearMenuItems();
        const info = host.desktopInfo;
        newItem(desktopsMenu, i18ndc(domain, "action:inmenu", "&All Desktops"),
            () => tasks.requestVirtualDesktops(taskIndex, []));
        for (let i = 0; i < info.desktopIds.length; i++) {
            const id = info.desktopIds[i];
            newItem(desktopsMenu, info.desktopNames[i],
                () => tasks.requestVirtualDesktops(taskIndex, [id]));
        }
        newItem(desktopsMenu, i18ndc(domain, "action:inmenu", "&New Desktop"),
            () => tasks.requestNewVirtualDesktop(taskIndex));
    }

    function refreshActivities() {
        activitiesMenu.clearMenuItems();
        const info = host.activityInfo;
        newItem(activitiesMenu, i18ndc(domain, "action:inmenu", "All Activities"),
            () => tasks.requestActivities(taskIndex, []));
        for (const id of info.runningActivities()) {
            newItem(activitiesMenu, i18ndc(domain, "action:inmenu", "Move to %1", info.activityName(id)),
                () => tasks.requestActivities(taskIndex, [id]));
        }
    }

    function popup() {
        pinned = tasks.launcherPosition(task.LauncherUrlWithoutIcon) >= 0;
        refreshAppItems();
        if (desktopsItem.visible) {
            refreshDesktops();
        }
        if (activitiesItem.visible) {
            refreshActivities();
        }
        openRelative();
    }

    PlasmaExtras.MenuItem {
        id: newWindowItem
        visible: menu.task.CanLaunchNewInstance === true
        text: i18ndc(menu.domain, "action:inmenu", "Open New Window")
        icon: "window-new"
        onClicked: menu.tasks.requestNewInstance(menu.taskIndex)
    }
    PlasmaExtras.MenuItem {
        separator: true
    }
    PlasmaExtras.MenuItem {
        id: desktopsItem
        visible: menu.hasWindows && menu.host.desktopInfo.numberOfDesktops > 1
            && menu.task.IsVirtualDesktopsChangeable === true
        text: i18ndc(menu.domain, "action:inmenu", "Move to &Desktop")
        icon: "virtual-desktops"
        readonly property PlasmaExtras.Menu submenu: PlasmaExtras.Menu {
            id: desktopsMenu
            visualParent: desktopsItem.action
        }
    }
    PlasmaExtras.MenuItem {
        id: activitiesItem
        visible: menu.hasWindows && menu.host.activityInfo.numberOfRunningActivities > 1
        text: i18ndc(menu.domain, "action:inmenu", "Show in &Activities")
        icon: "activities"
        readonly property PlasmaExtras.Menu submenu: PlasmaExtras.Menu {
            id: activitiesMenu
            visualParent: activitiesItem.action
        }
    }
    PlasmaExtras.MenuItem {
        visible: menu.task.LauncherUrlWithoutIcon != "" && !menu.pinned
        text: i18ndc(menu.domain, "action:inmenu", "&Pin to Task Manager")
        icon: "window-pin"
        onClicked: menu.tasks.requestAddLauncher(menu.task.LauncherUrl)
    }
    PlasmaExtras.MenuItem {
        visible: menu.pinned
        text: i18ndc(menu.domain, "action:inmenu", "Unpin from Task Manager")
        icon: "window-unpin"
        onClicked: menu.tasks.requestRemoveLauncher(menu.task.LauncherUrlWithoutIcon)
    }
    PlasmaExtras.MenuItem {
        id: moreItem
        visible: menu.hasWindows
        text: i18ndc(menu.domain, "item:inmenu opens submenu", "More")
        icon: "view-more-symbolic"
        readonly property PlasmaExtras.Menu submenu: PlasmaExtras.Menu {
            visualParent: moreItem.action

            PlasmaExtras.MenuItem {
                enabled: menu.task.IsMovable === true
                text: i18ndc(menu.domain, "action:inmenu", "&Move")
                icon: "transform-move"
                onClicked: menu.tasks.requestMove(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                enabled: menu.task.IsResizable === true
                text: i18ndc(menu.domain, "action:inmenu", "Re&size")
                icon: "transform-scale"
                onClicked: menu.tasks.requestResize(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                enabled: menu.task.IsMaximizable === true
                checkable: true
                checked: menu.task.IsMaximized === true
                text: i18ndc(menu.domain, "action:inmenu", "Ma&ximize")
                icon: "window-maximize"
                onClicked: menu.tasks.requestToggleMaximized(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                enabled: menu.task.IsMinimizable === true
                checkable: true
                checked: menu.task.IsMinimized === true
                text: i18ndc(menu.domain, "action:inmenu", "Mi&nimize")
                icon: "window-minimize"
                onClicked: menu.tasks.requestToggleMinimized(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.task.IsKeepAbove === true
                text: i18ndc(menu.domain, "action:inmenu", "Keep &Above Others")
                icon: "window-keep-above"
                onClicked: menu.tasks.requestToggleKeepAbove(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.task.IsKeepBelow === true
                text: i18ndc(menu.domain, "action:inmenu", "Keep &Below Others")
                icon: "window-keep-below"
                onClicked: menu.tasks.requestToggleKeepBelow(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                enabled: menu.task.IsFullScreenable === true
                checkable: true
                checked: menu.task.IsFullScreen === true
                text: i18ndc(menu.domain, "action:inmenu", "&Fullscreen")
                icon: "view-fullscreen"
                // On a desktop of its own, as in macOS (chosen by the user).
                onClicked: {
                    menu.tasks.requestActivate(menu.taskIndex);
                    menu.fullscreenOwnDesktop.start();
                }
            }
            PlasmaExtras.MenuItem {
                enabled: menu.task.CanSetNoBorder === true
                checkable: true
                checked: menu.task.HasNoBorder === true
                text: i18ndc(menu.domain, "@action:inmenu", "&No Titlebar and Frame")
                icon: "edit-none-border"
                onClicked: menu.tasks.requestToggleNoBorder(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.task.IsExcludedFromCapture === true
                text: i18ndc(menu.domain, "@action:inmenu", "&Hide from Screencast")
                icon: "view-private"
                onClicked: menu.tasks.requestToggleExcludeFromCapture(menu.taskIndex)
            }
            PlasmaExtras.MenuItem {
                separator: true
            }
            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.task.IsGroupable === true
                text: i18ndc(menu.domain, "@option:check inmenu", "Allow this program to be grouped")
                icon: "view-group"
                onClicked: menu.tasks.requestToggleGrouping(menu.taskIndex)
            }
        }
    }
    PlasmaExtras.MenuItem {
        separator: true
    }
    PlasmaExtras.MenuItem {
        readonly property PlasmaCore.Action source: Plasmoid.internalAction("configure")
        visible: source !== null && source.visible
        text: source ? source.text : ""
        icon: source ? source.icon : ""
        onClicked: source.trigger()
    }
    PlasmaExtras.MenuItem {
        readonly property PlasmaCore.Action source: Plasmoid.containment.internalAction("add widgets")
        visible: source !== null && source.visible
        enabled: source !== null && source.enabled
        text: source ? source.text : ""
        icon: source ? source.icon : ""
        onClicked: {
            menu.deferred.source = source;
            menu.deferred.start();
        }
    }
    PlasmaExtras.MenuItem {
        readonly property PlasmaCore.Action source: Plasmoid.containment.internalAction("configure")
        visible: source !== null && source.visible
        enabled: source !== null && source.enabled
        text: source ? source.text : ""
        icon: source ? source.icon : ""
        onClicked: {
            menu.deferred.source = source;
            menu.deferred.start();
        }
    }
    PlasmaExtras.MenuItem {
        separator: true
        visible: menu.hasWindows
    }
    PlasmaExtras.MenuItem {
        visible: menu.hasWindows
        enabled: menu.task.IsClosable === true
        text: menu.task.IsGroupParent ? i18ndc(menu.domain, "@action:inmenu", "&Close All")
                                      : i18ndc(menu.domain, "@action:inmenu", "&Close")
        icon: "window-close"
        onClicked: menu.tasks.requestClose(menu.taskIndex)
    }
}
