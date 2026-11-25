import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Windows

PanelWindow {
    id: menu

    property bool open: false
    property string pending: ""
    property var rows: []
    property real cardX: 8
    property real cardWidth: 240
    property string namespace: "elrice-dropdown"
    property bool trackBar: false
    property bool atBottom: false
    property real bottomGap: 92
    readonly property real barHeight: 32

    signal triggered(var row)
    signal opened
    signal dismissed
    signal barHovered(real x)
    signal barClicked(real x)

    function toggle() {
        open = !open
    }

    function activate(row) {
        if (row.disabled)
            return
        if (row.verb && pending !== row.name) {
            pending = row.name
            return
        }
        open = false
        triggered(row)
        if (row.run)
            row.run()
    }

    visible: open || card.opacity > 0
    onVisibleChanged: if (!visible) dismissed()
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: menu.namespace
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        pending = ""
        if (open) {
            keys.forceActiveFocus()
            opened()
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: menu.open = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: menu.trackBar
        onPositionChanged: mouse => {
            if (menu.trackBar && mouse.y < menu.barHeight)
                menu.barHovered(mouse.x)
        }
        onClicked: mouse => {
            if (menu.trackBar && mouse.y < menu.barHeight)
                menu.barClicked(mouse.x)
            else
                menu.open = false
        }
    }

    GlassCard {
        id: card

        x: menu.cardX
        y: menu.atBottom ? menu.height - height - menu.bottomGap : 34
        width: menu.cardWidth
        height: list.implicitHeight + 12
        radius: 12
        shadow: true
        opacity: menu.open ? 1 : 0
        scale: menu.open ? 1 : 0.96
        transformOrigin: menu.atBottom ? Item.Bottom : Item.TopLeft

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Column {
            id: list
            x: 6
            y: 6
            width: parent.width - 12

            Repeater {
                model: menu.rows

                Item {
                    id: row

                    required property var modelData

                    width: list.width
                    height: modelData.sep ? 9 : 26

                    Rectangle {
                        visible: row.modelData.sep === true
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: parent.width - 16
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.18)
                    }

                    Rectangle {
                        visible: row.modelData.sep !== true
                        anchors.fill: parent
                        radius: 6
                        color: hover.hovered && !row.modelData.disabled ? "#0A84FF" : "transparent"
                        opacity: row.modelData.disabled ? 0.35 : 1

                        UiText {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            font.weight: Font.Normal
                            text: row.modelData.verb && menu.pending === row.modelData.name ? "Click again to " + row.modelData.verb : row.modelData.name ?? ""
                        }

                        UiText {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            font.weight: Font.Normal
                            color: Qt.rgba(1, 1, 1, hover.hovered && !row.modelData.disabled ? 0.85 : 0.5)
                            text: row.modelData.shortcut ?? ""
                        }
                    }

                    HoverHandler { id: hover }
                    TapHandler {
                        enabled: row.modelData.sep !== true && row.modelData.disabled !== true
                        onTapped: menu.activate(row.modelData)
                    }
                }
            }
        }
    }
}
