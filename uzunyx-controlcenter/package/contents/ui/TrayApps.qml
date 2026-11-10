/*
 * The icons of the apps in the background: a click opens the app, the right
 * button its menu. The list and icons are Plasma's own model (ask its roles by
 * name: going through them all brought the process down).
 */
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: apps

    required property var model
    signal menuRequested(string source, string title)
    signal activated(string source)
    signal more()

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: i18n("Apps in the background")
        font.weight: Font.DemiBold
    }
    Flow {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        // Plasma's tray, for what has no control here.
        Item {
            width: Kirigami.Units.iconSizes.medium + 8
            height: width
            Glass {
                anchors.fill: parent
                strength: moreMouse.containsMouse ? 0.4 : 0.08
            }
            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                source: "view-more-horizontal-symbolic"
                isMask: true
                color: Kirigami.Theme.textColor
            }
            MouseArea {
                id: moreMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: apps.more()
            }
            QQC2.ToolTip.text: i18n("More")
            QQC2.ToolTip.visible: moreMouse.containsMouse
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        Repeater {
            id: icons
            model: apps.model
            delegate: Item {
                id: app

                required property var model
                readonly property bool attention: model.Status === 3

                width: Kirigami.Units.iconSizes.medium + 8
                height: width

                Glass {
                    anchors.fill: parent
                    tint: app.attention ? "#ff1a0a" : "#aeb3bf"
                    strength: app.attention ? 0.9 : mouse.containsMouse ? 0.4 : 0.08
                }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    source: app.model.IconName ? app.model.IconName : app.model.Icon
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        if (event.button === Qt.RightButton || app.model.ItemIsMenu) {
                            apps.menuRequested(app.model.DataEngineSource, app.model.Title);
                        } else {
                            apps.activated(app.model.DataEngineSource);
                        }
                    }
                }
                QQC2.ToolTip.text: app.model.Title
                QQC2.ToolTip.visible: mouse.containsMouse
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
