import QtQuick

Rectangle {
    id: item

    default property alias content: row.data
    property color tint: "#ffffff"
    signal clicked

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 24
    radius: 6
    color: hover.hovered ? Qt.alpha(tint, 0.16) : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: item.clicked() }
}
