import QtQuick
import Quickshell
import Quickshell.Windows

MenuDropdown {
    namespace: "elrice-applemenu"

    rows: [
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
}
