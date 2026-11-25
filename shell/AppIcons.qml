import QtQml

QtObject {
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
}
