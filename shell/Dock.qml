import QtQuick
import Quickshell
import Quickshell.Windows
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: dock

    property var config: ({dock: []})
    property var pinned: config.dock ?? []
    property bool shown: hover.hovered
    property real reveal: 1

    function matches(entry, toplevel) {
        const re = new RegExp(entry.match, "i")
        return re.test(toplevel.appId) || re.test(toplevel.title)
    }

    readonly property var appIcons: [
        [/brave.*beta/, "brave-beta"], [/brave.*(nightly|dev)/, "brave-nightly"], [/brave/, "brave"],
        [/helium/, "helium"], [/chromium/, "chromium"], [/chrome/, "chrome"], [/edge/, "msedge"],
        [/firefox/, "firefox"], [/^(code|vscode|visual ?studio ?code)/, "code"], [/steam/, "steam"],
        [/obsidian/, "obsidian"], [/telegram/, "telegram"], [/notepad|texteditor/, "notepad"],
        [/systemsettings|immersivecontrolpanel/, "settings"], [/taskmgr|taskmanager/, "taskmgr"],
        [/calc/, "calculator"], [/prism/, "prismlauncher"], [/minecraft/, "minecraft"],
        [/^obs/, "obs"], [/^vlc/, "vlc"], [/gimp/, "gimp"], [/discord/, "discord"],
        [/spotify/, "spotify"], [/explorer/, "explorer"], [/wezterm/, "wezterm"]
    ]

    function iconFor(appId) {
        const id = String(appId).toLowerCase().replace(/^.*[!\\/]/, "").replace(/\.exe$/, "")
        const hit = appIcons.find(e => e[0].test(id) || e[0].test(String(appId).toLowerCase()))
        return hit ? Qt.resolvedUrl("icons/dock/apps/" + hit[1] + ".svg") : "image://icon/" + appId
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
                    onScrolled: direction => dock.cycle(windows, direction)
                }
            }

            Repeater {
                model: ToplevelManager.toplevels

                DockItem {
                    required property var modelData
                    property bool entered: false
                    visible: !dock.isPinned(modelData)
                    width: visible ? 64 : 0
                    opacity: entered ? 1 : 0
                    scale: entered ? 1 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
                    Component.onCompleted: entered = true
                    iconSource: dock.iconFor(modelData.appId)
                    fallbackSource: Qt.resolvedUrl("icons/dock/application-x-executable.svg")
                    label: modelData.title
                    running: true
                    focused: modelData.activated
                    onClicked: dock.toggle(modelData)
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

            DockItem {
                iconSource: Qt.resolvedUrl("icons/dock/user-trash.svg")
                label: "Recycle Bin"
                onClicked: Quickshell.execDetached(["explorer.exe", "shell:RecycleBinFolder"])
            }

            DockItem {
                iconSource: Qt.resolvedUrl("icons/dock/view-app-grid.svg")
                label: "Apps"
                onClicked: Hyprland.dispatch("global quickshell:spotlightToggle")
            }
        }
    }
}
