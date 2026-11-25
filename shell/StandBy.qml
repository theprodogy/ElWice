import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window

    property var config

    signal settingsRequested(string key, rect target)

    function request(key, target) {
        settingsRequested(key, Qt.rect(target.x + margins.left, target.y + margins.top, target.width, target.height))
    }

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "elrice-standby"

    anchors {
        top: true
        left: true
    }

    margins {
        left: 24
        top: 48
    }

    exclusionMode: ExclusionMode.Ignore
    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    color: "transparent"

    Row {
        id: grid
        spacing: 24

        Column {
            spacing: 24

            CalendarCard {
                config: window.config
                onSettingsRequested: target => window.request(settingsKey, target)
            }

            WeatherCard {
                config: window.config
                onSettingsRequested: target => window.request(settingsKey, target)
            }
        }

        Column {
            spacing: 24

            NowPlayingCard {
                config: window.config
                onSettingsRequested: target => window.request(settingsKey, target)
            }

            Row {
                spacing: 24

                AnalogClock {
                    config: window.config
                    onSettingsRequested: target => window.request(settingsKey, target)
                }
                BatteryCard {
                    config: window.config
                    onSettingsRequested: target => window.request(settingsKey, target)
                }
            }
        }
    }
}
