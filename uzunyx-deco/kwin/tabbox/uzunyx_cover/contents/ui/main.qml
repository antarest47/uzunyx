/*
 * Alt+Tab in the style of Cover Switch: live previews, the chosen window facing
 * the viewer and the others turned away at its sides. Rotation around the Y axis
 * gives the perspective; the windows on each side are stacked towards the centre.
 */
import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    Instantiator {
        active: tabBox.visible
        delegate: Window {
            id: stage

            readonly property int duration: 220
            readonly property real coverWidth: Math.round(width * 0.46)
            readonly property real coverHeight: Math.round(height * 0.56)
            readonly property int count: covers.count

            x: tabBox.screenGeometry.x
            y: tabBox.screenGeometry.y
            width: tabBox.screenGeometry.width
            height: tabBox.screenGeometry.height
            flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
            color: "transparent"
            visible: true

            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.backgroundColor
                opacity: 0.72
            }

            Item {
                id: scene
                anchors.fill: parent
                focus: true

                Keys.onLeftPressed: tabBox.currentIndex = (tabBox.currentIndex - 1 + stage.count) % stage.count
                Keys.onRightPressed: tabBox.currentIndex = (tabBox.currentIndex + 1) % stage.count

                Repeater {
                    id: covers
                    model: tabBox.model

                    delegate: Item {
                        id: cover

                        required property int index
                        required property var model

                        // Shortest way around from the chosen window: negative on the left.
                        readonly property int offset: {
                            const half = stage.count / 2;
                            let d = (index - tabBox.currentIndex + stage.count) % stage.count;
                            return d > half ? d - stage.count : d;
                        }
                        readonly property int distance: Math.abs(offset)
                        readonly property int side: offset === 0 ? 0 : (offset > 0 ? 1 : -1)
                        readonly property bool chosen: offset === 0

                        width: stage.coverWidth
                        height: stage.coverHeight
                        y: Math.round((stage.height - height) / 2 - stage.height * 0.03)
                        x: Math.round((stage.width - width) / 2 + side * (stage.width * 0.27 + (distance - 1) * stage.width * 0.055))
                        z: 100 - distance
                        scale: chosen ? 1 : 0.8
                        opacity: distance > 3 ? 0 : (distance > 2 ? 0.45 : 1)

                        Behavior on x { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: stage.duration } }

                        transform: Rotation {
                            origin.x: cover.width / 2
                            origin.y: cover.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: -cover.side * 58
                            Behavior on angle { NumberAnimation { duration: stage.duration; easing.type: Easing.OutCubic } }
                        }

                        // The frame hugs the window, whatever its shape.
                        readonly property real fit: thumbnail.implicitWidth > 0 && thumbnail.implicitHeight > 0
                            ? Math.min(width / thumbnail.implicitWidth, height / thumbnail.implicitHeight) : 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: cover.fit > 0 ? thumbnail.implicitWidth * cover.fit + 6 : parent.width
                            height: cover.fit > 0 ? thumbnail.implicitHeight * cover.fit + 6 : parent.height
                            radius: 8
                            color: Kirigami.Theme.alternateBackgroundColor
                            border.width: cover.chosen ? 2 : 1
                            border.color: cover.chosen ? Kirigami.Theme.focusColor : Qt.rgba(1, 1, 1, 0.25)
                        }

                        KWin.WindowThumbnail {
                            id: thumbnail
                            anchors.fill: parent
                            anchors.margins: 3
                            wId: cover.model.windowId
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: tabBox.model.activate(cover.index)
                        }
                    }
                }

                Row {
                    id: title
                    readonly property var current: covers.count > 0 ? covers.itemAt(tabBox.currentIndex) : null
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height / 2 + stage.coverHeight / 2 + parent.height * 0.015)
                    spacing: Kirigami.Units.largeSpacing
                    visible: current !== null

                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        source: title.current ? title.current.model.icon : ""
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, stage.width * 0.6)
                        text: title.current ? title.current.model.caption : ""
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
