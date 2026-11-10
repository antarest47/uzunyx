/*
    SPDX-FileCopyrightText: 2026 emi <285864120+antarest47@users.noreply.github.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Uzunyx startup splash: the same picture as the boot splash
// (uzunyx-plymouth), so boot, login and desktop read as one sequence. The
// edition's icon, and under it its name with a shine sweeping over it and
// glints on its stars, on the palette's #111318. The images (icon.png,
// logo.png, glint.png) come from gen-splash.py, one set per edition.

import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#111318"

    property int stage

    // Sizes for a 1200 px tall screen, scaled to this one (the images are
    // twice that size).
    readonly property real unit: height / 1200
    // Animations follow the user's speed setting, and stop if they're off.
    readonly property bool animated: Kirigami.Units.longDuration > 1

    onStageChanged: {
        if (stage == 2) {
            fadeIn.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Column {
            // Same place as the boot splash: centred, a little above the middle.
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.height * 0.03
            spacing: 24 * root.unit

            Image {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220 * root.unit
                height: width * implicitHeight / Math.max(1, implicitWidth)
                source: "images/icon.png"
                smooth: true
                mipmap: true
            }

            Item {
                id: name
                anchors.horizontalCenter: parent.horizontalCenter
                width: 520 * root.unit
                height: width * logo.implicitHeight / Math.max(1, logo.implicitWidth)

                Image {
                    id: logo
                    anchors.fill: parent
                    source: "images/logo.png"
                    smooth: true
                    mipmap: true
                }

                // The shine: a slanted white band crossing the name, shown
                // only where the name is (the logo's alpha as a mask).
                Item {
                    id: band
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true

                    Rectangle {
                        id: stripe
                        width: name.width * 0.16
                        height: name.height * 2
                        y: -name.height / 2
                        x: -width * 2
                        rotation: 19
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
                            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.34) }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.62) }
                            GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, 0.34) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: band
                    maskEnabled: true
                    maskSource: logo
                    // The PNG has faint, almost transparent specks around the
                    // name: ignore them, with a soft edge.
                    maskThresholdMin: 0.4
                    maskSpreadAtMin: 0.4
                }

                SequentialAnimation {
                    running: root.animated && content.opacity > 0
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: stripe
                        property: "x"
                        from: -stripe.width * 2
                        to: name.width + stripe.width
                        duration: 1400
                        easing.type: Easing.InOutSine
                    }
                    PauseAnimation { duration: 2200 }
                }

                // Glints on the name's stars and pearls: position relative to
                // the name and size, as in the boot splash.
                Repeater {
                    model: [
                        [0.0925, 0.5925, 1.0], [0.5401, 0.7196, 1.0], [0.9406, 0.4461, 0.6],
                        [0.9558, 0.5580, 0.45], [0.1326, 0.6823, 0.45], [0.6552, 0.6823, 0.45],
                    ]

                    Image {
                        required property var modelData
                        required property int index
                        readonly property real size: 56 * root.unit * modelData[2]
                        x: modelData[0] * name.width - size / 2
                        y: modelData[1] * name.height - size / 2
                        width: size
                        height: size
                        source: "images/glint.png"
                        smooth: true
                        opacity: 0

                        // Each one twinkles once every 4 s, staggered.
                        SequentialAnimation on opacity {
                            running: root.animated
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 620 }
                            NumberAnimation { from: 0; to: 1; duration: 400; easing.type: Easing.OutQuad }
                            NumberAnimation { from: 1; to: 0; duration: 400; easing.type: Easing.InQuad }
                            PauseAnimation { duration: 4000 - 800 - index * 620 }
                        }
                    }
                }
            }
        }
    }

    OpacityAnimator {
        id: fadeIn
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
