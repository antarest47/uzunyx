/*
 * The tiling layout as a drawing, the same as uzunyx-tiling's tray icon.
 */
import QtQuick

Item {
    id: icon

    property string layout
    property color tint

    readonly property int line: Math.max(1, Math.round(width / 16))
    // Rectangles of the layout, as fractions of the icon: a main window and
    // a stack of three, a spiral that keeps halving, and without tiling a free
    // window, with its title bar and buttons.
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
