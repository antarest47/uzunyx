/*
 * The clipboard history, from Plasma's own model: images show as images. A click
 * makes an entry the current one.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.clipboard as Clipboard

DetailPage {
    id: page

    signal done()

    // The roles' values for an image, as in Plasma's own clipboard.
    readonly property int imageType: 4

    title: i18n("Clipboard")

    Clipboard.HistoryModel {
        id: history
    }

    PlasmaComponents.Label {
        visible: history.count === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: i18n("The clipboard is empty")
        opacity: 0.8
    }
    Repeater {
        model: history
        delegate: Item {
            id: entry

            required property int index
            required property var display
            required property var decoration
            required property size imageSize
            required property var uuid
            required property int type
            readonly property bool isImage: type === page.imageType
            readonly property bool current: index === 0

            Layout.fillWidth: true
            implicitHeight: isImage ? Kirigami.Units.gridUnit * 6 : row.implicitHeight

            ListRow {
                id: row
                anchors.fill: entry.isImage ? parent : undefined
                width: parent.width
                iconSource: entry.isImage ? "" : entry.current ? "edit-paste-symbolic" : "edit-copy-symbolic"
                title: entry.isImage ? "" : String(entry.display).replace(/\s+/g, " ")
                current: entry.current
                onClicked: {
                    history.moveToTop(entry.uuid);
                    page.done();
                }
                PlasmaComponents.ToolButton {
                    icon.name: "edit-delete-symbolic"
                    onClicked: history.remove(entry.uuid)
                    PlasmaComponents.ToolTip { text: i18n("Remove") }
                }
            }
            Image {
                visible: entry.isImage
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.gridUnit * 2.5
                source: entry.isImage ? entry.decoration : ""
                sourceSize.height: Kirigami.Units.gridUnit * 6
                cache: false
                smooth: true
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
            }
        }
    }
    PlasmaComponents.Button {
        visible: history.count > 0
        Layout.alignment: Qt.AlignRight
        icon.name: "edit-clear-history-symbolic"
        text: i18n("Clear history")
        onClicked: history.clearHistory()
    }
}
