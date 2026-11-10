import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// Two cards (Akane, Sora) with their wallpaper and logo, and below them the
// parts to change. Apply runs uzunyx-edition (kcm.save()).
KCM.GridViewKCM {
    id: root

    readonly property var editions: [
        {
            edition: "akane",
            name: "Uzunyx Akane",
            description: i18n("Crimson"),
            wallpaper: "UzunyxAkane",
            logo: "uzunyx-akane",
        },
        {
            edition: "sora",
            name: "Uzunyx Sora",
            description: i18n("Cyan"),
            wallpaper: "UzunyxSora",
            logo: "uzunyx-sora",
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

    header: Kirigami.InlineMessage {
        position: Kirigami.InlineMessage.Position.Header
        type: Kirigami.MessageType.Error
        visible: kcm.errorText !== ""
        text: kcm.errorText
        showCloseButton: true
    }

    view.model: editions
    view.currentIndex: indexOf(kcm.selectedEdition)
    view.enabled: !kcm.busy

    view.delegate: KCM.GridDelegate {
        id: delegate

        required property var modelData
        required property int index

        text: modelData.name
        subtitle: kcm.currentEdition === modelData.edition ? i18n("Current edition") : modelData.description
        toolTip: modelData.name

        thumbnailAvailable: true
        thumbnail: Item {
            anchors.fill: parent

            Image {
                anchors.fill: parent
                source: kcm.wallpaperPreview(delegate.modelData.wallpaper)
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
                source: delegate.modelData.logo
            }
        }

        onClicked: {
            kcm.selectedEdition = modelData.edition;
            root.view.forceActiveFocus();
        }
    }

    footer: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Change, without touching the panels or the icons:")
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            enabled: !kcm.busy

            QQC2.CheckBox {
                text: i18n("Theme and colors")
                checked: kcm.applyTheme
                onToggled: kcm.applyTheme = checked
            }
            QQC2.CheckBox {
                text: i18n("Desktop wallpaper")
                checked: kcm.applyWallpaper
                onToggled: kcm.applyWallpaper = checked
            }
            QQC2.CheckBox {
                text: i18n("Lock screen")
                checked: kcm.applyLock
                onToggled: kcm.applyLock = checked
            }
            QQC2.CheckBox {
                text: i18n("Launcher icon")
                checked: kcm.applyLauncher
                onToggled: kcm.applyLauncher = checked
            }
        }

        QQC2.CheckBox {
            enabled: !kcm.busy
            text: i18n("Login screen too (all users; asks for the administrator password)")
            checked: kcm.applySddm
            onToggled: kcm.applySddm = checked
        }

        QQC2.CheckBox {
            visible: kcm.plymouthAvailable
            enabled: !kcm.busy
            text: i18n("Boot screen too (all users; asks for the administrator password; takes a while)")
            checked: kcm.applyPlymouth
            onToggled: kcm.applyPlymouth = checked
        }

        QQC2.Button {
            visible: kcm.shortcutsAvailable()
            icon.name: "preferences-desktop-keyboard-shortcuts"
            text: i18n("Keyboard shortcuts…")
            onClicked: kcm.showShortcuts()
        }

        RowLayout {
            visible: kcm.busy
            spacing: Kirigami.Units.smallSpacing

            QQC2.BusyIndicator {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                running: kcm.busy
            }
            QQC2.Label {
                text: i18n("Applying…")
            }
        }
    }
}
