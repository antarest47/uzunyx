/*
 * Uzunyx window decoration.
 *
 * Unlike Breeze, it keeps its borders and rounded corners when the window is
 * maximized: the client area is a plain rectangle inside the borders, and
 * the corners are rounded in the decoration itself, transparent outside.
 */
import QtQuick
import QtQuick.Effects
import org.kde.kwin.decoration

Decoration {
    id: root

    // Same look as the Plasma panel corners.
    readonly property int cornerRadius: 8
    // Must be >= cornerRadius * (1 - 1/sqrt(2)) so the client area's
    // corners stay inside the rounded outline.
    readonly property int borderWidth: 4
    readonly property int titleHeight: 30
    readonly property int buttonSize: 24
    // Room around the frame for the shadow. Aurorae turns whatever is drawn
    // in the padding into a native KWin shadow (not part of the window).
    // Maximized windows get no padding, hence no shadow.
    readonly property int shadowSize: 28
    readonly property int shadowOffset: 6
    readonly property bool showShadow: !decoration.client.maximized

    alpha: true

    DecorationOptions {
        id: options
        deco: decoration
    }
    ColorHelper {
        id: colorHelper
    }

    // The window itself: everything but the shadow padding.
    Item {
        id: frameArea
        anchors {
            fill: parent
            leftMargin: root.showShadow ? root.padding.left : 0
            rightMargin: root.showShadow ? root.padding.right : 0
            topMargin: root.showShadow ? root.padding.top : 0
            bottomMargin: root.showShadow ? root.padding.bottom : 0
        }
    }

    RectangularShadow {
        anchors.fill: frameArea
        visible: root.showShadow
        radius: root.cornerRadius
        offset.y: root.shadowOffset / 2
        blur: root.shadowSize - root.shadowOffset
        color: Qt.rgba(0, 0, 0, decoration.client.active ? 0.5 : 0.3)
    }

    Rectangle {
        id: frame
        anchors.fill: frameArea
        radius: root.cornerRadius
        color: options.titleBarColor
        border.width: 1
        border.color: colorHelper.multiplyAlpha(options.fontColor, decoration.client.active ? 0.25 : 0.12)
    }

    Item {
        id: titleRow
        anchors {
            left: frameArea.left
            right: frameArea.right
            top: frameArea.top
            leftMargin: root.borderWidth + 4
            rightMargin: root.borderWidth + 4
        }
        height: root.titleHeight

        ButtonGroup {
            id: leftButtonGroup
            spacing: 4
            explicitSpacer: root.buttonSize
            height: root.buttonSize
            menuButton: menuButtonComponent
            appMenuButton: appMenuButtonComponent
            minimizeButton: minimizeButtonComponent
            maximizeButton: maximizeButtonComponent
            keepBelowButton: keepBelowButtonComponent
            keepAboveButton: keepAboveButtonComponent
            helpButton: helpButtonComponent
            shadeButton: shadeButtonComponent
            allDesktopsButton: allDesktopsButtonComponent
            closeButton: closeButtonComponent
            buttons: options.titleButtonsLeft
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }
        Text {
            id: caption
            anchors {
                left: leftButtonGroup.right
                right: rightButtonGroup.left
                leftMargin: 8
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: decoration.client.caption
            color: options.fontColor
            opacity: decoration.client.active ? 1 : 0.6
            font: options.titleFont
            elide: Text.ElideMiddle
        }
        ButtonGroup {
            id: rightButtonGroup
            spacing: 4
            explicitSpacer: root.buttonSize
            height: root.buttonSize
            menuButton: menuButtonComponent
            appMenuButton: appMenuButtonComponent
            minimizeButton: minimizeButtonComponent
            maximizeButton: maximizeButtonComponent
            keepBelowButton: keepBelowButtonComponent
            keepAboveButton: keepAboveButtonComponent
            helpButton: helpButtonComponent
            shadeButton: shadeButtonComponent
            allDesktopsButton: allDesktopsButtonComponent
            closeButton: closeButtonComponent
            buttons: options.titleButtonsRight
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
        }
    }

    // Where KWin lets you drag the window (anything else in the top border
    // resizes it). installTitleItem() maps the item to scene coordinates,
    // which include the shadow padding, but KWin expects them relative to
    // the window frame, so this item sits at the title row's position minus
    // the padding. It starts below the top border, which stays for resizing.
    Item {
        id: titleBarArea
        x: titleRow.x - frameArea.x
        y: titleRow.y - frameArea.y + root.borderWidth
        width: titleRow.width
        height: titleRow.height - root.borderWidth
        Component.onCompleted: decoration.installTitleItem(titleBarArea)
    }

    Component {
        id: closeButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonClose; size: root.buttonSize }
    }
    Component {
        id: maximizeButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonMaximizeRestore; size: root.buttonSize }
    }
    Component {
        id: minimizeButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonMinimize; size: root.buttonSize }
    }
    Component {
        id: keepAboveButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonKeepAbove; size: root.buttonSize }
    }
    Component {
        id: keepBelowButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonKeepBelow; size: root.buttonSize }
    }
    Component {
        id: helpButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonQuickHelp; size: root.buttonSize }
    }
    Component {
        id: shadeButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonShade; size: root.buttonSize }
    }
    Component {
        id: allDesktopsButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonOnAllDesktops; size: root.buttonSize }
    }
    Component {
        id: appMenuButtonComponent
        UzunyxButton { buttonType: DecorationOptions.DecorationButtonApplicationMenu; size: root.buttonSize }
    }
    Component {
        id: menuButtonComponent
        MenuButton {
            width: root.buttonSize
            height: root.buttonSize
        }
    }

    Component.onCompleted: {
        borders.setBorders(root.borderWidth);
        borders.setTitle(root.titleHeight);
        maximizedBorders.setBorders(root.borderWidth);
        maximizedBorders.setTitle(root.titleHeight);
        // Easier resizing: grab area a bit outside the thin borders.
        extendedBorders.setBorders(4);
        padding.left = root.shadowSize;
        padding.right = root.shadowSize;
        padding.top = root.shadowSize - root.shadowOffset;
        padding.bottom = root.shadowSize + root.shadowOffset;
    }
}
