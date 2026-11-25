import QtQuick
import Quickshell.Services.UPower

GlassCard {
    id: card

    settingsKey: "battery"

    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging

    visible: device.isPresent
    width: 170
    height: 170
    radius: 22

    Canvas {
        id: ring

        property real fraction: card.level / 100
        property bool low: card.level < 20 && !card.charging

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        width: 90
        height: 90
        onFractionChanged: requestPaint()
        onLowChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.lineWidth = 9
            ctx.lineCap = "round"
            ctx.strokeStyle = "rgba(255,255,255,0.16)"
            ctx.beginPath()
            ctx.arc(45, 45, 39, 0, 2 * Math.PI)
            ctx.stroke()
            ctx.strokeStyle = low ? "#ff453a" : "#30d158"
            ctx.beginPath()
            ctx.arc(45, 45, 39, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(fraction, 0.01))
            ctx.stroke()
        }

        UiText {
            anchors.centerIn: parent
            text: Math.round(card.level) + "%"
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }
    }

    UiText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        text: card.charging ? "Charging" : card.device.state === UPowerDeviceState.FullyCharged ? "Fully Charged" : "Battery"
        color: Qt.rgba(1, 1, 1, 0.65)
    }
}
