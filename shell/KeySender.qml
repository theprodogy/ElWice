import QtQuick
import Quickshell.Windows

Item {
    id: sender

    property string queued: ""

    readonly property var mods: ({ctrl: 29, shift: 42, alt: 56})
    readonly property var glyphs: ({
        ctrl: "⌃", shift: "⇧", alt: "⌥", left: "←", right: "→", up: "↑", down: "↓", enter: "↵",
        esc: "⎋", tab: "⇥", delete: "⌦", backspace: "⌫", space: "Space", pageup: "PgUp",
        pagedown: "PgDn", home: "Home", end: "End"
    })
    readonly property var keys: ({
        esc: 1, "1": 2, "2": 3, "3": 4, "4": 5, "5": 6, "6": 7, "7": 8, "8": 9, "9": 10, "0": 11,
        "-": 12, "=": 13, backspace: 14, tab: 15, q: 16, w: 17, e: 18, r: 19, t: 20, y: 21, u: 22,
        i: 23, o: 24, p: 25, "[": 26, "]": 27, enter: 28, a: 30, s: 31, d: 32, f: 33, g: 34, h: 35,
        j: 36, k: 37, l: 38, ";": 39, "'": 40, "`": 41, "\\": 43, z: 44, x: 45, c: 46, v: 47, b: 48,
        n: 49, m: 50, ",": 51, ".": 52, "/": 53, space: 57, f1: 59, f2: 60, f3: 61, f4: 62, f5: 63,
        f6: 64, f7: 65, f8: 66, f9: 67, f10: 68, f11: 87, f12: 88, home: 102, up: 103, pageup: 104,
        left: 105, right: 106, end: 107, down: 108, pagedown: 109, delete: 111
    })

    function parse(combo) {
        const parts = combo.toLowerCase().split("+")
        const key = parts.pop()
        return {mods: parts, key: key}
    }

    function glyph(combo) {
        const p = parse(combo)
        return p.mods.map(m => glyphs[m]).join("") + (glyphs[p.key] ?? p.key.toUpperCase())
    }

    function send(toplevel, combo) {
        if (!toplevel)
            return
        toplevel.minimized = false
        toplevel.activate()
        queued = combo
        delay.restart()
    }

    function press() {
        const p = parse(queued)
        const down = p.mods.map(m => mods[m])
        const code = keys[p.key]
        down.forEach(c => Input.sendKey(c, true))
        Input.sendKey(code, true)
        Input.sendKey(code, false)
        down.slice().reverse().forEach(c => Input.sendKey(c, false))
        queued = ""
    }

    Timer {
        id: delay
        interval: 100
        onTriggered: sender.press()
    }
}
