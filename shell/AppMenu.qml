import QtQuick
import Quickshell
import Quickshell.Windows

MenuDropdown {
    id: menu

    property var bar
    property var target: null
    property int index: -1

    readonly property var current: bar && index >= 0 && index < bar.menus.length ? bar.menus[index] : null
    property var rects: []

    namespace: "elrice-appmenu"
    trackBar: true
    cardWidth: 290
    cardX: index >= 0 && index < rects.length ? rects[index].x : 8
    rows: current ? current.items.map(item => ({
        name: item.name,
        sep: item.sep === true,
        shortcut: item.keys ? sender.glyph(item.keys) : "",
        disabled: !item.sep && !item.url && !item.exec && !target,
        item: item
    })) : []

    KeySender { id: sender }

    function pick(i) {
        if (open && index === i) {
            open = false
            return
        }
        index = i
        open = true
    }

    function hit(x) {
        return rects.findIndex(r => x >= r.x && x < r.x + r.w)
    }

    function run(item) {
        if (item.exec) {
            Quickshell.execDetached(item.exec)
        } else if (item.url) {
            Quickshell.execDetached(["explorer.exe", item.url])
        } else if (item.action === "minimize") {
            target.minimized = true
        } else if (item.action === "zoom") {
            target.maximized = !target.maximized
        } else if (item.action === "close") {
            target.close()
        } else {
            sender.send(target, item.keys)
        }
    }

    onOpened: {
        target = bar.toplevel
        rects = bar.titleRects()
    }
    onBarHovered: x => {
        const i = hit(x)
        if (open && i >= 0)
            index = i
    }
    onBarClicked: x => {
        const i = hit(x)
        if (i >= 0)
            pick(i)
        else
            open = false
    }
    onTriggered: row => {
        if (row.item)
            run(row.item)
    }
}
