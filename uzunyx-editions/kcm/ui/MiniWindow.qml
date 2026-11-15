import QtQuick

// A small window for the previews: dark surface, 1 px border (in the accent
// when it has the focus) and two lines of "text".
Rectangle {
    property bool focused: false
    property color accent: "white"

    radius: 3
    color: focused ? "#2a2d35" : "#20232b"
    border.width: 1
    border.color: focused ? accent : "#343944"

    Column {
        x: 5
        y: 6
        spacing: 3

        Rectangle {
            width: parent.parent.width * 0.55
            height: 3
            radius: 1.5
            color: "#4a4f5c"
        }
        Rectangle {
            width: parent.parent.width * 0.35
            height: 3
            radius: 1.5
            color: "#4a4f5c"
        }
    }
}
