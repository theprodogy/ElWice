import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: popup

    property real anchorX: 0
    property bool shown: false
    readonly property int cell: 40
    readonly property int count: SystemTray.items.values.length
    readonly property int cols: Math.max(1, Math.min(8, count))
    readonly property int rows: Math.max(1, Math.ceil(count / 8))

    signal dismissed

    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "elrice-tray"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        shown = true
        keys.forceActiveFocus()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: popup.dismissed()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.dismissed()
    }

    GlassCard {
        id: card

        width: popup.cols * popup.cell + 16
        height: popup.rows * popup.cell + 16
        x: Math.max(8, Math.min(popup.width - width - 8, popup.anchorX - width / 2))
        y: popup.height - 100 - height + (popup.shown ? 0 : 8)
        radius: 20
        shadow: true
        opacity: popup.shown ? 1 : 0
        scale: popup.shown ? 1 : 0.96
        transformOrigin: Item.Bottom

        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }

        MouseArea { anchors.fill: parent }

        Grid {
            x: 8
            y: 8
            columns: 8

            Repeater {
                model: SystemTray.items

                Item {
                    id: cellItem

                    required property var modelData

                    width: popup.cell
                    height: popup.cell

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: Qt.rgba(1, 1, 1, ma.pressed ? 0.14 : ma.containsMouse ? 0.08 : 0)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: cellItem.modelData.icon
                        sourceSize: Qt.size(44, 44)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        scale: ma.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (cellItem.modelData.hasMenu) {
                                    const p = cellItem.mapToItem(null, mouse.x, mouse.y)
                                    cellItem.modelData.display(popup, p.x, p.y)
                                } else {
                                    cellItem.modelData.secondaryActivate()
                                }
                            } else {
                                cellItem.modelData.activate()
                            }
                        }
                        onWheel: wheel => cellItem.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }

    }
}
