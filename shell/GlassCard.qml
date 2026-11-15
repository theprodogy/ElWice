import QtQuick
import QtQuick.Effects

Item {
    id: card

    default property alias content: inner.data
    property real radius: 26
    property color tint: Qt.rgba(0.06, 0.06, 0.08, 0.4)
    property bool shadow: false

    Rectangle {
        anchors.fill: parent
        radius: card.radius
        color: card.tint
        layer.enabled: card.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowVerticalOffset: 6
            shadowBlur: 0.8
        }
    }

    Canvas {
        property real r: card.radius

        anchors.fill: parent
        onRChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (width < 2 || height < 2)
                return
            var rad = Math.min(r, width / 2, height / 2)
            ctx.save()
            ctx.beginPath()
            ctx.roundedRect(0, 0, width, height, rad, rad)
            ctx.clip()
            var sheen = ctx.createLinearGradient(0, 0, 0, height * 0.55)
            sheen.addColorStop(0, "rgba(255,255,255,0.10)")
            sheen.addColorStop(1, "rgba(255,255,255,0)")
            ctx.fillStyle = sheen
            ctx.fillRect(0, 0, width, height * 0.55)
            var shade = ctx.createLinearGradient(0, height - 28, 0, height)
            shade.addColorStop(0, "rgba(0,0,0,0)")
            shade.addColorStop(1, "rgba(0,0,0,0.22)")
            ctx.fillStyle = shade
            ctx.fillRect(0, height - 28, width, 28)
            ctx.restore()
            var rim = ctx.createLinearGradient(0, 0, width, height)
            rim.addColorStop(0, "rgba(255,255,255,0.6)")
            rim.addColorStop(0.3, "rgba(255,255,255,0.14)")
            rim.addColorStop(0.7, "rgba(255,255,255,0.06)")
            rim.addColorStop(1, "rgba(255,255,255,0.3)")
            ctx.strokeStyle = rim
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.roundedRect(0.5, 0.5, width - 1, height - 1, rad - 0.5, rad - 0.5)
            ctx.stroke()
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
