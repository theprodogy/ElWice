import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Windows

Scope {
    id: host

    property var recent: []
    property int altUp: 0

    signal opened

    function unload() {
        watcher.running = false
        Qt.callLater(() => lazy.active = false)
    }

    function step(direction) {
        const fresh = !lazy.item || !lazy.item.visible
        if (fresh) {
            altUp = 0
            lazy.active = true
        }
        lazy.item.step(direction)
        if (!lazy.item.visible) {
            unload()
            return
        }
        if (fresh) {
            watcher.running = true
            opened()
        }
    }

    function commit() {
        if (lazy.item) lazy.item.commit()
    }

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            const id = ToplevelManager.activeToplevel?.appId
            if (id) host.recent = [id].concat(host.recent.filter(x => x !== id))
        }
    }

    GlobalShortcut {
        name: "altTab"
        description: "Next app"
        onPressed: host.step(1)
    }

    GlobalShortcut {
        name: "altShiftTab"
        description: "Previous app"
        onPressed: host.step(-1)
    }

    IpcHandler {
        target: "alttab"
        function next(): void { host.step(1) }
        function previous(): void { host.step(-1) }
        function commit(): void { host.commit() }
    }

    Process {
        id: watcher
        command: [Quickshell.shellPath("altwatch.exe")]
        onRunningChanged: if (!running && lazy.item && lazy.item.visible) running = true

        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "1") host.altUp = 0
                else if (++host.altUp >= 2) host.commit()
            }
        }
    }

    LazyLoader {
        id: lazy

        AltTab {
            recent: host.recent
            onDismissed: host.unload()
        }
    }
}
