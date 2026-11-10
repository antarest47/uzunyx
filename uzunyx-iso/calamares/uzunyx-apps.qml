// "Aplicaciones" page of Calamares (packagechooserq@apps, uzunyx-apps.conf): the
// default install or the extended selection, which uzunyx-install-apps
// downloads at the end. Approved mockup of 2026-11-08.
import QtQuick
import QtQuick.Controls

Item {
    id: page

    readonly property color accent: "#e62967"
    readonly property color text: "#f2f2f7"
    readonly property color dim: "#c8ccd6"
    readonly property string kora: "file:///usr/share/icons/kora/apps/scalable/"
    property string choice: "default"

    function choose(id) {
        choice = id;
        config.packageChoice = id;
    }
    Component.onCompleted: choose(choice)

    // The page's own background, Akane's window: a QQuickWidget is white
    // underneath, and the cards and text are dark-only.
    Rectangle {
        anchors.fill: parent
        color: "#111318"
    }

    component Option: Rectangle {
        id: option
        property string optionId
        property alias title: titleText.text
        property alias body: bodyText.text
        property var apps: []
        readonly property bool chosen: page.choice === optionId
        width: parent.width
        height: column.implicitHeight + 24
        radius: 10
        color: chosen ? "#22151c" : "#171920"
        border.color: chosen ? page.accent : "#343944"
        border.width: chosen ? 2 : 1

        Rectangle {
            x: 14
            y: 14
            width: 16
            height: 16
            radius: 8
            color: "transparent"
            border.color: option.chosen ? page.accent : "#6b7180"
            border.width: 2
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: page.accent
                visible: option.chosen
            }
        }
        Column {
            id: column
            x: 42
            y: 12
            width: parent.width - 56
            spacing: 4
            Text {
                id: titleText
                color: page.text
                font.pixelSize: 15
                font.weight: Font.Bold
            }
            Text {
                id: bodyText
                width: parent.width
                color: page.dim
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
            Flow {
                width: parent.width
                topPadding: 6
                spacing: 6
                Repeater {
                    model: option.apps
                    Column {
                        required property var modelData
                        width: 70
                        spacing: 3
                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 34
                            height: 34
                            sourceSize: Qt.size(68, 68)
                            source: modelData[0]
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            color: "#d9dce4"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            text: modelData[1]
                        }
                    }
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: page.choose(option.optionId)
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        Column {
            width: parent.width
            spacing: 4
            Text {
                color: page.text
                font.pixelSize: 19
                font.weight: Font.Bold
                text: "Aplicaciones"
            }
            Text {
                color: page.dim
                font.pixelSize: 13
                text: "¿Qué quieres instalar además del escritorio?"
            }
        }
        Option {
            optionId: "default"
            title: "Instalación por defecto"
            body: "Lo justo para empezar: navegador, archivos, terminal, editor y visores."
            apps: [[page.kora + "firefox.svg", "Firefox"],
                   ["file:///usr/share/icons/uzunyx/apps/scalable/org.kde.dolphin.svg", "Dolphin"],
                   [page.kora + "org.kde.konsole.svg", "Konsole"],
                   [page.kora + "org.kde.kate.svg", "Kate"],
                   [page.kora + "org.kde.gwenview.svg", "Gwenview"],
                   [page.kora + "org.kde.okular.svg", "Okular"],
                   [page.kora + "org.kde.ark.svg", "Ark"]]
        }
        Option {
            optionId: "extended"
            title: "Selección ampliada"
            body: "Todo lo anterior y además ofimática, correo, música, vídeo e imagen. Se descargan al final de "
                + "la instalación: hace falta internet; sin conexión queda la instalación por defecto."
            apps: [[page.kora + "libreoffice-startcenter.svg", "LibreOffice"],
                   [page.kora + "thunderbird.svg", "Thunderbird"],
                   [page.kora + "vlc.svg", "VLC"],
                   [page.kora + "org.kde.elisa.svg", "Elisa"],
                   [page.kora + "gimp.svg", "GIMP"],
                   [page.kora + "org.kde.kcalc.svg", "KCalc"]]
        }
        Text {
            color: page.dim
            font.pixelSize: 12
            text: "Más aplicaciones cuando quieras, desde Discover."
        }
    }
}
