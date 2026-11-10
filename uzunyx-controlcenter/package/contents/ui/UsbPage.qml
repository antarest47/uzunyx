/*
 * Removable drives: open, unmount or eject.
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
    signal open(string folder)

    function reload() {
        helper.call(["usb"], result => drives = result || []);
    }
    function act(command, device) {
        helper.call([command, device], (result, failure) => {
            error = failure ? i18n("The drive is in use") : "";
            reload();
        });
    }

    title: i18n("Devices")
    Component.onCompleted: reload()

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
        text: page.error
    }
    Repeater {
        model: page.drives
        delegate: ListRow {
            id: drive
            required property var modelData
            iconSource: "drive-removable-media-usb-symbolic"
            title: modelData.label || modelData.device
            subtitle: modelData.size + (modelData.mount ? " · " + modelData.mount : "")
            current: modelData.mount.length > 0
            onClicked: {
                if (modelData.mount) {
                    page.open(modelData.mount);
                } else {
                    page.helper.call(["usb-mount", modelData.device], () => page.reload());
                }
            }
            PlasmaComponents.ToolButton {
                visible: drive.modelData.mount.length > 0
                icon.name: "media-eject-symbolic"
                onClicked: page.act("usb-eject", drive.modelData.device)
                PlasmaComponents.ToolTip { text: i18n("Eject") }
            }
        }
    }
}
