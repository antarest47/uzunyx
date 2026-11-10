import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kwin.decoration

DecorationButton {
    id: button

    property real size
    // Minimize, maximize/restore and close use the coloured images in
    // ../buttons (same image for maximize and restore); the rest use icons.
    readonly property string imageName: {
        switch (buttonType) {
        case DecorationOptions.DecorationButtonClose:
            return "close";
        case DecorationOptions.DecorationButtonMaximizeRestore:
            return "maximize";
        case DecorationOptions.DecorationButtonMinimize:
            return "minimize";
        }
        return "";
    }
    readonly property string imageState: !decoration.client.active ? "backdrop"
        : pressed ? "active" : hovered ? "hover" : "normal"

    width: size
    height: size

    // Ring around the ball on hover, like the one Electron (Claude Desktop)
    // draws around its buttons: pink for close, warm white for the rest.
    Rectangle {
        visible: button.imageName !== "" && button.hovered
        anchors.centerIn: parent
        width: 24
        height: 24
        radius: width / 2
        color: button.imageName === "close" ? "#fe919d" : "#c2b6b0"
    }

    Image {
        visible: button.imageName !== ""
        anchors.centerIn: parent
        width: 20
        height: 20
        sourceSize: Qt.size(width * 2, height * 2)
        source: visible ? Qt.resolvedUrl("../buttons/" + button.imageName + "-" + button.imageState + ".svg") : ""
    }

    Rectangle {
        visible: button.imageName === ""
        anchors.fill: parent
        radius: width / 2
        color: options.fontColor
        opacity: button.pressed ? 0.45 : (button.hovered ? 0.15 : 0)
    }

    Kirigami.Icon {
        visible: button.imageName === ""
        anchors.centerIn: parent
        width: 16
        height: 16
        isMask: true
        color: options.fontColor
        opacity: button.enabled ? (decoration.client.active ? 1 : 0.6) : 0.3
        source: {
            switch (button.buttonType) {
            case DecorationOptions.DecorationButtonKeepAbove:
                return "window-keep-above-symbolic";
            case DecorationOptions.DecorationButtonKeepBelow:
                return "window-keep-below-symbolic";
            case DecorationOptions.DecorationButtonQuickHelp:
                return "help-contextual-symbolic";
            case DecorationOptions.DecorationButtonShade:
                return "window-shade-symbolic";
            case DecorationOptions.DecorationButtonOnAllDesktops:
                return button.toggled ? "window-unpin-symbolic" : "window-pin-symbolic";
            case DecorationOptions.DecorationButtonApplicationMenu:
                return "application-menu-symbolic";
            }
            return "";
        }
    }
}
