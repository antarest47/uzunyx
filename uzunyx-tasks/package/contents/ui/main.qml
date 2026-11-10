/*
 * Uzunyx Tasks: a task manager for the panel, QML only, on top of the public
 * org.kde.taskmanager module (Plasma's own applet keeps its QML compiled in
 * its plugin, so it can't be reused without building against each Plasma).
 * Pinned apps and windows live in one TasksModel, grouped by application.
 */
import QtQml
import QtQuick
import QtQuick.Layouts
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.workspace.dbus as DBus
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // Use the panel's whole thickness, as Plasma's task manager does.
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktops
    }
    TaskManager.ActivityInfo {
        id: activities
    }

    readonly property var tasks: tasksModel
    readonly property var desktopInfo: virtualDesktops
    readonly property var activityInfo: activities
    readonly property var pulseAudio: audioLoader.item

    Loader {
        id: audioLoader
        source: "AudioStreams.qml"
    }

    Mpris.Mpris2Model {
        id: mprisModel
    }
    function playerFor(launcherUrl, pid) {
        return mprisModel.playerForLauncherUrl(launcherUrl, pid);
    }

    // What apps announce for their launcher (Unity Launcher API): a count, a
    // progress and whether they ask for attention, by "application://x.desktop".
    property var launcherEntries: ({})

    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        // Repeated by uzunyx-task-badges: this only watches a fixed sender.
        service: "org.uzunyx.TaskBadges"
        path: "/org/uzunyx/TaskBadges"
        iface: "org.uzunyx.TaskBadges"

        function dbusUpdate(appUri, properties) {
            root.updateLauncherEntry(appUri, properties);
        }
    }
    // Progress of running jobs (downloads in Firefox, file copies...) by the
    // app's desktop entry, from what the notifications know.
    property var jobProgress: ({})

    function updateJobProgress() {
        const totals = {};
        for (let i = 0; i < jobEntries.count; i++) {
            const job = jobEntries.objectAt(i);
            if (job && job.running && job.desktopEntry !== "") {
                const total = totals[job.desktopEntry] || { sum: 0, count: 0 };
                total.sum += job.percentage;
                total.count++;
                totals[job.desktopEntry] = total;
            }
        }
        const progress = {};
        for (const entry in totals) {
            progress[entry] = totals[entry].sum / totals[entry].count / 100;
        }
        jobProgress = progress;
    }

    Instantiator {
        id: jobEntries
        model: NotificationManager.Notifications {
            showNotifications: false
            showJobs: true
            showExpired: true
            showDismissed: true
        }
        delegate: QtObject {
            required property var model
            readonly property string desktopEntry: model.desktopEntry || ""
            readonly property int percentage: model.percentage || 0
            readonly property bool running: model.jobState !== NotificationManager.Notifications.JobStateStopped

            onPercentageChanged: root.updateJobProgress()
            onRunningChanged: root.updateJobProgress()
        }
        onObjectAdded: root.updateJobProgress()
        onObjectRemoved: root.updateJobProgress()
    }

    function updateLauncherEntry(appUri, properties) {
        const entries = Object.assign({}, launcherEntries);
        const entry = Object.assign({}, entries[appUri]);
        for (const key in properties) {
            // D-Bus values arrive wrapped in an object.
            const value = properties[key];
            entry[key] = value !== null && typeof value === "object" ? value.value : value;
        }
        entries[appUri] = entry;
        launcherEntries = entries;
    }

    // The menu's actions of each app, recent files included, come from the
    // module of the application launchers: Plasma's task manager has its own
    // code for them in its compiled backend. Tsunyx uses this module too.
    Kicker.SimpleFavoritesModel {
        id: appModel
    }
    Instantiator {
        id: appEntry
        model: appModel
        delegate: QtObject {
            required property var model
        }
    }
    Kicker.ComputerModel {
        id: placesModel
        systemApplications: []
    }
    Instantiator {
        id: placeEntries
        model: placesModel
        delegate: QtObject {
            required property var model
        }
    }

    function actionsOf(appId) {
        appModel.favorites = appId ? [appId] : [];
        const entry = appEntry.objectAt(0);
        return entry ? (entry.model.actionList || []) : [];
    }
    function triggerAppAction(actionId, argument) {
        appModel.trigger(0, actionId, argument);
    }
    function places() {
        const list = [];
        for (let row = 0; row < placeEntries.count; row++) {
            list.push({ text: placeEntries.objectAt(row).model.display, row: row });
        }
        return list;
    }
    function openPlace(row) {
        placesModel.trigger(row, "", null);
    }

    Plasmoid.status: tasksModel.anyTaskDemandsAttention && Plasmoid.configuration.unhideOnAttention
        ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.PassiveStatus

    DBus.DBusServiceWatcher {
        id: windowViewService
        busType: DBus.BusType.Session
        watchedService: "org.kde.KWin.Effect.WindowView1"
    }
    readonly property bool windowViewAvailable: windowViewService.registered

    function callKWin(service, path, member, ids) {
        DBus.SessionBus.asyncCall({
            service: service,
            path: path,
            iface: service,
            member: member,
            arguments: [ids],
            signature: "(as)",
        });
    }
    // The large previews of a group.
    function showWindowView(ids) {
        callKWin("org.kde.KWin.Effect.WindowView1", "/org/kde/KWin/Effect/WindowView1", "activate", ids);
    }
    // Hides all windows but these while hovering a preview; none to end it.
    function highlight(ids) {
        if (Plasmoid.configuration.highlightWindows) {
            callKWin("org.kde.KWin.HighlightWindow", "/org/kde/KWin/HighlightWindow", "highlightWindows", ids);
        }
    }

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: Plasmoid.configuration.groupingStrategy === 0 ? TaskManager.TasksModel.GroupDisabled
                                                                 : TaskManager.TasksModel.GroupApplications
        sortMode: Plasmoid.configuration.sortingStrategy
        separateLaunchers: Plasmoid.configuration.separateLaunchers
        launchInPlace: sortMode === TaskManager.TasksModel.SortManual && !separateLaunchers
        hideActivatedLaunchers: Plasmoid.configuration.hideLauncherOnStart
        filterByVirtualDesktop: Plasmoid.configuration.showOnlyCurrentDesktop
        filterByActivity: Plasmoid.configuration.showOnlyCurrentActivity
        filterByScreen: Plasmoid.configuration.showOnlyCurrentScreen
        filterNotMinimized: Plasmoid.configuration.showOnlyMinimized
        virtualDesktop: virtualDesktops.currentDesktop
        activity: activities.currentActivity
        screenGeometry: Plasmoid.containment.screenGeometry
        launcherList: Plasmoid.configuration.launchers
        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
    }

    fullRepresentation: Item {
        id: area

        readonly property int thickness: root.vertical ? width : height
        // As many rows as requested and still usable.
        readonly property int rows: Math.max(1, Math.min(Plasmoid.configuration.maxStripes, Math.floor(thickness / 20)))
        readonly property int cell: Math.floor(thickness / rows)
        readonly property int spacing: Plasmoid.configuration.iconSpacing
        readonly property int length: Math.max(1, Math.ceil(tasksModel.count / rows) * (cell + spacing) - spacing)

        Layout.fillWidth: !root.vertical && Plasmoid.configuration.fill
        Layout.fillHeight: root.vertical && Plasmoid.configuration.fill
        Layout.minimumWidth: root.vertical ? -1 : length
        Layout.preferredWidth: root.vertical ? -1 : length
        Layout.minimumHeight: root.vertical ? length : -1
        Layout.preferredHeight: root.vertical ? length : -1

        Repeater {
            model: tasksModel
            TaskButton {
                host: root
                size: area.cell
                gap: area.spacing
                rows: area.rows
                vertical: root.vertical
            }
        }
    }
}
