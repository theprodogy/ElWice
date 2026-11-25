import QtQml
import Quickshell
import Quickshell.Io
import "ConfigMerge.js" as ConfigMerge

ShellRoot {
    id: root

    property var config: ({city: "Bucharest", unit: "celsius", relativeY: 0.38, dock: [
        {name: "Brave", command: ["cmd.exe", "/c", "start", "", "brave"], icon: "icons/dock/brave-browser.svg", match: "brave"},
        {name: "Discord", command: ["cmd.exe", "/c", "start", "", "discord:"], icon: "icons/dock/discord.svg", match: "discord"},
        {name: "File Explorer", command: ["explorer.exe"], icon: "icons/dock/org.gnome.Nautilus.svg", match: "^(explorer|Microsoft\\.Windows\\.Explorer)$"},
        {name: "Spotify", command: ["cmd.exe", "/c", "start", "", "spotify:"], icon: "icons/dock/spotify.svg", match: "spotify"},
        {name: "WezTerm", command: ["C:\\Program Files\\WezTerm\\wezterm-gui.exe"], icon: "icons/dock/macos-terminal.svg", match: "wezterm"}
    ]})

    function saveWidget(key, top, widget) {
        var disk = ""
        try {
            disk = settingsFile.text()
        } catch (error) {
            disk = ""
        }
        settingsFile.setText(ConfigMerge.merge(disk, config, key, widget, top))
    }

    FileView {
        id: settingsFile
        path: Quickshell.shellPath("standby.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.config = Object.assign({}, root.config, JSON.parse(text()))
            } catch (error) {
                console.warn("standby.json invalid: " + error)
            }
        }
    }

    Process {
        command: [Quickshell.shellPath("taskbar.exe")]
        running: true
        stdinEnabled: true
        onRunningChanged: if (!running) running = true
    }

    SpotlightHost { id: spotlight }

    AltTabHost {
        id: altTab
        onOpened: spotlight.close()
    }

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            StandBy {
                screen: modelData
                config: root.config
                onSettingsRequested: (key, target) => {
                    settingsLazy.active = true
                    settingsLazy.item.widgetKey = key
                    settingsLazy.item.target = target
                }
            }

            LazyLoader {
                id: settingsLazy

                WidgetSettings {
                    screen: modelData
                    config: root.config
                    onSaved: (top, widget) => root.saveWidget(widgetKey, top, widget)
                    onDismissed: Qt.callLater(() => settingsLazy.active = false)
                }
            }

            property alias appleItem: appleLazy.item
            property alias appItem: appLazy.item
            property alias ccItem: ccLazy.item

            function closeMenus() {
                if (appleItem) appleItem.open = false
                if (appItem) appItem.open = false
            }

            function toggleApple() {
                if (appItem) appItem.open = false
                appleLazy.active = true
                appleLazy.item.toggle()
            }

            function pickMenu(index) {
                if (appleItem) appleItem.open = false
                appLazy.active = true
                appLazy.item.pick(index)
            }

            function toggleControlCenter() {
                ccLazy.active = true
                ccLazy.item.toggle()
            }

            Connections {
                target: altTab
                function onOpened() { closeMenus() }
            }

            TopBar {
                id: topBar
                screen: modelData
                openMenu: appItem && appItem.open ? appItem.index : -1
                onAppMenuClicked: index => pickMenu(index)
                onControlCenterToggled: toggleControlCenter()
                onAppleMenuToggled: toggleApple()
            }

            LazyLoader {
                id: appleLazy

                AppleMenu {
                    screen: modelData
                    onDismissed: Qt.callLater(() => appleLazy.active = false)
                }
            }

            LazyLoader {
                id: appLazy

                AppMenu {
                    screen: modelData
                    bar: topBar
                    onDismissed: Qt.callLater(() => appLazy.active = false)
                }
            }

            LazyLoader {
                id: ccLazy

                ControlCenter {
                    screen: modelData
                    onDismissed: Qt.callLater(() => ccLazy.active = false)
                }
            }

            Dock {
                screen: modelData
                config: root.config
                onPinsChanged: list => root.saveWidget("", {dock: list}, {})
            }
        }
    }
}
