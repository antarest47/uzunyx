import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// Cards instead of checkboxes: the edition (Akane, Sora), the parts it
// changes and how windows get the focus, each with a drawn preview. The
// previews of the parts show the selected edition. Apply runs uzunyx-edition
// (kcm.save()).
KCM.SimpleKCM {
    id: root

    // Colors from uzunyx-colors (gen-colors.py): accent and selection.
    readonly property var editions: [
        {
            edition: "akane",
            name: "Uzunyx Akane",
            description: i18n("Crimson"),
            wallpaper: "UzunyxAkane",
            sky: "UzunyxAkaneSky",
            logo: "uzunyx-akane",
            accent: "#e62967",
            selected: "#a51e4e",
        },
        {
            edition: "sora",
            name: "Uzunyx Sora",
            description: i18n("Cyan"),
            wallpaper: "UzunyxSora",
            sky: "UzunyxSoraSky",
            logo: "uzunyx-sora",
            accent: "#16cde0",
            selected: "#078fa8",
        },
    ]

    function indexOf(edition) {
        for (let i = 0; i < editions.length; i++) {
            if (editions[i].edition === edition) {
                return i;
            }
        }
        return -1;
    }

    readonly property var shown: editions[Math.max(0, indexOf(kcm.selectedEdition))]
    readonly property int cardColumns: Math.max(1, Math.min(3, Math.floor(width / (Kirigami.Units.gridUnit * 10))))

    header: Kirigami.InlineMessage {
        position: Kirigami.InlineMessage.Position.Header
        type: Kirigami.MessageType.Error
        visible: kcm.errorText !== ""
        text: kcm.errorText
        showCloseButton: true
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        enabled: !kcm.busy

        Kirigami.Heading {
            level: 4
            text: i18n("Edition")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.cardColumns > 1 ? 2 : 1
            uniformCellWidths: true
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            Repeater {
                model: root.editions

                ToggleCard {
                    id: editionCard

                    required property var modelData

                    exclusive: true
                    previewRatio: 0.45
                    text: modelData.name
                    subtitle: kcm.currentEdition === modelData.edition ? i18n("Current edition") : modelData.description
                    checked: kcm.selectedEdition === modelData.edition
                    onClicked: kcm.selectedEdition = modelData.edition

                    Image {
                        anchors.fill: parent
                        source: kcm.wallpaperPreview(editionCard.modelData.wallpaper)
                        sourceSize.width: 640
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Kirigami.Icon {
                        anchors {
                            left: parent.left
                            bottom: parent.bottom
                            margins: Kirigami.Units.smallSpacing
                        }
                        width: Kirigami.Units.iconSizes.large
                        height: width
                        source: editionCard.modelData.logo
                    }
                }
            }
        }

        Kirigami.Heading {
            Layout.topMargin: Kirigami.Units.largeSpacing
            level: 4
            text: i18n("What changes with the edition")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.cardColumns
            uniformCellWidths: true
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            ToggleCard {
                text: i18n("Theme and colors")
                checked: kcm.applyTheme
                onClicked: kcm.applyTheme = !kcm.applyTheme

                Rectangle {
                    anchors.fill: parent
                    color: "#111318"

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: parent.width * 0.12
                            rightMargin: parent.width * 0.12
                            topMargin: parent.height * 0.14
                            bottomMargin: parent.height * 0.1
                        }
                        radius: 3
                        color: "#20232b"
                        border.width: 1
                        border.color: "#343944"

                        Column {
                            anchors {
                                fill: parent
                                margins: 6
                            }
                            spacing: 4

                            Rectangle {
                                width: parent.width
                                height: 7
                                radius: 2
                                color: "#2a2d35"
                            }
                            Rectangle {
                                width: parent.width
                                height: 7
                                radius: 2
                                color: root.shown.selected
                            }
                            Rectangle {
                                width: parent.width
                                height: 7
                                radius: 2
                                color: "#2a2d35"
                            }
                            Rectangle {
                                width: parent.width * 0.35
                                height: 7
                                radius: 3.5
                                color: root.shown.accent
                            }
                        }
                    }
                }
            }

            ToggleCard {
                text: i18n("Desktop wallpaper")
                checked: kcm.applyWallpaper
                onClicked: kcm.applyWallpaper = !kcm.applyWallpaper

                Image {
                    anchors.fill: parent
                    source: kcm.wallpaperPreview(root.shown.wallpaper)
                    sourceSize.width: 400
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 4
                    }
                    width: parent.width * 0.6
                    height: 8
                    radius: 3
                    color: Qt.alpha("#20232b", 0.85)
                }
            }

            ToggleCard {
                text: i18n("Lock screen")
                checked: kcm.applyLock
                onClicked: kcm.applyLock = !kcm.applyLock

                Image {
                    anchors.fill: parent
                    source: kcm.wallpaperPreview(root.shown.sky)
                    sourceSize.width: 400
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    QQC2.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "10:42"
                        color: "white"
                        font.bold: true
                    }
                    Rectangle {
                        width: 46
                        height: 8
                        radius: 4
                        color: Qt.alpha("white", 0.3)
                    }
                }
            }

            ToggleCard {
                text: i18n("Launcher icon")
                checked: kcm.applyLauncher
                onClicked: kcm.applyLauncher = !kcm.applyLauncher

                Rectangle {
                    anchors.fill: parent
                    color: "#181a20"

                    Rectangle {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 6
                        }
                        width: launcherRow.width + 10
                        height: launcherRow.height + 8
                        radius: 6
                        color: "#20232b"
                        border.width: 1
                        border.color: "#343944"

                        Row {
                            id: launcherRow
                            anchors.centerIn: parent
                            spacing: 5

                            Kirigami.Icon {
                                width: 18
                                height: 18
                                source: root.shown.logo
                            }
                            Repeater {
                                model: 3

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    radius: 3
                                    color: "#343944"
                                }
                            }
                        }
                    }
                }
            }

            ToggleCard {
                text: i18n("Login screen")
                subtitle: i18n("All users")
                subtitleIcon: "object-locked"
                checked: kcm.applySddm
                onClicked: kcm.applySddm = !kcm.applySddm

                Image {
                    anchors.fill: parent
                    source: kcm.wallpaperPreview(root.shown.sky)
                    sourceSize.width: 400
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: Qt.alpha("white", 0.6)
                    }
                    Rectangle {
                        width: 50
                        height: 8
                        radius: 4
                        color: "#111318"
                    }
                }
            }

            ToggleCard {
                visible: kcm.plymouthAvailable
                text: i18n("Boot screen")
                subtitle: i18n("All users, takes a while")
                subtitleIcon: "object-locked"
                checked: kcm.applyPlymouth
                onClicked: kcm.applyPlymouth = !kcm.applyPlymouth

                Rectangle {
                    anchors.fill: parent
                    color: "#111318"

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Kirigami.Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 22
                            height: 22
                            source: root.shown.logo
                        }
                        QQC2.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "UZUNYX"
                            color: "#dddddd"
                            font.pixelSize: 8
                            font.letterSpacing: 2
                        }
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("The panels and the icons are not touched. The login and boot screens ask for the administrator password.")
            color: Kirigami.Theme.disabledTextColor
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
        }

        Kirigami.Heading {
            Layout.topMargin: Kirigami.Units.largeSpacing
            level: 4
            text: i18n("Window focus")
        }

        // Same order as UzunyxEditionsKcm::FocusMode. Two windows: A at the
        // top left, B at the bottom right; the pointer is on B (on A for
        // click to focus).
        GridLayout {
            Layout.fillWidth: true
            columns: root.cardColumns
            uniformCellWidths: true
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [
                    { title: i18n("With a click"), subtitle: i18n("Click to focus") },
                    { title: i18n("Follows the mouse"), subtitle: i18n("Without changing the order") },
                    { title: i18n("Follows and raises"), subtitle: i18n("Brings it to the front") },
                ]

                ToggleCard {
                    id: focusCard

                    required property var modelData
                    required property int index

                    exclusive: true
                    text: modelData.title
                    subtitle: modelData.subtitle
                    checked: kcm.focusMode === index
                    onClicked: kcm.focusMode = index

                    Rectangle {
                        anchors.fill: parent
                        color: "#181a20"
                    }
                    MiniWindow {
                        id: windowA
                        x: parent.width * 0.08
                        y: parent.height * 0.12
                        z: focusCard.index === 2 ? 0 : 1
                        width: parent.width * 0.55
                        height: parent.height * 0.6
                        focused: focusCard.index === 0
                        accent: Kirigami.Theme.highlightColor
                    }
                    MiniWindow {
                        x: parent.width * 0.4
                        y: parent.height * 0.35
                        width: parent.width * 0.52
                        height: parent.height * 0.55
                        focused: focusCard.index !== 0
                        accent: Kirigami.Theme.highlightColor
                    }
                    // Click: a ring where the pointer clicks.
                    Rectangle {
                        visible: focusCard.index === 0
                        x: pointer.x - width / 2 + 1
                        y: pointer.y - height / 2 + 1
                        z: 2
                        width: 14
                        height: 14
                        radius: 7
                        color: "transparent"
                        border.width: 1.5
                        border.color: "white"
                    }
                    Pointer {
                        id: pointer
                        x: focusCard.index === 0 ? parent.width * 0.3 : parent.width * 0.75
                        y: focusCard.index === 0 ? parent.height * 0.4 : parent.height * 0.68
                        z: 3
                    }
                    Kirigami.Icon {
                        visible: focusCard.index === 2
                        anchors {
                            right: parent.right
                            top: parent.top
                            margins: 4
                        }
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        z: 3
                        source: "go-up"
                        color: Kirigami.Theme.highlightColor
                        isMask: true
                    }
                }
            }
        }
    }

    footer: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            visible: kcm.shortcutsAvailable()
            icon.name: "preferences-desktop-keyboard-shortcuts"
            text: i18n("Keyboard shortcuts…")
            onClicked: kcm.showShortcuts()
        }

        Item {
            Layout.fillWidth: true
        }

        QQC2.BusyIndicator {
            visible: kcm.busy
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            running: kcm.busy
        }
        QQC2.Label {
            visible: kcm.busy
            text: i18n("Applying…")
        }
    }
}
