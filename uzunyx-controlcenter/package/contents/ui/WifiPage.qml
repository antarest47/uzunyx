/*
 * The Wi-Fi networks, from Plasma's own model: click one to connect, or the
 * connected one to disconnect. A secured network that isn't saved asks for its
 * password here. A saved one has a menu on right click to forget it, password and all.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.networkmanagement as PlasmaNM

DetailPage {
    id: page

    required property var handler
    signal settings()
    property string askingFor: ""

    title: i18n("Wi-Fi")
    Component.onCompleted: handler.requestScan()

    Repeater {
        model: PlasmaNM.AppletProxyModel {
            sourceModel: PlasmaNM.NetworkModel {}
        }
        delegate: ColumnLayout {
            id: network

            required property var model
            readonly property bool wireless: model.Type === PlasmaNM.Enums.Wireless
            readonly property bool connected: model.ConnectionState === PlasmaNM.Enums.Activated
            readonly property bool connecting: model.ConnectionState === PlasmaNM.Enums.Activating
            readonly property bool needsPassword: !model.Uuid && model.SecurityType !== PlasmaNM.Enums.NoneSecurity
            readonly property bool asking: page.askingFor === model.ItemUniqueName

            function disconnect() {
                page.handler.deactivateConnection(model.ConnectionPath, model.DevicePath);
            }
            function connect(password) {
                page.askingFor = "";
                if (model.Uuid) {
                    page.handler.activateConnection(model.ConnectionPath, model.DevicePath, model.SpecificPath);
                } else if (password) {
                    page.handler.addAndActivateConnection(model.DevicePath, model.SpecificPath, password);
                } else {
                    page.handler.addAndActivateConnection(model.DevicePath, model.SpecificPath);
                }
            }

            visible: wireless
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ListRow {
                iconSource: network.model.ConnectionIcon
                title: network.model.Name
                subtitle: network.connected ? i18n("Connected · click to disconnect")
                    : network.connecting ? i18n("Connecting…")
                    : network.model.SecurityTypeString
                current: network.connected
                onClicked: {
                    if (network.connected || network.connecting) {
                        network.disconnect();
                        return;
                    }
                    if (network.needsPassword) {
                        page.askingFor = network.asking ? "" : network.model.ItemUniqueName;
                    } else {
                        network.connect();
                    }
                }
                onRightClicked: {
                    if (network.model.Uuid) {
                        menu.popup();
                    }
                }
                PlasmaComponents.Menu {
                    id: menu
                    PlasmaComponents.MenuItem {
                        text: network.connected || network.connecting ? i18n("Disconnect") : i18n("Connect")
                        icon.name: network.connected || network.connecting ? "network-disconnect-symbolic" : "network-connect-symbolic"
                        onClicked: network.connected || network.connecting ? network.disconnect() : network.connect()
                    }
                    PlasmaComponents.MenuSeparator {}
                    PlasmaComponents.MenuItem {
                        text: i18n("Forget network")
                        icon.name: "edit-delete-symbolic"
                        onClicked: page.handler.removeConnection(network.model.ConnectionPath)
                    }
                }
            }
            RowLayout {
                visible: network.asking
                Layout.fillWidth: true
                PlasmaExtras.PasswordField {
                    id: password
                    Layout.fillWidth: true
                    onVisibleChanged: {
                        text = "";
                        if (visible) {
                            forceActiveFocus();
                        }
                    }
                    onAccepted: network.connect(text)
                }
                PlasmaComponents.Button {
                    text: i18n("Connect")
                    enabled: password.text.length > 0
                    onClicked: network.connect(password.text)
                }
            }
        }
    }

    PlasmaComponents.Button {
        Layout.alignment: Qt.AlignRight
        icon.name: "configure-symbolic"
        text: i18n("Network settings")
        onClicked: page.settings()
    }
}
