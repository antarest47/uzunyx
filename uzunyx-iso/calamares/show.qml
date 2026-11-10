// Slideshow while Calamares installs: Akane and Sora say hello, then the two
// editions, the panel, the control center, Tsunyx and the shortcuts. The
// pictures are in slides/ (build-iso.sh gathers them). Approved mockup of
// 2026-11-08.
import QtQuick
import calamares.slideshow 1.0
import "slides"

Presentation {
    id: presentation

    readonly property color accent: "#e62967"
    readonly property color akane: "#ff5a8c"
    readonly property color sora: "#4fd2ff"
    readonly property color text: "#f2f2f7"
    readonly property color dim: "#c8ccd6"

    // A slide that fills the whole area (Calamares' Slide leaves margins for
    // a title).
    component Full: Slide {
        x: 0
        y: 0
        width: presentation.width
        height: presentation.height
    }

    // Title and text at the bottom-left, over a picture or not.
    component Caption: Column {
        property alias title: titleText.text
        property alias titleColor: titleText.color
        property alias body: bodyText.text
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 6
        Text {
            id: titleText
            color: presentation.text
            font.pixelSize: 24
            font.weight: Font.ExtraBold
        }
        Text {
            id: bodyText
            width: parent.width
            color: "#e4e6ec"
            font.pixelSize: 14
            lineHeight: 1.1
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
        }
    }

    // Dark at the bottom so the caption reads over a wallpaper.
    component Shade: Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.35; color: "#000a0b0e" }
            GradientStop { position: 0.62; color: "#8c0a0b0e" }
            GradientStop { position: 1.0; color: "#eb0a0b0e" }
        }
    }

    component Glow: Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#111318" }
            GradientStop { position: 1.0; color: "#2b1822" }
        }
    }

    component Key: Rectangle {
        property alias label: keyText.text
        width: keyText.implicitWidth + 32
        height: 44
        radius: 7
        border.color: "#4a505d"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2a2e38" }
            GradientStop { position: 1.0; color: "#1b1e25" }
        }
        Text {
            id: keyText
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            color: presentation.text
            font.pixelSize: 20
            font.weight: Font.ExtraBold
        }
    }

    Timer {
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    // Cross-fade instead of the plain switch.
    function switchSlides(from, to, forward) {
        if (fade.running) {
            fade.complete();
        }
        fadeOut.target = from;
        fadeIn.target = to;
        to.opacity = 0;
        to.visible = true;
        fade.start();
        return true;
    }
    ParallelAnimation {
        id: fade
        NumberAnimation { id: fadeOut; property: "opacity"; to: 0; duration: 500 }
        NumberAnimation { id: fadeIn; property: "opacity"; to: 1; duration: 500 }
        onFinished: {
            fadeOut.target.visible = false;
            fadeOut.target.opacity = 1;
        }
    }

    // 1. Akane and Sora
    Full {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#111318" }
                GradientStop { position: 0.6; color: "#1d1620" }
                GradientStop { position: 1.0; color: "#3a1a2a" }
            }
        }
        Image {
            anchors.right: parent.right
            anchors.rightMargin: -14
            anchors.bottom: parent.bottom
            height: parent.height
            fillMode: Image.PreserveAspectFit
            source: "slides/akane-sora.png"
            mipmap: true
        }
        Column {
            x: 28
            width: parent.width * 0.4
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -parent.height * 0.12
            spacing: 12
            Text {
                width: parent.width
                color: presentation.text
                font.pixelSize: 26
                font.weight: Font.ExtraBold
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                text: "¡Hola! Somos <font color=\"#ff5a8c\">Akane</font> y <font color=\"#4fd2ff\">Sora</font>"
            }
            Text {
                width: parent.width
                color: "#e4e6ec"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: "Gracias por elegir Uzunyx. Mientras copiamos todo, te contamos un poco de lo que vas a encontrar."
            }
        }
    }

    // 2. Akane
    Full {
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: "slides/akane.jpeg"
            sourceSize.width: 1280
        }
        Shade {}
        Caption {
            title: "Akane"
            titleColor: presentation.akane
            body: "La edición carmesí, la que viene por defecto. Fondo, colores, terminal y pantalla de arranque a juego."
        }
    }

    // 3. Sora
    Full {
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: "slides/sora.jpeg"
            sourceSize.width: 1280
        }
        Shade {}
        Caption {
            title: "Sora"
            titleColor: presentation.sora
            body: "La edición cian. Se elige en la bienvenida al primer inicio, o cuando quieras desde Configuración › Uzunyx."
        }
    }

    // 4. The panel, with the control center's pill enlarged
    Full {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2b1822" }
                GradientStop { position: 0.7; color: "#111318" }
            }
        }
        Image {
            id: panel
            x: 14
            y: 56
            width: parent.width - 28
            fillMode: Image.PreserveAspectFit
            source: "slides/panel.png"
            mipmap: true
            readonly property real scale_: paintedWidth / sourceSize.width
            // Around the pill, whose place in panel.png crop-panel.py writes.
            PillPlace { id: place }
            Rectangle {
                id: ring
                x: place.x * panel.scale_ - 4
                y: place.y * panel.scale_ - 4
                width: place.width * panel.scale_ + 8
                height: place.height * panel.scale_ + 8
                radius: height / 2
                color: "transparent"
                border.color: presentation.accent
                border.width: 2
            }
        }
        Rectangle {
            x: ring.x + panel.x + ring.width / 2 - 1
            y: panel.y + ring.y + ring.height
            width: 2
            height: zoom.y - y
            gradient: Gradient {
                GradientStop { position: 0.0; color: presentation.accent }
                GradientStop { position: 1.0; color: "#33e62967" }
            }
        }
        Rectangle {
            id: zoom
            anchors.horizontalCenter: parent.horizontalCenter
            y: panel.y + panel.paintedHeight + 46
            width: pill.width + 12
            height: pill.height + 12
            radius: height / 2
            color: "transparent"
            border.color: presentation.accent
            border.width: 2
            Image {
                id: pill
                anchors.centerIn: parent
                // Taken at scale 2: no bigger than that, or it blurs.
                width: Math.min(presentation.width * 0.6, sourceSize.width)
                height: width * sourceSize.height / sourceSize.width
                source: "slides/pill.png"
                smooth: true
            }
        }
        Caption {
            title: "Todo en una píldora"
            body: "Wifi, Bluetooth, volumen, batería y Bloq Mayús/Num siempre a la vista. Un clic y se abre el centro de control."
        }
    }

    // 5. Control center
    Full {
        Glow {}
        Image {
            id: center
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width * 0.55, 340)
            fillMode: Image.PreserveAspectFit
            source: "slides/control-center.png"
            mipmap: true
        }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.right: center.left
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Text {
                width: parent.width
                color: presentation.text
                font.pixelSize: 24
                font.weight: Font.ExtraBold
                wrapMode: Text.WordWrap
                text: "Centro de control"
            }
            Text {
                width: parent.width
                color: "#e4e6ec"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: "Volumen y brillo, wifi y Bluetooth, modo enfoque, mosaico, no molestar, luz nocturna, portapapeles y dispositivos."
            }
        }
    }

    // 6. Tsunyx
    Full {
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Image.AlignTop
            source: "slides/tsunyx.png"
            mipmap: true
        }
        Shade {}
        Caption {
            title: "Tsunyx"
            body: "Todas tus apps con <b>Super</b>. Escribe para buscar, calcular (<b>2+2</b>), iniciar un temporizador (<b>5m té</b>) o ejecutar un comando."
        }
    }

    // 7. Shortcuts
    Full {
        Rectangle {
            anchors.fill: parent
            color: "#111318"
        }
        Column {
            anchors.centerIn: parent
            width: parent.width - 80
            spacing: 16
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Key { label: "Super" }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: presentation.text
                    font.pixelSize: 20
                    text: "+"
                }
                Key { label: "Espacio" }
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: presentation.text
                font.pixelSize: 22
                font.weight: Font.Bold
                text: "Todos los atajos, a mano"
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: presentation.dim
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: "Abre la ventana con todos los atajos del teclado y los gestos del panel táctil. Vuelve a pulsarlo para cerrarla."
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 26
                Repeater {
                    model: [["Super", "Aplicaciones"], ["Super+Tab", "Vista general"], ["Super+F", "Pantalla completa"]]
                    Column {
                        required property var modelData
                        Text {
                            color: presentation.text
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            text: modelData[0]
                        }
                        Text {
                            color: "#d9dce4"
                            font.pixelSize: 13
                            text: modelData[1]
                        }
                    }
                }
            }
        }
    }

    // Which slide it is: dots at the top-right, the current one long.
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 6
        z: 10
        Repeater {
            model: presentation.slides.length
            Rectangle {
                required property int index
                width: index === presentation.currentSlide ? 20 : 7
                height: 7
                radius: 3.5
                color: index === presentation.currentSlide ? presentation.accent : "#59ffffff"
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    function onActivate() {}
    function onLeave() {}
}
