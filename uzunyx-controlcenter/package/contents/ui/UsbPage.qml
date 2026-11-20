/*
 * Removable drives, with what Plasma's device notifier does: open, mount, unmount,
 * unlock an encrypted one (KDE's passphrase dialog, from the helper) and eject. The
 * control center opens here by itself when one is plugged in.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

DetailPage {
    id: page

    required property var helper
    property var drives: []
    property string error: ""
    // Devices waiting for the helper (unlocking waits for the passphrase).
    property var busy: ({})
    signal open(string folder)

    // Menu entries that are hidden take no room.
    component MenuEntry: PlasmaComponents.MenuItem {
        height: visible ? implicitHeight : 0
    }

    function reload() {
        helper.call(["usb"], result => drives = result || []);
    }
    function act(command, device, failureText) {
        const b = Object.assign({}, busy);
        b[device] = true;
        busy = b;
        error = "";
        helper.call(device === "all" ? [command] : [command, device], (result, failure) => {
            const after = Object.assign({}, busy);
            delete after[device];
            busy = after;
            if (failure) {
                error = failure.indexOf("wrong passphrase") >= 0 ? i18n("Wrong passphrase") : failureText;
            }
            reload();
        });
    }
    function sizeText(bytes) {
        if (!bytes) {
            return "";
        }
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Number(bytes), unit = 0;
        while (value >= 1000 && unit < units.length - 1) {
            value /= 1000;
            unit++;
        }
        // One decimal under 10, with the locale's comma: «1,5 TB»; «1 TB», not «1,0 TB».
        const whole = value >= 10 || unit === 0 || Math.round(value * 10) % 10 === 0;
        return (whole ? Math.round(value) : value.toLocaleString(Qt.locale(), "f", 1)) + " " + units[unit];
    }
    function subtitle(drive) {
        let text = sizeText(drive.size);
        if (drive.mount && drive.free) {
            text += " · " + i18n("%1 free", sizeText(drive.free));
        } else if (drive.encrypted && !drive.unlocked) {
            text += " · " + i18n("Locked");
        } else if (!drive.mount) {
            text += " · " + i18n("Not mounted");
        }
        return text;
    }

    title: i18n("Devices")
    Component.onCompleted: reload()
    actions: PlasmaComponents.ToolButton {
        visible: page.drives.length > 0
        text: i18n("Eject all")
        onClicked: page.act("usb-eject-all", "all", i18n("The drive is in use"))
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: page.reload()
    }
    PlasmaComponents.Label {
        visible: page.drives.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: i18n("No removable devices")
        opacity: 0.8
    }
    PlasmaComponents.Label {
        visible: page.error.length > 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: Kirigami.Theme.negativeTextColor
        text: page.error
    }
    Repeater {
        model: page.drives
        delegate: ListRow {
            id: drive
            required property var modelData
            readonly property bool mounted: modelData.mount.length > 0
            readonly property bool locked: modelData.encrypted && !modelData.unlocked
            readonly property bool working: page.busy[modelData.device] === true

            iconSource: locked ? "object-locked-symbolic"
                : modelData.encrypted ? "object-unlocked-symbolic" : "drive-removable-media-usb-symbolic"
            title: modelData.label || (modelData.encrypted ? i18n("Encrypted drive") : modelData.device)
            subtitle: page.subtitle(modelData)
            current: mounted
            onClicked: {
                if (mounted) {
                    page.open(modelData.mount);
                } else if (locked) {
                    page.act("usb-unlock", modelData.device, i18n("Could not unlock the drive"));
                } else {
                    page.act("usb-mount", modelData.device, i18n("Could not mount the drive"));
                }
            }
            onRightClicked: menu.popup()

            PlasmaComponents.BusyIndicator {
                visible: drive.working
                running: visible
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: implicitWidth
            }
            PlasmaComponents.Button {
                visible: !drive.working && !drive.mounted
                text: drive.locked ? i18n("Unlock") : i18n("Mount")
                onClicked: drive.clicked()
            }
            PlasmaComponents.ToolButton {
                visible: !drive.working && drive.mounted
                icon.name: "document-open-folder-symbolic"
                onClicked: page.open(drive.modelData.mount)
                PlasmaComponents.ToolTip { text: i18n("Open") }
            }
            PlasmaComponents.ToolButton {
                visible: !drive.working
                icon.name: "media-eject-symbolic"
                onClicked: page.act("usb-eject", drive.modelData.device, i18n("The drive is in use"))
                PlasmaComponents.ToolTip { text: i18n("Eject") }
            }

            PlasmaComponents.Menu {
                id: menu
                MenuEntry {
                    visible: drive.mounted
                    text: i18n("Open")
                    icon.name: "document-open-folder-symbolic"
                    onClicked: page.open(drive.modelData.mount)
                }
                MenuEntry {
                    visible: !drive.mounted
                    text: drive.locked ? i18n("Unlock") : i18n("Mount")
                    icon.name: drive.locked ? "object-unlocked-symbolic" : "media-mount-symbolic"
                    onClicked: drive.clicked()
                }
                MenuEntry {
                    visible: drive.mounted || drive.modelData.unlocked
                    text: drive.modelData.encrypted ? i18n("Unmount and lock") : i18n("Unmount")
                    icon.name: "media-eject-symbolic"
                    onClicked: page.act("usb-unmount", drive.modelData.device, i18n("The drive is in use"))
                }
                MenuEntry {
                    text: i18n("Eject")
                    icon.name: "media-eject-symbolic"
                    onClicked: page.act("usb-eject", drive.modelData.device, i18n("The drive is in use"))
                }
            }
        }
    }
}
