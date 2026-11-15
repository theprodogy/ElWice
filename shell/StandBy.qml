import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window

    property var config

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

            CalendarCard {}

            WeatherCard {
                config: window.config
            }
        }

        Column {
            spacing: 24

            NowPlayingCard {}

            Row {
                spacing: 24

                AnalogClock {}
                BatteryCard {}
            }
        }
    }
}
