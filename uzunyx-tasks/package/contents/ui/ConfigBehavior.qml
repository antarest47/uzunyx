/*
 * All the texts come from Plasma's task manager and use its translations.
 */
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus
import org.kde.taskmanager as TaskManager

KCMUtils.SimpleKCM {
    id: page

    readonly property string domain: "plasma_applet_org.kde.plasma.taskmanager"
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    property alias cfg_groupingStrategy: groupingStrategy.currentIndex
    property alias cfg_groupedTaskVisualization: groupedTaskVisualization.currentIndex
    property int cfg_sortingStrategy
    property alias cfg_separateLaunchers: separateLaunchers.checked
    property alias cfg_hideLauncherOnStart: hideLauncherOnStart.checked
    property alias cfg_minimizeActiveTaskOnClick: minimizeActive.checked
    property alias cfg_middleClickAction: middleClickAction.currentIndex
    property alias cfg_wheelEnabled: wheelEnabled.currentIndex
    property alias cfg_wheelSkipMinimized: wheelSkipMinimized.checked
    property alias cfg_showOnlyCurrentDesktop: showOnlyCurrentDesktop.checked
    property alias cfg_showOnlyCurrentActivity: showOnlyCurrentActivity.checked
    property alias cfg_showOnlyCurrentScreen: showOnlyCurrentScreen.checked
    property alias cfg_showOnlyMinimized: showOnlyMinimized.checked
    property alias cfg_unhideOnAttention: unhideOnAttention.checked
    property alias cfg_reverseMode: reverseMode.checked

    DBus.DBusServiceWatcher {
        id: windowView
        busType: DBus.BusType.Session
        watchedService: "org.kde.KWin.Effect.WindowView1"
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.ComboBox {
            id: groupingStrategy
            Kirigami.FormData.label: i18ndc(page.domain, "@label:listbox how to group tasks", "Group:")
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 14
            model: [
                i18ndc(page.domain, "@item:inlistbox how to group tasks", "Do not group"),
                i18ndc(page.domain, "@item:inlistbox how to group tasks", "By program name"),
            ]
        }
        QQC2.ComboBox {
            id: groupedTaskVisualization
            Kirigami.FormData.label: i18ndc(page.domain, "@label:listbox completes sentence like: … cycles through tasks", "Clicking grouped task:")
            Layout.fillWidth: true
            enabled: groupingStrategy.currentIndex !== 0
            model: [
                i18ndc(page.domain, "@item:inlistbox Completes the sentence 'Clicking grouped task cycles through tasks' ", "Cycles through tasks"),
                i18ndc(page.domain, "@item:inlistbox Completes the sentence 'Clicking grouped task shows small window previews' ", "Shows small window previews"),
                i18ndc(page.domain, "@item:inlistbox Completes the sentence 'Clicking grouped task shows large window previews' ", "Shows large window previews"),
                i18ndc(page.domain, "@item:inlistbox Completes the sentence 'Clicking grouped task shows textual list' ", "Shows textual list"),
            ]
        }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: groupedTaskVisualization.currentIndex === 2 && !windowView.registered
            type: Kirigami.MessageType.Warning
            text: i18ndc(page.domain, "@info displayed as InlineMessage", "The compositor does not support displaying windows side by side, so a textual list will be displayed instead.")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: sortingStrategy
            Kirigami.FormData.label: i18ndc(page.domain, "@label:listbox sort tasks in grouped task", "Sort:")
            Layout.fillWidth: true
            textRole: "text"
            valueRole: "value"
            model: [
                { "text": i18ndc(page.domain, "@item:inlistbox sort tasks in grouped task", "Do not sort"), "value": TaskManager.TasksModel.SortDisabled },
                { "text": i18ndc(page.domain, "@item:inlistbox sort tasks in grouped task", "Manually"), "value": TaskManager.TasksModel.SortManual },
                { "text": i18ndc(page.domain, "@item:inlistbox sort tasks in grouped task", "Alphabetically"), "value": TaskManager.TasksModel.SortAlpha },
                { "text": i18ndc(page.domain, "@item:inlistbox sort tasks in grouped task", "By desktop"), "value": TaskManager.TasksModel.SortVirtualDesktop },
                { "text": i18ndc(page.domain, "@item:inlistbox sort tasks in grouped task", "By activity"), "value": TaskManager.TasksModel.SortActivity },
                { "text": i18ndc(page.domain, "@item:inlistbox sort tasks in grouped task", "By horizontal window position"), "value": TaskManager.TasksModel.SortWindowPositionHorizontal },
            ]
            onActivated: page.cfg_sortingStrategy = currentValue
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_sortingStrategy)
        }
        QQC2.CheckBox {
            id: separateLaunchers
            text: i18ndc(page.domain, "@option:check configure task sorting", "Keep launchers separate")
            enabled: sortingStrategy.currentValue === TaskManager.TasksModel.SortManual
        }
        QQC2.CheckBox {
            id: hideLauncherOnStart
            text: i18ndc(page.domain, "@option:check for icons-and-text task manager", "Hide launchers after application startup")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: minimizeActive
            Kirigami.FormData.label: i18ndc(page.domain, "@label for checkbox Part of a sentence: 'Clicking active task minimizes the task'", "Clicking active task:")
            text: i18ndc(page.domain, "@option:check Part of a sentence: 'Clicking active task minimizes the task'", "Minimizes the task")
        }
        QQC2.ComboBox {
            id: middleClickAction
            Kirigami.FormData.label: i18ndc(page.domain, "@label:listbox completes sentence like: … does nothing", "Middle-clicking any task:")
            Layout.fillWidth: true
            model: [
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Middle-clicking any task does nothing'", "Does nothing"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Middle-clicking any task closes window or group'", "Closes window or group"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Middle-clicking any task opens a new window'", "Opens a new window"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Middle-clicking any task minimizes/restores window or group'", "Minimizes/Restores window or group"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Middle-clicking any task toggles grouping'", "Toggles grouping"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Middle-clicking any task brings it to the current virtual desktop'", "Brings it to the current virtual desktop"),
            ]
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: wheelEnabled
            Kirigami.FormData.label: i18ndc(page.domain, "@label:listbox Part of a sentence: 'Scrolling behavior does nothing/cycles through tasks/cycles through the selected task's windows/adjusts the hovered task’s volume''", "Scrolling behavior:")
            Layout.fillWidth: true
            model: [
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Scrolling behavior does nothing'", "Does nothing"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Scrolling behavior cycles through all tasks'", "Cycles through all tasks"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Scrolling behavior cycles through the hovered task's windows'", "Cycles through the hovered task’s windows"),
                i18ndc(page.domain, "@item:inlistbox Part of a sentence: 'Scrolling behavior adjusts the hovered task’s volume'", "Adjusts the hovered task’s volume"),
            ]
        }
        QQC2.CheckBox {
            id: wheelSkipMinimized
            text: i18ndc(page.domain, "@option:check mouse wheel task cycling", "Skip minimized tasks")
            enabled: wheelEnabled.currentIndex !== 0
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showOnlyCurrentDesktop
            Kirigami.FormData.label: i18ndc(page.domain, "@label for checkbox group, completes sentence like: … from current screen", "Show only tasks:")
            text: i18ndc(page.domain, "@option:check completes sentence: show only tasks", "From the current desktop")
        }
        QQC2.CheckBox {
            id: showOnlyCurrentActivity
            text: i18ndc(page.domain, "@option:check completes sentence: show only tasks", "From the current activity")
        }
        QQC2.CheckBox {
            id: showOnlyCurrentScreen
            text: i18ndc(page.domain, "@option:check completes sentence: show only tasks", "From the current screen")
        }
        QQC2.CheckBox {
            id: showOnlyMinimized
            text: i18ndc(page.domain, "@option:check completes sentence: show only tasks", "That are minimized")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: unhideOnAttention
            Kirigami.FormData.label: i18ndc(page.domain, "@label for checkbox, completes sentence: … unhide if window wants attention", "When panel is hidden:")
            text: i18ndc(page.domain, "@option:check completes sentence: When panel is hidden", "Unhide when a window wants attention")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ButtonGroup {
            id: reverseGroup
        }
        QQC2.RadioButton {
            Kirigami.FormData.label: i18ndc(page.domain, "@label for radiobutton group completes sentence like: … on the bottom", "New tasks appear:")
            checked: !reverseMode.checked
            text: page.vertical ? i18ndc(page.domain, "@option:check completes sentence: New tasks appear", "On the bottom")
                                : i18ndc(page.domain, "@option:check completes sentence: New tasks appear", "To the right")
            QQC2.ButtonGroup.group: reverseGroup
        }
        QQC2.RadioButton {
            id: reverseMode
            text: page.vertical ? i18ndc(page.domain, "@option:check completes sentence: New tasks appear", "On the top")
                                : i18ndc(page.domain, "@option:check completes sentence: New tasks appear", "To the left")
            QQC2.ButtonGroup.group: reverseGroup
        }
    }
}
