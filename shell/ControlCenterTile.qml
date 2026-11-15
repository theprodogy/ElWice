import QtQuick

Item {
    id: tile

    property url icon
    property string title
    property string subtitle
    property bool active
    signal clicked

    implicitHeight: 44

    Rectangle {
        id: disc
        width: 36
        height: 36
        radius: 18
        anchors.verticalCenter: parent.verticalCenter
        color: tile.active ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.2)
        Behavior on color { ColorAnimation { duration: 100 } }

        SymbolIcon {
            anchors.centerIn: parent
            source: tile.icon
            size: 18
        }
    }

    Column {
        anchors.left: disc.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        BarText {
            width: parent.width
            text: tile.title
            elide: Text.ElideRight
            color: "#ffffff"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        BarText {
            width: parent.width
            text: tile.subtitle
            elide: Text.ElideRight
            color: Qt.rgba(1, 1, 1, 0.65)
            font.pixelSize: 12
        }
    }

    TapHandler { onTapped: tile.clicked() }
}
