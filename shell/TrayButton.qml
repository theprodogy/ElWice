import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: btn

    property var screen
    readonly property bool open: lazy.active

    visible: SystemTray.items.values.length > 0
    width: visible ? 64 : 0
    height: 64

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(1, 1, 1, area.pressed || btn.open ? 0.14 : area.containsMouse ? 0.08 : 0)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    SymbolIcon {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: area.containsMouse && !area.pressed ? -2 : 0
        size: 28
        source: Qt.resolvedUrl("icons/go-up-symbolic.svg")
        rotation: btn.open ? 180 : 0
        scale: area.pressed ? 0.95 : 1
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: lazy.active = !lazy.active
    }

    LazyLoader {
        id: lazy

        TrayPopup {
            screen: btn.screen
            anchorX: btn.mapToItem(null, btn.width / 2, 0).x
            onDismissed: Qt.callLater(() => lazy.active = false)
        }
    }
}
