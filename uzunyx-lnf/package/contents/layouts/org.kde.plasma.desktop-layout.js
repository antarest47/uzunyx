// Uzunyx desktop layout: Plasma's default panel
// (org.kde.plasma.desktop.defaultPanel), but floating, centered and sized
// to its content, with Tsunyx Launcher instead of Kickoff.

var panel = new Panel
panel.location = "bottom"
panel.floating = true
panel.lengthMode = "fit"
panel.alignment = "center"

// Same height as the default panel: next even number above 2.5 grid units.
panel.height = 2 * Math.ceil(gridUnit * 2.5 / 2)

// Fall back to Kickoff if Tsunyx Launcher (package tsunyx-launcher) is
// not installed, so the panel never ends up without a launcher.
var launcher = knownWidgetTypes.indexOf("local.tsunyxlauncher") !== -1
    ? "local.tsunyxlauncher" : "org.kde.plasma.kickoff"
// The launcher button shows the edition's logo (hicolor icon installed by
// this package; the Makefile sets the name for each edition).
var launcherWidget = panel.addWidget(launcher)
launcherWidget.currentConfigGroup = ["General"]
launcherWidget.writeConfig("icon", "uzunyx-akane")
// Search box between the launcher and the task manager (same package).
if (knownWidgetTypes.indexOf("local.tsunyxsearch") !== -1) {
    panel.addWidget("local.tsunyxsearch")
}
panel.addWidget(knownWidgetTypes.indexOf("org.uzunyx.pager") !== -1
    ? "org.uzunyx.pager" : "org.kde.plasma.pager")
// Clicking a group of windows shows their small previews (thumbnails)
// instead of cycling through them.
var tasks = panel.addWidget(knownWidgetTypes.indexOf("org.uzunyx.tasks") !== -1
    ? "org.uzunyx.tasks" : "org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["General"]
tasks.writeConfig("groupedTaskVisualization", 1)
// Pinned apps: the browser follows the user's default (Firefox, from
// /etc/xdg/mimeapps.list). Apps that aren't installed are left out, so the
// panel never shows a broken icon.
// The installer only exists in the live session of the ISO.
var pinned = ["calamares-install-debian.desktop",
              "systemsettings.desktop", "org.uzunyx.settings.desktop",
              "preferred://filemanager", "preferred://browser",
              "org.kde.konsole.desktop", "org.uzunyx.keys.desktop"]
tasks.writeConfig("launchers", pinned.filter(function (app) {
    return app.indexOf("preferred://") === 0 || applicationExists(app)
}).map(function (app) {
    return app.indexOf("preferred://") === 0 ? app : "applications:" + app
}))
panel.addWidget("org.kde.plasma.marginsseparator")

// Input Method Panel for languages that usually need one (same list as
// the default panel template).
var langIds = ["as", "bn", "bo", "brx", "doi", "gu", "hi", "ja", "kn", "ko",
               "kok", "ks", "lep", "mai", "ml", "mni", "mr", "ne", "or", "pa",
               "sa", "sat", "sd", "si", "ta", "te", "th", "ur", "vi", "zh_CN",
               "zh_TW"]
if (langIds.indexOf(languageId) != -1) {
    panel.addWidget("org.kde.plasma.kimpanel")
}

// Control center (uzunyx-controlcenter): a single pill with the lock keys,
// network, volume and battery. Without it, each of those on its own.
var controlCenter = knownWidgetTypes.indexOf("org.uzunyx.controlcenter") !== -1
var lockKeys = false
if (controlCenter) {
    panel.addWidget("org.uzunyx.controlcenter")
} else {
    // Caps Lock / Num Lock indicator (uzunyx-lockkeys), if installed.
    lockKeys = knownWidgetTypes.indexOf("org.uzunyx.lockkeys") !== -1
    if (lockKeys) {
        panel.addWidget("org.uzunyx.lockkeys")
    }
}
var tray = panel.addWidget("org.kde.plasma.systemtray")
// Plasma's items that our widgets replace stay out of the tray. It has
// already enabled its default items by now, so take them out of extraItems;
// being in knownItems keeps them from coming back, and the tray still
// enables any other default item it hasn't seen yet.
var replaced = []
if (controlCenter) {
    replaced.push("org.kde.plasma.battery")
}
if (lockKeys || controlCenter) {
    replaced.push("org.kde.plasma.keyboardindicator")
}
if (replaced.length > 0) {
    tray.currentConfigGroup = ["General"]
    tray.writeConfig("extraItems", String(tray.readConfig("extraItems")).split(",").filter(function (item) {
        return replaced.indexOf(item) === -1
    }))
    tray.writeConfig("knownItems", replaced)
    tray.reloadConfig()
}
// The control center has what the tray showed, and keeps the tray out of sight.
// Not removed: notifications live in the tray, and its "More" button opens it.
if (controlCenter) {
    tray.currentConfigGroup = ["General"]
    tray.writeConfig("hiddenItems", String(tray.readConfig("extraItems")).split(","))
    tray.reloadConfig()
}
if (knownWidgetTypes.indexOf("org.uzunyx.clock") !== -1) {
    panel.addWidget("org.uzunyx.clock")
} else {
    // 24-hour time and a short custom date ("dom, 25 de oct." in Spanish).
    var clock = panel.addWidget("org.kde.plasma.digitalclock")
    clock.currentConfigGroup = ["Appearance"]
    clock.writeConfig("use24hFormat", 2)
    clock.writeConfig("dateFormat", "custom")
    clock.writeConfig("customDateFormat", "ddd, d 'de' MMM")
}
panel.addWidget("org.kde.plasma.showdesktop")

// Leave button: only "Leave…", which opens the logout screen with shut
// down, restart, sleep and log out (no separate lock button).
if (controlCenter) {
    // In the control center.
} else if (knownWidgetTypes.indexOf("org.uzunyx.logout") !== -1) {
    panel.addWidget("org.uzunyx.logout")
} else {
    var leave = panel.addWidget("org.kde.plasma.lock_logout")
    leave.currentConfigGroup = ["General"]
    leave.writeConfig("show_lockScreen", false)
    leave.writeConfig("show_requestLogoutScreen", true)
}

var desktopsArray = desktopsForActivity(currentActivity())
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image'
    // Desktop icons in columns from the top right, as on macOS.
    desktopsArray[j].currentConfigGroup = ["General"]
    desktopsArray[j].writeConfig("arrangement", 1)
    desktopsArray[j].writeConfig("alignment", 1)
}

// Notifications at the bottom right of the screen, whatever the panel's width.
// Not in /etc/xdg: plasma-workspace owns /etc/xdg/plasmanotifyrc.
var notifications = ConfigFile("plasmanotifyrc")
notifications.group = "Notifications"
notifications.writeEntry("PopupPosition", "BottomRight")
