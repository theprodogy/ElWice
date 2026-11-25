import QtQuick
import Quickshell
import Quickshell.Windows
import Quickshell.Wayland

PanelWindow {
    id: dock

    property var config: ({dock: []})
    property var pinned: config.dock ?? []
    property bool menuOpen: menuLazy.active
    property bool shown: hover.hovered || menuOpen || tray.open
    property real reveal: 1

    signal pinsChanged(var list)

    AppIcons { id: icons }

    function matches(entry, toplevel) {
        const re = new RegExp(entry.match, "i")
        return re.test(toplevel.appId) || re.test(toplevel.title)
    }

    function windowsFor(entry) {
        return ToplevelManager.toplevels.values.filter(t => matches(entry, t))
    }

    function isPinned(toplevel) {
        return pinned.some(entry => matches(entry, toplevel))
    }

    function hasExtras() {
        return ToplevelManager.toplevels.values.some(t => !isPinned(t))
    }

    function showMenu(item, name, windows, entry, appId) {
        menuLazy.active = true
        const menu = menuLazy.item
        menu.appName = name
        menu.windows = windows
        menu.entry = entry
        menu.appId = appId
        menu.centerX = (screen.width - width) / 2 + item.mapToItem(null, item.width / 2, 0).x
        menu.open = true
    }

    function toggle(toplevel) {
        if (toplevel.activated && !toplevel.minimized) {
            toplevel.minimized = true
        } else {
            toplevel.minimized = false
            toplevel.activate()
        }
    }

    function cycle(list, direction) {
        if (list.length === 0) return
        const current = list.findIndex(t => t.activated)
        const target = list[(current + direction + list.length) % list.length]
        target.minimized = false
        target.activate()
    }

    onShownChanged: {
        if (shown) {
            hideTimer.stop()
            reveal = 1
        } else {
            hideTimer.restart()
        }
    }

    Component.onCompleted: hideTimer.start()

    Behavior on reveal { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Timer {
        id: hideTimer
        interval: 400
        onTriggered: dock.reveal = 0
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "elrice-dock"

    anchors.bottom: true

    implicitWidth: row.width + 72
    implicitHeight: reveal > 0 ? 108 : 4
    exclusiveZone: 0
    color: "transparent"

    HoverHandler { id: hover }

    LazyLoader {
        id: menuLazy

        DockMenu {
            screen: dock.screen
            currentPins: dock.pinned
            onPinsEdited: list => dock.pinsChanged(list)
            onDismissed: Qt.callLater(() => menuLazy.active = false)
        }
    }

    GlassCard {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8 - (1 - dock.reveal) * (height + 40)
        height: 76
        width: row.width + 24
        radius: 24
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                model: dock.pinned

                DockItem {
                    id: favorite
                    required property var modelData
                    readonly property var windows: dock.windowsFor(modelData)
                    iconSource: Qt.resolvedUrl(modelData.icon)
                    label: modelData.name
                    running: windows.length > 0
                    focused: windows.some(t => t.activated)
                    onClicked: {
                        if (windows.length > 0) dock.toggle(windows.find(t => t.activated) ?? windows[0])
                        else Quickshell.execDetached(modelData.command)
                    }
                    onRightClicked: dock.showMenu(favorite, modelData.name, windows, modelData, windows.length > 0 ? windows[0].appId : "")
                    onScrolled: direction => dock.cycle(windows, direction)
                }
            }

            Repeater {
                model: ToplevelManager.toplevels

                DockItem {
                    id: extra
                    required property var modelData
                    property bool entered: false
                    visible: !dock.isPinned(modelData)
                    width: visible ? 64 : 0
                    opacity: entered ? 1 : 0
                    scale: entered ? 1 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
                    Component.onCompleted: entered = true
                    iconSource: icons.iconFor(modelData.appId)
                    fallbackSource: Qt.resolvedUrl("icons/dock/application-x-executable.svg")
                    label: modelData.title
                    running: true
                    focused: modelData.activated
                    onClicked: dock.toggle(modelData)
                    onRightClicked: dock.showMenu(extra, modelData.title, [modelData], null, modelData.appId)
                }
            }

            Item {
                width: 13
                height: 64

                Rectangle {
                    width: 1
                    height: 40
                    anchors.centerIn: parent
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
            }

            TrayButton {
                id: tray
                screen: dock.screen
            }

            DockItem {
                iconSource: Qt.resolvedUrl("icons/dock/user-trash.svg")
                label: "Recycle Bin"
                onClicked: Quickshell.execDetached(["explorer.exe", "shell:RecycleBinFolder"])
            }
        }
    }
}
