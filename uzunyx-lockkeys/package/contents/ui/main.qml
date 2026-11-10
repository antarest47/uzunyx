/*
 * Lock keys: a pill in the panel with an "A" half for Caps Lock and a "1"
 * half for Num Lock, an alarm for keyboards without lock key lights: quiet
 * in the edition's colour in the normal position, pulsing red otherwise. The
 * key states come from the same module as Plasma's own keyboard indicator.
 *
 * Its option (Caps Lock and Num Lock, or Caps Lock only) also decides
 * whether Num Lock is turned on at login: KWin reads [Keyboard] NumLock
 * from kcminputrc when the session starts (0 on, 1 off, 2 leave as is).
 * The system default, on, comes from /etc/xdg/kcminputrc; changing the
 * option writes the user's own value.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

PlasmoidItem {
    id: root

    readonly property bool showNumLock: Plasmoid.configuration.showNumLock

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    toolTipMainText: Plasmoid.title
    toolTipSubText: {
        const lines = [capsLock.locked ? i18n("Caps Lock on") : i18n("Caps Lock off")];
        if (showNumLock) {
            lines.push(numLock.locked ? i18n("Num Lock on") : i18n("Num Lock off"));
        }
        return lines.join("\n");
    }

    KeyboardIndicator.KeyState {
        id: capsLock
        key: Qt.Key_CapsLock
    }
    KeyboardIndicator.KeyState {
        id: numLock
        key: Qt.Key_NumLock
    }

    // Writes the user's NumLock only when the option really changes:
    // appliedNumLock remembers the value last applied, so loading the
    // configuration (which also changes showNumLock) writes nothing, and a
    // choice made later in System Settings isn't overwritten at every login.
    // On first load it just records the option: the system default applies.
    function applyNumLockOption() {
        const value = String(showNumLock);
        if (Plasmoid.configuration.appliedNumLock === value) {
            return;
        }
        if (Plasmoid.configuration.appliedNumLock !== "") {
            executable.connectSource("kwriteconfig6 --file kcminputrc --group Keyboard --key NumLock "
                + (showNumLock ? "0" : "2"));
        }
        Plasmoid.configuration.appliedNumLock = value;
    }

    onShowNumLockChanged: applyNumLockOption()
    Component.onCompleted: applyNumLockOption()

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    // The pill, in the style of the window buttons (uzunyx-buttons): a glossy
    // black core with a rim, a sparkle and a highlight. It works as an alarm,
    // for keyboards without lock key lights: in the normal position (Caps
    // Lock off, Num Lock on) a half is quiet, in the edition's accent colour
    // (it follows the colour scheme); in the other position it fills with
    // intense red and pulses, with a halo going out of the pill, hard to miss.
    // Drawn as SVG here to use the scheme's colour. Sizes in pill units: 26
    // high, 34 each half (40 the single "A" pill).
    fullRepresentation: Item {
        id: pillArea
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        readonly property bool capsAlert: capsLock.locked
        readonly property bool numAlert: root.showNumLock && !numLock.locked
        readonly property int pillWidth: root.showNumLock ? 68 : 40
        readonly property int margin: 6
        // A medium icon's height, or less in a thin panel.
        readonly property real unit: Math.min(Kirigami.Units.iconSizes.medium,
            vertical ? width / pillWidth * 26 : height) * 0.8 / 26

        Layout.preferredWidth: vertical ? -1 : Math.round(pillWidth * unit)
        Layout.preferredHeight: vertical ? Math.round(26 * unit) : -1

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        readonly property color accent: Kirigami.Theme.focusColor

        // Half outlines. The side nearest the middle is straight.
        function outline(side) {
            if (side === "whole") {
                return "M13 .5H27A12.5 12.5 0 0 1 27 25.5H13A12.5 12.5 0 0 1 13 .5Z";
            }
            return side === "left" ? "M13 .5H34V25.5H13A12.5 12.5 0 0 1 13 .5Z"
                                   : "M34 .5H55A12.5 12.5 0 0 1 55 25.5H34Z";
        }

        function half(id, side, letter, alert) {
            const path = outline(side);
            const cx = side === "whole" ? 20 : side === "left" ? 18 : 50;
            const rim = alert ? ["#ffffff", "#ff1a0a"]
                              : [Qt.lighter(accent, 1.5), Qt.darker(accent, 1.7)];
            const core = alert ? ["#ff4a2a", "#c80000"] : ["#22262b", "#030405"];
            const symbol = alert ? "#ffffff" : Qt.lighter(accent, 1.2);
            const text = `x="${cx}" y="18" text-anchor="middle" font-family="sans-serif" font-size="14" font-weight="700"`;
            return `<defs>
                <linearGradient id="${id}r" x1="0" y1="0" x2="0" y2="26" gradientUnits="userSpaceOnUse">
                    <stop offset="0" stop-color="${rim[0]}"/><stop offset="1" stop-color="${rim[1]}"/></linearGradient>
                <radialGradient id="${id}c" cx="${cx}" cy="9" r="22" gradientUnits="userSpaceOnUse">
                    <stop offset="0" stop-color="${core[0]}"/><stop offset="1" stop-color="${core[1]}"/></radialGradient>
                </defs>
                <path d="${path}" fill="url(#${id}c)"/>`
                + (alert ? "" : `<text ${text} fill="none" stroke="${accent}" stroke-width="3" opacity="0.3">${letter}</text>`)
                + `<text ${text} fill="${symbol}">${letter}</text>
                <ellipse cx="${cx + 7}" cy="6" rx="4.4" ry="1.3" transform="rotate(14 ${cx + 7} 6)" fill="#fff" opacity="${alert ? 0.85 : 0.6}"/>
                <circle cx="${cx + 11}" cy="9" r="0.7" fill="#fff" opacity="0.55"/>
                <path d="M${cx - 9} 4.4l.4 1.5 1.5.4-1.5.4-.4 1.5-.4-1.5-1.5-.4 1.5-.4z" fill="#fff" opacity="${alert ? 1 : 0.85}"/>
                <path d="${path}" fill="none" stroke="url(#${id}r)" stroke-width="1.1"/>`;
        }

        // Halo: wide translucent strokes (no SVG filters, as in the buttons).
        function halo(side) {
            return [[11, 0.10], [7.5, 0.18], [4, 0.32]].map(s =>
                `<path d="${outline(side)}" fill="none" stroke="#ff1a0a" stroke-width="${s[0]}" stroke-linejoin="round" opacity="${s[1]}"/>`).join("");
        }

        function document(body) {
            const m = margin;
            const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${pillWidth + 2 * m}" height="${26 + 2 * m}" viewBox="${-m} ${-m} ${pillWidth + 2 * m} ${26 + 2 * m}">${body}</svg>`;
            return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
        }

        readonly property var halves: root.showNumLock
            ? [{ side: "left", letter: "A", alert: capsAlert }, { side: "right", letter: "1", alert: numAlert }]
            : [{ side: "whole", letter: "A", alert: capsAlert }]

        // What stays still: quiet halves, and a dark red under the alarms so
        // they never look normal at the low point of the pulse.
        readonly property string quietLayer: document(halves.map((h, i) => h.alert
            ? `<path d="${outline(h.side)}" fill="#5a0000" stroke="#ff1a0a" stroke-width="1.1"/>`
            : half("q" + i, h.side, h.letter, false)).join(""))
        // What pulses.
        readonly property string alertLayer: document(
            halves.filter(h => h.alert).map(h => halo(h.side)).join("")
            + halves.map((h, i) => h.alert ? half("a" + i, h.side, h.letter, true) : "").join(""))

        component PillLayer: Image {
            anchors.centerIn: parent
            width: Math.round((pillArea.pillWidth + 2 * pillArea.margin) * pillArea.unit)
            height: Math.round((26 + 2 * pillArea.margin) * pillArea.unit)
            sourceSize: Qt.size(width * 2, height * 2)
            cache: false
        }

        PillLayer {
            source: pillArea.quietLayer
        }
        PillLayer {
            id: alertImage
            visible: pillArea.capsAlert || pillArea.numAlert
            source: pillArea.alertLayer
            SequentialAnimation on opacity {
                running: alertImage.visible
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.25; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.25; to: 1; duration: 450; easing.type: Easing.InOutSine }
            }
        }
    }
}
