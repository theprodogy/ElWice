import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Windows

Scope {
    id: host

    function toggle() {
        if (lazy.item && lazy.item.visible) {
            lazy.item.close()
            return
        }
        lazy.active = true
        lazy.item.open()
    }

    function close() {
        if (lazy.item) lazy.item.close()
    }

    GlobalShortcut {
        name: "spotlightToggle"
        description: "Toggle Spotlight"
        onPressed: host.toggle()
    }

    IpcHandler {
        target: "spotlight"
        function toggle(): void { host.toggle() }
    }

    LazyLoader {
        id: lazy

        Spotlight {
            onDismissed: Qt.callLater(() => lazy.active = false)
        }
    }
}
