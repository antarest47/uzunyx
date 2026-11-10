/*
 * The rest of Plasma's tray, inside the control center: the widgets we have no
 * controls for. Each opens here, with its own content created from the tray's
 * applet, so the tray's window never opens.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

DetailPage {
    id: page

    required property var tray
    property var openApplet: null
    property var content: null
    // These already have their controls in the control center.
    readonly property var covered: ["org.kde.plasma.battery", "org.kde.plasma.bluetooth",
        "org.kde.plasma.brightness", "org.kde.plasma.clipboard", "org.kde.plasma.devicenotifier",
        "org.kde.plasma.keyboardindicator", "org.kde.plasma.networkmanagement", "org.kde.plasma.volume",
        "org.uzunyx.tiling"]
    signal done()

    function open(applet) {
        openApplet = applet;
        content = applet.fullRepresentation.createObject(holder, { "width": holder.width, "height": holder.height });
    }
    function close() {
        if (content) {
            content.destroy();
            content = null;
        }
        openApplet = null;
    }

    title: openApplet ? openApplet.plasmoid.title : i18n("More")
    onBack: {
        if (openApplet) {
            close();
        } else {
            done();
        }
    }
    Component.onDestruction: close()

    Item {
        id: holder
        visible: page.openApplet !== null
        Layout.fillWidth: true
        implicitHeight: visible ? Kirigami.Units.gridUnit * 17 : 0
        onWidthChanged: if (page.content) page.content.width = width
        onHeightChanged: if (page.content) page.content.height = height
    }

    Repeater {
        model: page.tray ? page.tray.systemTrayModel : null
        delegate: ListRow {
            required property var model
            readonly property var applet: model.hasApplet ? model.applet : null
            visible: !page.openApplet && applet !== null && applet !== undefined
                && model.effectiveStatus !== PlasmaCore.Types.HiddenStatus
                && page.covered.indexOf(applet.plasmoid.pluginName) < 0
            iconSource: applet ? applet.plasmoid.icon : ""
            monochrome: false
            title: applet ? applet.plasmoid.title : ""
            subtitle: applet ? applet.toolTipSubText : ""
            onClicked: page.open(applet)
        }
    }
}
