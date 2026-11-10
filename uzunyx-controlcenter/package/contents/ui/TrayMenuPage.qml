/*
 * The menu of an app in the background, inside the control center: submenus
 * open in the same list.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

DetailPage {
    id: page

    required property string source
    required property var helper
    property string appTitle
    property var entries: []
    // Parents of the submenu on screen.
    property var path: []
    property string error: ""
    signal done()

    readonly property string service: source.split("/")[0]
    readonly property string objectPath: "/" + source.split("/").slice(1).join("/")
    readonly property var shown: path.length > 0 ? path[path.length - 1].children : entries

    title: path.length > 0 ? path[path.length - 1].label : appTitle
    onBack: {
        if (path.length > 0) {
            path = path.slice(0, -1);
        } else {
            done();
        }
    }
    Component.onCompleted: helper.call(["tray-menu", service, objectPath], (result, failure) => {
        entries = result || [];
        error = failure ? i18n("This app has no menu") : "";
    })

    PlasmaComponents.Label {
        visible: page.error.length > 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: page.error
        opacity: 0.8
    }
    Repeater {
        model: page.shown.filter(e => e.visible)
        delegate: Item {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: modelData.type === "separator" ? Kirigami.Units.smallSpacing * 2 : row.implicitHeight

            Rectangle {
                visible: parent.modelData.type === "separator"
                anchors.centerIn: parent
                width: parent.width
                height: 1
                color: Kirigami.Theme.textColor
                opacity: 0.25
            }
            ListRow {
                id: row
                visible: parent.modelData.type !== "separator"
                anchors { left: parent.left; right: parent.right }
                enabled: parent.modelData.enabled
                opacity: enabled ? 1 : 0.5
                iconSource: parent.modelData.icon
                monochrome: false
                title: parent.modelData.label
                current: parent.modelData.checked
                onClicked: {
                    const item = parent.modelData;
                    if (item.children.length > 0) {
                        page.path = page.path.concat([item]);
                    } else {
                        page.helper.call(["tray-event", page.service, page.objectPath, item.id], () => {});
                        page.done();
                    }
                }
                Kirigami.Icon {
                    visible: row.parent.modelData.children.length > 0
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: implicitWidth
                    source: "go-next-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }
            }
        }
    }
}
