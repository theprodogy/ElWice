import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: popover

    property var config
    property string widgetKey
    property rect target: Qt.rect(0, 0, 0, 0)
    property var values: ({})
    property string peer: "time.windows.com"
    property string syncNote: ""
    property string error: ""
    property bool busy: false
    property var pending: []
    readonly property var fields: fieldsFor(widgetKey)
    readonly property string title: ({clock: "Clock", weather: "Weather", calendar: "Calendar", nowplaying: "Now Playing", battery: "Battery"})[widgetKey] ?? ""

    signal saved(var top, var widget)
    signal dismissed

    function fieldsFor(key) {
        var hide = {name: "hidden", label: "Hide widget", type: "toggle", def: false}
        var own = {
            weather: [
                {name: "city", label: "City", type: "text", top: true, def: "Bucharest"},
                {name: "unit", label: "Unit", type: "choice", top: true, def: "celsius", options: [{label: "°C", value: "celsius"}, {label: "°F", value: "fahrenheit"}]}
            ],
            clock: [{name: "showSeconds", label: "Seconds hand", type: "toggle", def: true}, {name: "timeServer", label: "Time server", type: "text", def: "time.windows.com"}],
            calendar: [{name: "weekStart", label: "Week starts", type: "choice", def: "monday", options: [{label: "Mon", value: "monday"}, {label: "Sun", value: "sunday"}]}]
        }
        return (own[key] ?? []).concat([hide])
    }

    function initial(field) {
        var stored = field.top ? config?.[field.name] : config?.widgets?.[widgetKey]?.[field.name]
        return stored ?? field.def
    }

    function setValue(name, value) {
        var next = Object.assign({}, values)
        next[name] = value
        values = next
    }

    function finish(top, widget) {
        saved(top, widget)
        dismissed()
    }

    function apply(server, top, widget) {
        var script = "Set-Service w32time -StartupType Automatic; if ((Get-Service w32time).Status -ne 'Running') { Start-Service w32time }; w32tm /config '/manualpeerlist:" + server + ",0x8' /syncfromflags:manual /update; $c = $LASTEXITCODE; w32tm /resync; exit $c"
        var bytes = ""
        for (var i = 0; i < script.length; i++)
            bytes += String.fromCharCode(script.charCodeAt(i), 0)
        pending = [top, widget]
        error = ""
        busy = true
        applyProc.command = ["powershell.exe", "-NoProfile", "-Command", "try { $p = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -WindowStyle Hidden -ArgumentList '-NoProfile', '-EncodedCommand', '" + Qt.btoa(bytes) + "'; exit $p.ExitCode } catch { exit 1 }"]
        applyProc.running = true
    }

    function save() {
        if (busy)
            return
        var top = {}
        var widget = {}
        fields.forEach(field => {
            var value = values[field.name]
            if (typeof value === "string")
                value = value.trim() || field.def
            if (field.top)
                top[field.name] = value
            else
                widget[field.name] = value
        })
        if (widgetKey === "clock") {
            if (!/^[A-Za-z0-9.:-]{1,253}$/.test(widget.timeServer)) {
                error = "Invalid server name"
                return
            }
            if (widget.timeServer !== peer) {
                apply(widget.timeServer, top, widget)
                return
            }
        }
        finish(top, widget)
    }

    Process {
        id: readProc
        running: popover.widgetKey === "clock"
        command: ["powershell.exe", "-NoProfile", "-Command", "((Get-ItemProperty HKLM:\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Parameters).NtpServer -split '\\s+')[0] -replace ',0x\\w+$', ''; $s = @(w32tm /query /status 2>$null); if ($LASTEXITCODE -eq 0 -and $s.Count -gt 7) { ($s[6] -replace '^[^:]*:\\s*', '') + '|' + ($s[7] -replace '^[^:]*:\\s*', '' -replace ',0x\\w+$', '') }"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var found = lines[0].trim()
                if (/^[A-Za-z0-9.:-]{1,253}$/.test(found)) {
                    popover.peer = found
                    popover.setValue("timeServer", found)
                }
                var parts = (lines[1] ?? "").trim().split("|")
                var clock = /\d{1,2}:\d{2}/.exec(parts[0])
                if (clock && parts[1])
                    popover.syncNote = "Last synced " + clock[0] + " from " + parts[1]
            }
        }
    }

    Process {
        id: applyProc
        onExited: exitCode => {
            popover.busy = false
            if (exitCode === 0)
                popover.finish(popover.pending[0], popover.pending[1])
            else
                popover.error = "Not applied"
        }
    }

    Component.onCompleted: {
        var start = {}
        fields.forEach(field => start[field.name] = initial(field))
        values = start
    }

    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "elrice-widgetsettings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: popover.dismissed()
        Keys.onReturnPressed: popover.save()
        Keys.onEnterPressed: popover.save()

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: popover.dismissed()
        }

        GlassCard {
            id: card

            readonly property real besideX: popover.target.x + popover.target.width + 12

            x: Math.max(8, besideX + width + 8 <= popover.width ? besideX : popover.target.x - 12 - width)
            y: Math.max(8, Math.min(popover.target.y, popover.height - height - 8))
            width: 280
            height: list.implicitHeight + 32
            radius: 14
            shadow: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Column {
                id: list
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 10

                UiText {
                    text: popover.title
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Repeater {
                    model: popover.fields

                    Item {
                        id: row

                        required property var modelData
                        readonly property var current: popover.values[modelData.name]

                        width: list.width
                        height: 28

                        UiText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                            font.weight: Font.Normal
                        }

                        Rectangle {
                            visible: row.modelData.type === "toggle"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 24
                            radius: 12
                            color: row.current === true ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.2)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                y: 2
                                x: row.current === true ? 18 : 2
                                width: 20
                                height: 20
                                radius: 10
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            }

                            TapHandler { onTapped: popover.setValue(row.modelData.name, row.current !== true) }
                        }

                        Rectangle {
                            visible: row.modelData.type === "choice"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: segments.implicitWidth + 4
                            height: 26
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.12)

                            Row {
                                id: segments
                                x: 2
                                y: 2

                                Repeater {
                                    model: row.modelData.options ?? []

                                    Rectangle {
                                        id: segment

                                        required property var modelData

                                        width: 56
                                        height: 22
                                        radius: 6
                                        color: row.current === modelData.value ? "#0A84FF" : "transparent"

                                        UiText {
                                            anchors.centerIn: parent
                                            text: segment.modelData.label
                                            font.weight: Font.Normal
                                        }

                                        TapHandler { onTapped: popover.setValue(row.modelData.name, segment.modelData.value) }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: row.modelData.type === "text"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 140
                            height: 26
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.12)
                            border.width: field.activeFocus ? 1 : 0
                            border.color: "#0A84FF"

                            TextInput {
                                id: field
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                color: "#ffffff"
                                selectionColor: "#0A84FF"
                                font.family: Qt.fontFamilies().indexOf("Inter") >= 0 ? "Inter" : "Segoe UI Variable"
                                font.pixelSize: 13
                                text: String(row.current ?? "")
                                onTextEdited: popover.setValue(row.modelData.name, text)
                                onAccepted: popover.save()
                                Component.onCompleted: if (row.modelData.type === "text") {
                                    forceActiveFocus()
                                    selectAll()
                                }
                            }
                        }
                    }
                }

                Column {
                    visible: popover.widgetKey === "clock"
                    width: list.width
                    spacing: 6

                    UiText {
                        visible: text !== ""
                        text: popover.error || (popover.busy ? "Waiting for permission..." : popover.syncNote)
                        color: popover.error ? "#FF453A" : Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        width: parent.width
                        wrapMode: Text.Wrap
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: ["time.windows.com", "time.cloudflare.com", "pool.ntp.org", "time.google.com"]

                            Rectangle {
                                id: chip

                                required property string modelData

                                width: chipText.implicitWidth + 14
                                height: 20
                                radius: 6
                                color: Qt.rgba(1, 1, 1, chipPress.pressed ? 0.28 : 0.12)

                                UiText {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: chip.modelData
                                    font.pixelSize: 11
                                    font.weight: Font.Normal
                                }

                                TapHandler {
                                    id: chipPress
                                    onTapped: popover.setValue("timeServer", chip.modelData)
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Repeater {
                        model: [{label: "Cancel", primary: false}, {label: "Save", primary: true}]

                        Rectangle {
                            id: button

                            required property var modelData

                            width: 72
                            height: 26
                            radius: 7
                            color: modelData.primary ? "#0A84FF" : Qt.rgba(1, 1, 1, press.pressed ? 0.28 : 0.16)
                            opacity: modelData.primary && press.pressed ? 0.8 : 1

                            UiText {
                                anchors.centerIn: parent
                                text: button.modelData.label
                            }

                            TapHandler {
                                id: press
                                onTapped: button.modelData.primary ? popover.save() : popover.dismissed()
                            }
                        }
                    }
                }
            }
        }
    }
}
