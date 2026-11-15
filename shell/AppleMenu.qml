import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Windows

PanelWindow {
    id: menu

    property bool open: false
    property string pending: ""

    readonly property var rows: [
        {name: "About This Mac", run: () => Quickshell.execDetached(["explorer.exe", "ms-settings:about"])},
        {sep: true},
        {name: "System Settings…", run: () => Quickshell.execDetached(["explorer.exe", "ms-settings:"])},
        {sep: true},
        {name: "Force Quit…", run: () => Quickshell.execDetached(["taskmgr.exe"])},
        {sep: true},
        {name: "Sleep", run: () => Session.suspend()},
        {name: "Restart…", verb: "restart", run: () => Session.reboot()},
        {name: "Shut Down…", verb: "shut down", run: () => Session.shutdown()},
        {sep: true},
        {name: "Lock Screen", run: () => Session.lock()},
        {name: "Log Out", verb: "log out", run: () => Quickshell.execDetached(["shutdown.exe", "/l"])}
    ]

    function toggle() {
        open = !open
    }

    function activate(row) {
        if (row.verb && pending !== row.name) {
            pending = row.name
            return
        }
        open = false
        row.run()
    }

    visible: open || card.opacity > 0
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "elrice-applemenu"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        pending = ""
        if (open)
            keys.forceActiveFocus()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: menu.open = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menu.open = false
    }

    GlassCard {
        id: card

        x: 8
        y: 34
        width: 240
        height: list.implicitHeight + 12
        radius: 12
        shadow: true
        opacity: menu.open ? 1 : 0
        scale: menu.open ? 1 : 0.96
        transformOrigin: Item.TopLeft

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
                        color: hover.hovered ? "#0A84FF" : "transparent"

                        UiText {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            font.weight: Font.Normal
                            text: row.modelData.verb && menu.pending === row.modelData.name ? "Click again to " + row.modelData.verb : row.modelData.name ?? ""
                        }
                    }

                    HoverHandler { id: hover }
                    TapHandler {
                        enabled: row.modelData.sep !== true
                        onTapped: menu.activate(row.modelData)
                    }
                }
            }
        }
    }
}
