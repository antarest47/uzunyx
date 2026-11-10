/*
 * Battery: state, blocking sleep and screen locking, what else is blocking them,
 * the power profile and the charge limit. Plasma's battery applet goes compiled
 * into its plugin; its modules and translations are public enough to reuse.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.batterymonitor as BatteryMonitor

DetailPage {
    id: page

    required property var batteries
    required property int percent
    required property string stateName
    required property string iconName
    required property color tint
    signal settings()
    signal energyInfo()

    function tr(text) {
        return i18nd("plasma_applet_org.kde.plasma.battery", text);
    }
    function duration(msec) {
        const minutes = Math.round(msec / 60000);
        const hours = Math.floor(minutes / 60);
        return hours > 0 ? i18n("%1 h %2 min", hours, minutes % 60) : i18n("%1 min", minutes);
    }
    readonly property var profileNames: ({
        "power-saver": tr("Power Save"), "balanced": tr("Balanced"), "performance": tr("Performance")
    })
    readonly property var profileIcons: ({
        "power-saver": "battery-profile-powersave-symbolic", "balanced": "speedometer-symbolic",
        "performance": "battery-profile-performance-symbolic"
    })
    readonly property string blockLabel: i18ndc("plasma_applet_org.kde.plasma.battery", "@action:button Prevent an app from blocking automatic sleep and screen locking after inactivity", "Unblock")
    readonly property string allowLabel: i18ndc("plasma_applet_org.kde.plasma.battery", "@action:button Undo preventing an app from blocking automatic sleep and screen locking after inactivity", "Allow")
    readonly property int remaining: batteries.smoothedRemainingMsec
    readonly property int threshold: batteries.chargeStopThreshold

    title: i18n("Battery")

    BatteryMonitor.InhibitionControl {
        id: inhibition
        isSilent: true
    }
    BatteryMonitor.PowerProfilesControl {
        id: profiles
        isSilent: true
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing * 2
        Kirigami.Icon {
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: implicitWidth
            source: page.iconName
            isMask: true
            color: page.tint
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Kirigami.Heading {
                level: 2
                text: page.percent + " %"
                color: page.tint
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: page.remaining > 0 ? page.stateName + " · " + page.duration(page.remaining) : page.stateName
                opacity: 0.85
                elide: Text.ElideRight
            }
        }
    }

    ListRow {
        iconSource: inhibition.isManuallyInhibited ? "system-suspend-inhibited-symbolic" : "system-suspend-symbolic"
        title: i18ndc("plasma_applet_org.kde.plasma.battery", "@action:button Block sleep and screen locking after inactivity", "Manually Block Sleep and Screen Locking")
        subtitle: inhibition.isManuallyInhibited ? i18ndc("plasma_applet_org.kde.plasma.battery", "@label corresponding to Manually Block Sleep and Screen Locking toggle", "This will result in higher energy consumption.") : ""
        current: inhibition.isManuallyInhibited
        onClicked: {
            if (inhibition.isManuallyInhibited) {
                inhibition.uninhibit();
            } else {
                inhibition.inhibit(i18n("Blocked from the control center"));
            }
        }
    }
    Repeater {
        model: inhibition.requestedInhibitions
        ListRow {
            required property var modelData
            iconSource: modelData.icon || "application-x-executable"
            monochrome: false
            title: modelData.prettyName || modelData.appName
            subtitle: modelData.reason || ""
            PlasmaComponents.ToolButton {
                text: modelData.allowed ? page.blockLabel : page.allowLabel
                onClicked: inhibition.setInhibitionAllowed(modelData.appName, modelData.reason, !modelData.allowed)
            }
        }
    }

    Kirigami.Heading {
        visible: profiles.isPowerProfileDaemonInstalled && profiles.profiles.length > 0
        Layout.topMargin: Kirigami.Units.smallSpacing
        level: 5
        text: page.tr("Power Profile")
    }
    Repeater {
        model: profiles.isPowerProfileDaemonInstalled ? profiles.profiles : []
        ListRow {
            required property string modelData
            iconSource: page.profileIcons[modelData] || "speedometer-symbolic"
            title: page.profileNames[modelData] || modelData
            current: profiles.activeProfile === modelData
            onClicked: profiles.setProfile(modelData)
        }
    }

    PlasmaComponents.Label {
        visible: page.threshold > 0 && page.threshold < 100
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        wrapMode: Text.WordWrap
        opacity: 0.85
        text: i18nd("plasma_applet_org.kde.plasma.battery", "Battery is configured to charge up to approximately %1%.", page.threshold)
    }

    ListRow {
        Layout.topMargin: Kirigami.Units.smallSpacing
        iconSource: "configure-symbolic"
        title: page.tr("&Configure Power Management…").replace("&", "")
        onClicked: page.settings()
    }
    ListRow {
        iconSource: "utilities-energy-monitor"
        monochrome: false
        title: page.tr("&Show Energy Information…").replace("&", "")
        onClicked: page.energyInfo()
    }
}
