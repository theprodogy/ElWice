import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Windows

PanelWindow {
    id: switcher

    property var groups: []
    property int current: 0
    property var recent: []

    signal dismissed

    readonly property var ownIds: /quickshell|^qsw?(\.exe)?$/i

    AppIcons { id: icons }

    function collect() {
        const map = {}
        const list = []
        for (const t of ToplevelManager.toplevels.values) {
            if (!t.appId || !t.title || ownIds.test(t.appId)) continue
            if (!map[t.appId]) {
                map[t.appId] = {appId: t.appId, windows: []}
                list.push(map[t.appId])
            }
            map[t.appId].windows.push(t)
        }
        const rank = g => {
            const at = recent.indexOf(g.appId)
            return at < 0 ? recent.length : at
        }
        return list.sort((a, b) => rank(a) - rank(b))
    }

    function nameOf(appId) {
        const id = String(appId).replace(/^.*[!\/]/, "").replace(/\.exe$/i, "")
        return id.charAt(0).toUpperCase() + id.slice(1)
    }

    function open(direction) {
        const name = Hyprland.focusedMonitor?.name
        screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
        groups = collect()
        if (groups.length === 0) return
        current = groups.length > 1 ? (direction > 0 ? 1 : groups.length - 1) : 0
        visible = true
        keys.forceActiveFocus()
    }

    function step(direction) {
        if (!visible) open(direction)
        else current = (current + direction + groups.length) % groups.length
    }

    function commit() {
        if (!visible) return
        visible = false
        const group = groups[current]
        if (!group) return
        const target = group.windows.find(t => t.activated) ?? group.windows[0]
        target.minimized = false
        target.activate()
    }

    visible: false
    onVisibleChanged: if (!visible) dismissed()
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "elrice-alttab"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab) switcher.step(1)
            else if (event.key === Qt.Key_Backtab) switcher.step(-1)
            else if (event.key === Qt.Key_Escape) switcher.visible = false
            else if (event.key === Qt.Key_Left) switcher.step(-1)
            else if (event.key === Qt.Key_Right) switcher.step(1)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) switcher.commit()
            else return
            event.accepted = true
        }

        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt && !event.isAutoRepeat) switcher.commit()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: switcher.visible = false
    }

    GlassCard {
        anchors.centerIn: parent
        width: row.width + 40
        height: 188
        radius: 28
        tint: Qt.rgba(1, 1, 1, 0.2)

        MouseArea { anchors.fill: parent }

        Row {
            id: row
            x: 20
            y: 18
            spacing: 6

            Repeater {
                model: switcher.groups

                Item {
                    id: tile
                    required property var modelData
                    required property int index

                    width: 112
                    height: 112

                    Rectangle {
                        anchors.fill: parent
                        radius: 24
                        color: Qt.rgba(1, 1, 1, tile.index === switcher.current ? 0.22 : hover.hovered ? 0.1 : 0)
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 84
                        height: 84
                        source: icons.iconFor(tile.modelData.appId)
                        sourceSize: Qt.size(168, 168)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        onStatusChanged: if (status === Image.Error) source = Qt.resolvedUrl("icons/dock/application-x-executable.svg")
                    }

                    HoverHandler { id: hover }

                    TapHandler {
                        onTapped: {
                            switcher.current = tile.index
                            switcher.commit()
                        }
                    }
                }
            }
        }

        UiText {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 142
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: 15
            text: switcher.groups[switcher.current] ? switcher.nameOf(switcher.groups[switcher.current].appId) : ""
        }
    }
}
