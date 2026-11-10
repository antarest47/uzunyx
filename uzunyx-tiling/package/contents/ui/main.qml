/*
 * Tray icon for the tiling: a click rotates off, main and stack, and spiral, and the
 * right-click menu chooses them and the Uzunyx mode (normal or focus). The icon
 * draws the layout, in the edition's accent. uzunyx-tiling and
 * uzunyx-mode do the work and keep the state, also for changes from a terminal.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property string mode: "off"
    property string layoutMode: "normal"
    readonly property var modes: [
        { id: "off", label: i18n("No tiling") },
        { id: "stack", label: i18n("Main and stack") },
        { id: "spiral", label: i18n("Spiral") },
    ]

    toolTipMainText: Plasmoid.title
    toolTipSubText: modes.find(m => m.id === mode).label + " · " + (layoutMode === "focus" ? i18n("Focus") : i18n("Normal"))
    Plasmoid.icon: "view-grid"

    function choose(next) {
        mode = next;
        runner.connectSource("uzunyx-tiling " + next);
    }

    function chooseLayout(next) {
        layoutMode = next;
        runner.connectSource("uzunyx-mode " + next);
    }

    // A click rotates, wherever it arrives: at the icon or as the tray's
    // activation. Both can come from one click, so the second is ignored.
    property double lastRotation: 0
    function rotate() {
        const now = Date.now();
        if (now - lastRotation < 300) {
            return;
        }
        lastRotation = now;
        const index = modes.findIndex(m => m.id === mode);
        choose(modes[(index + 1) % modes.length].id);
    }

    // There is nothing to show: without this the tray opens an empty panel.
    activationTogglesExpanded: false
    Connections {
        target: Plasmoid
        function onActivated() {
            root.rotate();
        }
    }
    onExpandedChanged: isExpanded => {
        if (isExpanded) {
            root.rotate();
            Qt.callLater(() => root.expanded = false);
        }
    }

    PlasmaCore.ActionGroup { id: tilingGroup }
    PlasmaCore.ActionGroup { id: layoutGroup }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.modes[0].label
            checkable: true
            checked: root.mode === "off"
            actionGroup: tilingGroup
            onTriggered: root.choose("off")
        },
        PlasmaCore.Action {
            text: root.modes[1].label
            checkable: true
            checked: root.mode === "stack"
            actionGroup: tilingGroup
            onTriggered: root.choose("stack")
        },
        PlasmaCore.Action {
            text: root.modes[2].label
            checkable: true
            checked: root.mode === "spiral"
            actionGroup: tilingGroup
            onTriggered: root.choose("spiral")
        },
        PlasmaCore.Action {
            isSeparator: true
        },
        PlasmaCore.Action {
            text: i18n("Normal")
            checkable: true
            checked: root.layoutMode === "normal"
            actionGroup: layoutGroup
            onTriggered: root.chooseLayout("normal")
        },
        PlasmaCore.Action {
            text: i18n("Focus")
            checkable: true
            checked: root.layoutMode === "focus"
            actionGroup: layoutGroup
            onTriggered: root.chooseLayout("focus")
        }
    ]

    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => {
            const out = data.stdout.trim();
            if (modes.some(m => m.id === out)) {
                root.mode = out;
            } else if (out === "normal" || out === "focus") {
                root.layoutMode = out;
            }
            disconnectSource(source);
        }
    }

    // Also follows changes made from a terminal.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            runner.connectSource("uzunyx-tiling status");
            runner.connectSource("uzunyx-mode status");
        }
    }

    component LayoutIcon: Item {
        id: icon

        property string layout
        property color tint
        // Line width, on whole pixels so that it stays sharp at tray size.
        readonly property int line: Math.max(1, Math.round(width / 16))

        // Rectangles of the layout, as fractions of the icon: a main
        // window and a stack of three, a spiral that keeps halving, and
        // without tiling a free window, with its title bar and buttons.
        readonly property var cells: layout === "stack"
            ? [[0, 0, 0.47, 1], [0.56, 0, 0.44, 0.28], [0.56, 0.36, 0.44, 0.28], [0.56, 0.72, 0.44, 0.28]]
            : layout === "spiral"
                ? [[0, 0, 0.47, 1], [0.56, 0, 0.44, 0.44], [0.56, 0.56, 0.17, 0.44], [0.83, 0.56, 0.17, 0.44]]
                : [[0, 0.12, 0.56, 0.2], [0.64, 0.12, 0.14, 0.2], [0.86, 0.12, 0.14, 0.2], [0, 0.4, 1, 0.48]]

        Repeater {
            model: icon.cells
            Rectangle {
                required property var modelData
                x: Math.round(modelData[0] * icon.width)
                y: Math.round(modelData[1] * icon.height)
                width: Math.round((modelData[0] + modelData[2]) * icon.width) - x
                height: Math.round((modelData[1] + modelData[3]) * icon.height) - y
                radius: icon.line
                color: icon.tint
            }
        }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        hoverEnabled: true
        onClicked: root.rotate()

        LayoutIcon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height, Kirigami.Units.iconSizes.smallMedium)
            height: width
            layout: root.mode
            tint: Kirigami.Theme.focusColor
        }
    }

    fullRepresentation: Item {}
}
