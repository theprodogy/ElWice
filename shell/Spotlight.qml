import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Windows

PanelWindow {
    id: spotlight

    property string query: ""
    property int current: 0
    property int filter: 0
    property string pending: ""

    signal dismissed
    readonly property real cardWidth: 600 + screen.width / 2 * 0.36
    readonly property var results: collect(query, filter)
    readonly property var rows: sections(results)

    readonly property var items: index(DesktopEntries.applications.values)
    readonly property var aliases: ({
        "editor": "notepad",
        "rechner": "calculator calc",
        "windows powershell": "ps pwsh",
        "command prompt": "cmd",
        "file explorer": "files explorer",
        "task manager": "taskmgr",
        "visual studio code": "vscode"
    })
    readonly property var builtins: [
        {name: "Settings", run: ["explorer.exe", "ms-settings:"]},
        {name: "File Explorer", run: ["explorer.exe"]},
        {name: "Task Manager", run: ["taskmgr.exe"]},
        {name: "Control Panel", run: ["control.exe"]},
        {name: "Command Prompt", run: ["cmd.exe"]}
    ]
    readonly property var filters: [
        {name: "Apps", icon: "icons/filter-apps-symbolic.svg"},
        {name: "Actions", icon: "icons/filter-actions-symbolic.svg"},
        {name: "Clipboard", icon: "icons/filter-clipboard-symbolic.svg"}
    ]
    readonly property var actions: [
        {name: "Lock Screen", sub: "Lock this PC", run: () => Session.lock()},
        {name: "Sleep", sub: "Put this PC to sleep", run: () => Session.suspend()},
        {name: "Restart", sub: "Restart this PC", verb: "restart", run: () => Session.reboot()},
        {name: "Shut Down", sub: "Turn off this PC", verb: "shut down", run: () => Session.shutdown()},
        {name: "Empty Recycle Bin", sub: "Delete everything in the Recycle Bin", verb: "empty the Recycle Bin", run: () => Quickshell.execDetached(["powershell.exe", "-NoProfile", "-WindowStyle", "Hidden", "-Command", "Clear-RecycleBin -Force"])},
        {name: "Settings", sub: "Open Settings", page: "ms-settings:"},
        {name: "Wi-Fi Settings", sub: "Network and Wi-Fi", page: "ms-settings:network-wifi"},
        {name: "Bluetooth Settings", sub: "Bluetooth and devices", page: "ms-settings:bluetooth"},
        {name: "Display Settings", sub: "Screens and resolution", page: "ms-settings:display"},
        {name: "Sound Settings", sub: "Output and input devices", page: "ms-settings:sound"},
        {name: "Personalization Settings", sub: "Background and colors", page: "ms-settings:personalization"}
    ]

    function norm(text) {
        return text.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, " ").trim()
    }

    function distance(a, b) {
        let row = Array.from({length: b.length + 1}, (_, i) => i)
        for (let i = 1; i <= a.length; i++) {
            const next = [i]
            for (let j = 1; j <= b.length; j++)
                next[j] = Math.min(row[j] + 1, next[j - 1] + 1, row[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1))
            row = next
        }
        return row[b.length]
    }

    function idKey(id) {
        const part = id.toLowerCase().replace(/\.exe$/, "").split("!")[0].split(/[\\/]/).pop().split("_")[0]
        return part.includes("{") ? "" : norm(part.split(".").pop())
    }

    function hidden(name, id) {
        return /^https?:/i.test(id) || /\.(url|chm|txt|html?|pdf|md|log)$/i.test(id)
            || /uninstall|readme|licen[sc]e|\bhelp\b|website|\bfaq\b|release notes|documentation|manuals?\b|module docs|\bsamples?\b|^history$/i.test(name)
    }

    function item(name, id, row, extra) {
        const n = norm(name)
        const words = n.split(" ")
        return {n: n, words: words, acro: words.map(w => w[0]).join(""), key: idKey(id), alias: norm(aliases[n] ?? ""), extra: norm(extra), row: Object.assign({name: name, sub: ""}, row)}
    }

    function index(list) {
        const seen = {}
        const items = []
        for (const e of list) {
            const target = e.execString || e.command.join(" ")
            if (e.noDisplay || !target || hidden(e.name, e.id)) continue
            const extra = e.keywords.concat(e.genericName).filter(k => k.toLowerCase() !== target.toLowerCase()).join(" ")
            items.push(item(e.name, e.id, {entry: e, icon: "image://icon/" + e.icon}, extra))
        }
        for (const b of builtins) items.push(item(b.name, "", {run: b.run, icon: ""}, ""))
        return items.filter(i => i.n !== "" && !seen[i.n] && (seen[i.n] = true))
    }

    function score(it, q) {
        if (it.n === q) return 100
        if (it.n.startsWith(q + " ")) return 95
        if (it.n.startsWith(q)) return 90
        if (it.alias.split(" ").some(w => w.startsWith(q))) return 85
        const word = it.words.findIndex((w, i) => i > 0 && w.startsWith(q))
        if (word > 0) return 80 - 4 * word
        if (q.length > 1 && it.acro.startsWith(q)) return 70
        if (it.key && (q.length > 2 ? it.key.includes(q) : it.key.startsWith(q))) return 50
        if (it.n.includes(q)) return 40
        if (it.extra.includes(q)) return 30
        if (q.length > 3 && it.words.concat(it.key).some(w => distance(q, w) <= 1 || distance(q, w.slice(0, q.length)) <= 1)) return 20
        if (q.length > 2 && it.n[0] === q[0]) {
            let at = 0
            for (const ch of q.replace(/ /g, "")) {
                at = it.n.replace(/ /g, "").indexOf(ch, at) + 1
                if (at === 0) return 0
            }
            return 10
        }
        return 0
    }

    function calc(text) {
        if (!/^[0-9+\-*\/().%^ ]+$/.test(text) || !/[+\-*\/%^]/.test(text.replace(/^\s*-/, ""))) return null
        try {
            const value = Function("return (" + text.replace(/\^/g, "**") + ")")()
            return typeof value === "number" && isFinite(value) ? String(Math.round(value * 1e10) / 1e10) : null
        } catch (error) {
            return null
        }
    }

    function search(raw) {
        const text = raw.trim().toLowerCase()
        const q = norm(text)
        if (q === "") return []
        const apps = items
            .map(i => ({row: i.row, score: score(i, q), n: i.n}))
            .filter(i => i.score > 0)
            .sort((a, b) => b.score - a.score || a.n.length - b.n.length || a.n.localeCompare(b.n))
            .slice(0, 7)
            .map(i => Object.assign({section: "Applications"}, i.row))
        const list = []
        const value = calc(text)
        if (value !== null) list.push({name: "= " + value, sub: raw.trim(), icon: "", section: "Calculator"})
        return list.concat(apps, [{name: "Search the web for \"" + raw.trim() + "\"", sub: "", icon: "", web: true, section: "Web Search"}])
    }

    function collect(raw, mode) {
        if (mode === 0) return search(raw)
        const q = norm(raw)
        if (mode === 1) {
            return actions
                .filter(a => q === "" || norm(a.name + " " + a.sub).includes(q))
                .map(a => Object.assign({icon: "", section: "Actions"}, a))
        }
        return (Clipboard.entries ?? [])
            .map(e => ({id: parseInt(e), text: e.slice(e.indexOf("\t") + 1)}))
            .filter(e => q === "" || norm(e.text).includes(q))
            .slice(0, 30)
            .map(e => ({name: e.text.replace(/\s+/g, " ").trim(), sub: "", icon: "", paste: e.id, section: "Clipboard"}))
    }

    function sections(list) {
        const out = []
        let last = ""
        let n = 0
        for (const r of list) {
            if (r.section !== last) {
                out.push({header: r.section})
                last = r.section
            }
            out.push(Object.assign({pick: n++}, r))
        }
        return out
    }

    function setFilter(f) {
        filter = f
        current = 0
        pending = ""
    }

    function open() {
        const name = Hyprland.focusedMonitor?.name
        screen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
        query = ""
        current = 0
        pending = ""
        visible = true
        input.forceActiveFocus()
    }

    function close() {
        visible = false
    }

    function toggle() {
        if (visible) close()
        else open()
    }

    function activate(row) {
        if (!row) return
        if (row.verb && pending !== row.name) {
            pending = row.name
            return
        }
        if (row.entry) row.entry.execute()
        else if (row.run) {
            if (Array.isArray(row.run)) Quickshell.execDetached(row.run)
            else row.run()
        } else if (row.page) Quickshell.execDetached(["explorer.exe", row.page])
        else if (row.paste !== undefined) Clipboard.copy(row.paste)
        else if (row.web) Quickshell.execDetached(["explorer.exe", "https://www.google.com/search?q=" + encodeURIComponent(query.trim())])
        close()
    }

    onQueryChanged: {
        current = 0
        pending = ""
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
    WlrLayershell.namespace: "elrice-spotlight"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
        anchors.fill: parent
        onClicked: spotlight.close()
    }

    Item {
        id: panel
        x: (parent.width - width) / 2
        y: parent.height * 0.2
        width: spotlight.cardWidth
        height: 68 + resultsCard.height

        GlassCard {
            width: panel.width - spotlight.filters.length * 66
            height: 56
            radius: 28

            MouseArea { anchors.fill: parent }

            Image {
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                source: Qt.resolvedUrl("icons/system-search-symbolic.svg")
                sourceSize: Qt.size(44, 44)
            }

            TextInput {
                id: input
                x: 54
                width: parent.width - 78
                height: 56
                verticalAlignment: TextInput.AlignVCenter
                color: "#ffffff"
                selectionColor: Qt.rgba(1, 1, 1, 0.3)
                font.family: "Inter"
                font.pixelSize: 20
                clip: true
                text: spotlight.query
                onTextChanged: spotlight.query = text

                Keys.onPressed: event => {
                    const count = spotlight.results.length
                    const ctrl = event.modifiers & Qt.ControlModifier
                    if (event.key === Qt.Key_Escape) {
                        spotlight.close()
                    } else if (ctrl && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + spotlight.filters.length) {
                        spotlight.setFilter(event.key - Qt.Key_1)
                    } else if (event.key === Qt.Key_Down && count > 0) {
                        spotlight.current = (spotlight.current + 1) % count
                    } else if (event.key === Qt.Key_Up && count > 0) {
                        spotlight.current = (spotlight.current - 1 + count) % count
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        spotlight.activate(spotlight.results[spotlight.current])
                    } else {
                        return
                    }
                    event.accepted = true
                }

                Text {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font: input.font
                }
            }
        }

        Row {
            x: panel.width - width
            spacing: 10

            Repeater {
                model: spotlight.filters

                GlassCard {
                    required property var modelData
                    required property int index
                    width: 56
                    height: 56
                    radius: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: 28
                        color: Qt.rgba(1, 1, 1, 0.28)
                        visible: index === spotlight.filter
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: Qt.resolvedUrl(modelData.icon)
                        sourceSize: Qt.size(48, 48)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            spotlight.setFilter(index)
                            input.forceActiveFocus()
                        }
                    }
                }
            }
        }

        GlassCard {
            id: resultsCard
            y: 68
            width: panel.width
            height: spotlight.rows.length > 0 ? spotlight.rows.reduce((h, r) => h + (r.header ? 30 : 52), 20) : 0
            visible: height > 0

            MouseArea { anchors.fill: parent }

            Column {
                x: 12
                y: 10
                width: parent.width - 24

                Repeater {
                    model: spotlight.rows

                    Item {
                        required property var modelData
                        width: parent.width
                        height: modelData.header ? 30 : 52

                        Text {
                            visible: modelData.header !== undefined
                            x: 12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            text: modelData.header ?? ""
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            visible: modelData.header === undefined
                            anchors.fill: parent
                            radius: 14
                            color: modelData.pick === spotlight.current ? Qt.rgba(1, 1, 1, 0.22) : "transparent"

                            Image {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 32
                                height: 32
                                source: modelData.icon ? modelData.icon : Qt.resolvedUrl("icons/system-search-symbolic.svg")
                                sourceSize: Qt.size(64, 64)
                            }

                            Text {
                                x: 56
                                width: parent.width - 72
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.verb && spotlight.pending === modelData.name ? "Press Enter again to " + modelData.verb
                                    : modelData.sub ? modelData.name + "   " + modelData.sub : modelData.name
                                elide: Text.ElideRight
                                color: "#ffffff"
                                font.family: "Inter"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: if (modelData.pick !== undefined) spotlight.current = modelData.pick
                                onClicked: spotlight.activate(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
