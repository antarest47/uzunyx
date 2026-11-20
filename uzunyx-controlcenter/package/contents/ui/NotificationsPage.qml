/*
 * The notifications in the history, newest first: Plasma keeps them in its tray,
 * hidden here. A click does what the notification offers; the cross closes it.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.components as PlasmaComponents

DetailPage {
    id: page

    required property var notifications
    signal clearAll()

    title: i18n("Notifications")
    actions: PlasmaComponents.ToolButton {
        text: i18n("Clear all")
        onClicked: page.clearAll()
    }

    PlasmaComponents.Label {
        visible: page.notifications.count === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: i18n("No notifications")
        opacity: 0.8
    }
    Repeater {
        model: page.notifications
        delegate: ListRow {
            id: item
            required property var model
            required property int index
            readonly property bool runningJob: model.type === NotificationManager.Notifications.JobType
                && model.jobState !== NotificationManager.Notifications.JobStateStopped
            visible: !runningJob
            iconSource: model.applicationIconName || model.iconName || "notifications-symbolic"
            monochrome: false
            title: model.summary || model.applicationName || ""
            subtitle: (model.body || "").replace(/<[^>]*>/g, "")
            onClicked: {
                if (model.hasDefaultAction) {
                    page.notifications.invokeDefaultAction(page.notifications.index(index, 0));
                }
            }
            PlasmaComponents.ToolButton {
                icon.name: "dialog-close"
                onClicked: page.notifications.close(page.notifications.index(item.index, 0))
                PlasmaComponents.ToolTip { text: i18n("Close") }
            }
        }
    }
}
