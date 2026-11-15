import QtQuick
import QtQuick.Effects

Item {
    property url source
    property color color: "#ffffff"
    property real size: 16

    width: size
    height: size

    Image {
        id: image
        anchors.fill: parent
        source: parent.source
        sourceSize: Qt.size(parent.size * 2, parent.size * 2)
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        colorization: 1
        colorizationColor: parent.color
    }
}
