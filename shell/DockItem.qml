import QtQuick

Item {
    id: item

    property string iconSource: ""
    property string fallbackSource: ""
    property string label: ""
    property bool running: false
    property bool focused: false

    signal clicked()
    signal scrolled(int direction)

    width: 64
    height: 64

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(1, 1, 1, area.pressed || item.focused ? 0.14 : area.containsMouse ? 0.08 : 0)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Image {
        id: img
        anchors.centerIn: parent
        anchors.verticalCenterOffset: area.containsMouse && !area.pressed ? -2 : 0
        width: 56
        height: 56
        source: item.iconSource
        sourceSize: Qt.size(112, 112)
        fillMode: Image.PreserveAspectFit
        smooth: true
        scale: area.pressed ? 0.95 : 1
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        onStatusChanged: if (status === Image.Error && item.fallbackSource !== "") source = item.fallbackSource
    }

    Rectangle {
        width: 5
        height: 5
        radius: 3
        color: "white"
        opacity: item.running ? (item.focused ? 1 : 0.6) : 0
        scale: item.running ? 1 : 0.5
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
        onWheel: wheel => item.scrolled(wheel.angleDelta.y > 0 ? -1 : 1)
    }
}
