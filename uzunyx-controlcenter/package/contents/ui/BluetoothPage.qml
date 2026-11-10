/*
 * The paired Bluetooth devices: click one to connect or disconnect. Pairing a new
 * one stays in Plasma's wizard.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.bluetooth as PlasmaBt

DetailPage {
    id: page

    signal addDevice()

    title: i18n("Bluetooth")

    PlasmaComponents.Label {
        visible: devices.count === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: BluezQt.Manager.bluetoothOperational ? i18n("No paired devices") : i18n("Bluetooth is off")
        opacity: 0.8
    }

    Repeater {
        id: devices
        model: PlasmaBt.DevicesProxyModel {
            hideBlockedDevices: true
            Component.onCompleted: sourceModel = PlasmaBt.SharedDevicesStateProxyModel
        }
        delegate: ListRow {
            required property var model
            iconSource: model.Icon || "network-bluetooth-symbolic"
            title: model.DeviceFullName || model.Name
            subtitle: model.Connecting ? i18n("Connecting…") : model.Connected ? i18n("Connected") : ""
            current: model.Connected
            onClicked: {
                if (model.Connected) {
                    model.Device.disconnectFromDevice();
                } else {
                    model.Device.connectToDevice();
                }
            }
        }
    }

    PlasmaComponents.Button {
        Layout.alignment: Qt.AlignRight
        icon.name: "list-add-symbolic"
        text: i18n("Add device…")
        onClicked: page.addDevice()
    }
}
