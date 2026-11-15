import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property var config: ({city: "Bucharest", unit: "celsius", relativeY: 0.38, dock: [
        {name: "Brave", command: ["cmd.exe", "/c", "start", "", "brave"], icon: "icons/dock/brave-browser.svg", match: "brave"},
        {name: "Discord", command: ["cmd.exe", "/c", "start", "", "discord:"], icon: "icons/dock/discord.svg", match: "discord"},
        {name: "File Explorer", command: ["explorer.exe"], icon: "icons/dock/org.gnome.Nautilus.svg", match: "^(explorer|Microsoft\\.Windows\\.Explorer)$"},
        {name: "Spotify", command: ["cmd.exe", "/c", "start", "", "spotify:"], icon: "icons/dock/spotify.svg", match: "spotify"},
        {name: "WezTerm", command: ["C:\\Program Files\\WezTerm\\wezterm-gui.exe"], icon: "icons/dock/macos-terminal.svg", match: "wezterm"}
    ]})

    FileView {
        path: Quickshell.shellPath("standby.json")
        onLoaded: {
            try {
                root.config = Object.assign({}, root.config, JSON.parse(text()))
            } catch (error) {
                console.warn("standby.json invalid: " + error)
            }
        }
    }

    Spotlight {}

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            StandBy {
                screen: modelData
                config: root.config
            }

            TopBar {
                screen: modelData
                onControlCenterToggled: controlCenter.toggle()
                onAppleMenuToggled: appleMenu.toggle()
            }

            AppleMenu {
                id: appleMenu
                screen: modelData
            }

            ControlCenter {
                id: controlCenter
                screen: modelData
            }

            Dock {
                screen: modelData
                config: root.config
            }
        }
    }
}
