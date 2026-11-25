import QtQuick
import Quickshell

MenuDropdown {
    id: menu

    property string appName: ""
    property string appId: ""
    property var windows: []
    property var entry: null
    property var currentPins: []
    property real centerX: 0

    signal pinsEdited(var list)

    readonly property bool isAumid: appId.indexOf("!") >= 0
    readonly property bool isPath: !isAumid && /[\\/]/.test(appId)
    readonly property string exe: appId.replace(/^.*[!\\/]/, "").replace(/\.exe$/i, "")
    readonly property bool hasWindows: windows.length > 0
    readonly property string prettyName: exe.charAt(0).toUpperCase() + exe.slice(1)

    namespace: "elrice-dockmenu"
    atBottom: true
    cardWidth: 220
    cardX: Math.max(8, Math.min(centerX - cardWidth / 2, (screen ? screen.width : 1920) - cardWidth - 8))

    AppIcons { id: icons }

    function newWindow() {
        if (entry)
            Quickshell.execDetached(entry.command)
        else if (isAumid)
            Quickshell.execDetached(["explorer.exe", "shell:AppsFolder\\" + appId])
        else if (isPath)
            Quickshell.execDetached([appId])
        else if (exe !== "")
            Quickshell.execDetached(["cmd.exe", "/c", "start", "", exe])
    }

    function pin() {
        const command = isAumid ? ["explorer.exe", "shell:AppsFolder\\" + appId]
            : isPath ? [appId] : ["cmd.exe", "/c", "start", "", exe]
        const key = isAumid ? appId : exe
        pinsEdited(currentPins.concat([{
            name: isAumid ? appName : prettyName,
            icon: String(icons.iconFor(appId)),
            command: command,
            match: key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
        }]))
    }

    function unpin() {
        pinsEdited(currentPins.filter(p => p.match !== entry.match))
    }

    function quit() {
        windows.forEach(t => t.close())
    }

    function forceQuit() {
        if (exe === "" || isAumid)
            Quickshell.execDetached(["taskkill", "/F", "/T", "/FI", "WINDOWTITLE eq " + windows[0].title])
        else
            Quickshell.execDetached(["taskkill", "/F", "/T", "/IM", exe + ".exe"])
    }

    rows: {
        const list = [
            {name: entry || isAumid || exe === "" ? appName : prettyName, disabled: true},
            {name: "New Window", disabled: !entry && !isAumid && exe === "", run: newWindow},
            entry ? {name: "Unpin from Dock", run: unpin} : {name: "Pin to Dock", run: pin}
        ]
        if (isPath)
            list.push({name: "Show in Explorer", run: () => Quickshell.execDetached(["explorer.exe", "/select," + appId])})
        if (hasWindows)
            list.push(
                {sep: true},
                {name: "Quit", run: quit},
                {name: "Force Quit", verb: "force quit", disabled: exe.toLowerCase() === "explorer", run: forceQuit}
            )
        return list
    }
}
