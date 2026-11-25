import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Windows
import Quickshell.Services.UPower

PanelWindow {
    id: bar

    signal controlCenterToggled
    signal appleMenuToggled

    signal appMenuClicked(int index)

    property int openMenu: -1
    property var frozen: null

    readonly property var toplevel: frozen ?? ToplevelManager.activeToplevel
    readonly property var device: UPower.displayDevice
    readonly property var info: appMenus.resolve(toplevel)
    readonly property string appName: info.name
    readonly property var menus: info.menus

    onOpenMenuChanged: frozen = openMenu >= 0 ? (frozen ?? ToplevelManager.activeToplevel) : null

    function titleRects() {
        const rects = []
        for (let n = 0; n < titles.count; n++) {
            const item = titles.itemAt(n)
            rects.push({x: item.mapToItem(null, 0, 0).x, w: item.width})
        }
        return rects
    }

    AppMenus { id: appMenus }

    property bool light: false
    readonly property color fg: light ? "#000000" : "#ffffff"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "elrice-bar"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 32
    exclusiveZone: 32
    color: "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Image {
        id: wallpaper
        source: "file:///" + Quickshell.shellPath("wallpaper.jpg")
        sourceSize: Qt.size(64, 0)
        visible: false
        onStatusChanged: if (status === Image.Ready) sampler.loadImage(source)
    }

    Canvas {
        id: sampler
        width: 64
        height: Math.max(1, Math.round(64 * wallpaper.implicitHeight / Math.max(1, wallpaper.implicitWidth)))
        opacity: 0
        onImageLoaded: requestPaint()
        onPaint: {
            if (!isImageLoaded(wallpaper.source) || bar.screen.height <= 0)
                return
            const ctx = getContext("2d")
            ctx.drawImage(wallpaper.source, 0, 0, width, height)
            const rows = Math.max(1, Math.ceil(height * 32 / bar.screen.height))
            const data = ctx.getImageData(0, 0, width, rows).data
            let sum = 0
            for (let i = 0; i < data.length; i += 4)
                sum += 0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2]
            bar.light = sum / (data.length / 4) / 255 > 0.6
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        BarItem {
            tint: bar.fg
            onClicked: bar.appleMenuToggled()

            SymbolIcon {
                source: Qt.resolvedUrl("icons/start-here-symbolic.svg")
                color: bar.fg
                size: 16
            }
        }

        BarItem {
            tint: bar.fg

            BarText {
                text: bar.appName
                color: bar.fg
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }

        Repeater {
            id: titles
            model: bar.menus

            BarItem {
                required property var modelData
                required property int index

                tint: bar.fg
                active: bar.openMenu === index
                onClicked: bar.appMenuClicked(index)

                BarText {
                    text: modelData.title
                    color: bar.fg
                    font.pixelSize: 13
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        BarItem {
            visible: Network.wifiAdapterPresent
            tint: bar.fg

            SymbolIcon {
                source: Qt.resolvedUrl("icons/cc/network-wireless" + (Network.wifiRadioOn ? "" : "-disabled") + "-symbolic.svg")
                color: bar.fg
            }
        }

        BarItem {
            visible: bar.device.isPresent
            tint: bar.fg

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(bar.device.percentage) + "%"
                color: bar.fg
                font.pixelSize: 13
            }

            SymbolIcon {
                readonly property real level: bar.device.percentage
                source: Qt.resolvedUrl("icons/" + (level >= 80 ? "battery-full" : level >= 50 ? "battery-good"
                    : level >= 20 ? "battery-low" : level >= 5 ? "battery-caution" : "battery-empty")
                    + (bar.device.state === UPowerDeviceState.Charging ? "-charging" : "") + "-symbolic.svg")
                color: bar.fg
            }
        }

        BarItem {
            tint: bar.fg
            onClicked: bar.controlCenterToggled()

            SymbolIcon {
                source: Qt.resolvedUrl("icons/cc/control-center-symbolic.svg")
                color: bar.fg
            }
        }

        BarItem {
            tint: bar.fg

            BarText {
                text: Qt.formatDateTime(clock.date, "ddd d MMM h:mm")
                color: bar.fg
                font.pixelSize: 13
            }
        }
    }
}
