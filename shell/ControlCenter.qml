import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Windows
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

PanelWindow {
    id: cc

    property bool open: false
    property bool brightnessAvailable: false
    property bool brightnessDdc: false
    property real brightness: 1

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function toggle() {
        open = !open
        if (open)
            Brightness.query(screen.name)
    }

    visible: open || card.opacity > 0
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "elrice-controlcenter"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) keys.forceActiveFocus()

    PwObjectTracker { objects: [cc.sink] }

    Connections {
        target: Brightness

        function onQueried(name, available, isDdc, value) {
            if (name !== cc.screen.name)
                return
            cc.brightnessAvailable = available
            cc.brightnessDdc = isDdc
            cc.brightness = value
        }

        function onSystemBrightnessChanged(name, value) {
            if (name === cc.screen.name)
                cc.brightness = value
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: cc.open = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: cc.open = false
    }

    GlassCard {
        id: card

        x: parent.width - width - 10
        y: 36
        width: 340
        height: content.implicitHeight + 20
        opacity: cc.open ? 1 : 0
        scale: cc.open ? 1 : 0.96
        transformOrigin: Item.TopRight

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            x: 10
            y: 10
            width: parent.width - 20
            spacing: 10

            Rectangle {
                width: parent.width
                height: toggles.implicitHeight + 24
                radius: 20
                color: Qt.rgba(1, 1, 1, 0.1)
                visible: Network.wifiAdapterPresent || cc.adapter !== null

                Column {
                    id: toggles
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 8

                    ControlCenterTile {
                        width: parent.width
                        visible: Network.wifiAdapterPresent
                        icon: Qt.resolvedUrl("icons/cc/network-wireless" + (Network.wifiRadioOn ? "" : "-disabled") + "-symbolic.svg")
                        title: "Wi-Fi"
                        subtitle: !Network.wifiRadioOn ? "Off" : Network.activeSsid !== "" ? Network.activeSsid : "Not Connected"
                        active: Network.wifiRadioOn
                        onClicked: Network.setWifiRadioEnabled(!Network.wifiRadioOn)
                    }

                    ControlCenterTile {
                        width: parent.width
                        visible: cc.adapter !== null
                        icon: Qt.resolvedUrl("icons/cc/bluetooth" + (cc.adapter?.enabled ? "" : "-disabled") + "-symbolic.svg")
                        title: "Bluetooth"
                        subtitle: cc.adapter?.enabled ? "On" : "Off"
                        active: cc.adapter?.enabled ?? false
                        onClicked: cc.adapter.enabled = !cc.adapter.enabled
                    }
                }
            }

            ControlCenterSlider {
                width: parent.width
                visible: cc.brightnessAvailable
                title: "Display"
                icon: Qt.resolvedUrl("icons/cc/display-brightness" + (cc.brightness < 0.4 ? "-low" : "") + "-symbolic.svg")
                value: cc.brightness
                onMoved: v => {
                    cc.brightness = v
                    Brightness.setBrightness(cc.screen.name, cc.brightnessDdc, v)
                }
            }

            ControlCenterSlider {
                width: parent.width
                visible: cc.sink !== null
                title: "Sound"
                icon: {
                    const v = cc.sink?.audio?.volume ?? 0
                    const name = cc.sink?.audio?.muted || v <= 0 ? "muted" : v < 0.34 ? "low" : v < 0.67 ? "medium" : "high"
                    return Qt.resolvedUrl("icons/cc/audio-volume-" + name + "-symbolic.svg")
                }
                value: cc.sink?.audio?.muted ? 0 : (cc.sink?.audio?.volume ?? 0)
                onIconClicked: cc.sink.audio.muted = !cc.sink.audio.muted
                onMoved: v => {
                    cc.sink.audio.muted = false
                    cc.sink.audio.volume = v
                }
            }

            Rectangle {
                width: parent.width
                height: 84
                radius: 20
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    id: art
                    x: 12
                    y: 12
                    width: 60
                    height: 60
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: cc.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Column {
                    anchors.left: art.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    y: 14

                    BarText {
                        width: parent.width
                        text: cc.player && cc.player.trackTitle !== "" ? cc.player.trackTitle : "Not Playing"
                        elide: Text.ElideRight
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    BarText {
                        width: parent.width
                        text: cc.player && cc.player.trackArtist !== "" ? cc.player.trackArtist : " "
                        elide: Text.ElideRight
                        color: Qt.rgba(1, 1, 1, 0.65)
                        font.pixelSize: 12
                    }

                    Row {
                        topPadding: 6
                        spacing: 22

                        Repeater {
                            model: ["media-skip-backward", "toggle", "media-skip-forward"]

                            SymbolIcon {
                                required property string modelData

                                size: 18
                                source: Qt.resolvedUrl("icons/" + (modelData === "toggle"
                                    ? (cc.player?.isPlaying ? "media-playback-pause" : "media-playback-start") : modelData) + "-symbolic.svg")

                                TapHandler {
                                    onTapped: {
                                        if (!cc.player)
                                            return
                                        if (modelData === "media-skip-backward")
                                            cc.player.previous()
                                        else if (modelData === "media-skip-forward")
                                            cc.player.next()
                                        else
                                            cc.player.togglePlaying()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
