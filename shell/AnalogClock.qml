import QtQuick
import Quickshell

GlassCard {
    id: card

    readonly property bool showSeconds: config?.widgets?.clock?.showSeconds !== false

    settingsKey: "clock"
    onShowSecondsChanged: face.requestPaint()

    width: 170
    height: 170
    radius: 22

    SystemClock {
        id: clock
        precision: card.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
        onDateChanged: face.requestPaint()
    }

    Canvas {
        id: face

        function hand(ctx, angle, length, tail, lineWidth, color) {
            var c = width / 2
            ctx.strokeStyle = color
            ctx.lineWidth = lineWidth
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.moveTo(c - Math.sin(angle) * tail, c + Math.cos(angle) * tail)
            ctx.lineTo(c + Math.sin(angle) * length, c - Math.cos(angle) * length)
            ctx.stroke()
        }

        function dot(ctx, radius, color) {
            ctx.fillStyle = color
            ctx.beginPath()
            ctx.arc(width / 2, width / 2, radius, 0, 2 * Math.PI)
            ctx.fill()
        }

        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var c = width / 2
            var radius = c - 14

            for (var tick = 0; tick < 60; tick++) {
                var major = tick % 5 === 0
                var angle = tick * Math.PI / 30
                var inner = radius - (major ? 9 : 4)
                ctx.strokeStyle = major ? "rgba(255,255,255,0.95)" : "rgba(255,255,255,0.4)"
                ctx.lineWidth = major ? 2.4 : 1.1
                ctx.beginPath()
                ctx.moveTo(c + Math.sin(angle) * inner, c - Math.cos(angle) * inner)
                ctx.lineTo(c + Math.sin(angle) * radius, c - Math.cos(angle) * radius)
                ctx.stroke()
            }

            ctx.fillStyle = "#ffffff"
            ctx.font = "600 16px Inter"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            var numeralRadius = radius - 23
            var numerals = [12, 3, 6, 9]
            for (var i = 0; i < numerals.length; i++) {
                var a = (numerals[i] % 12) * Math.PI / 6
                ctx.fillText(String(numerals[i]), c + Math.sin(a) * numeralRadius, c - Math.cos(a) * numeralRadius)
            }

            var seconds = clock.seconds
            var minutes = clock.minutes + seconds / 60
            var hours = (clock.hours % 12) + minutes / 60

            hand(ctx, hours * Math.PI / 6, radius * 0.5, 0, 5.5, "#ffffff")
            hand(ctx, minutes * Math.PI / 30, radius * 0.78, 0, 3.8, "#ffffff")
            dot(ctx, 5.5, "#ffffff")
            if (showSeconds) {
                hand(ctx, seconds * Math.PI / 30, radius * 0.88, radius * 0.16, 1.8, "#ff9f0a")
                dot(ctx, 3.2, "#ff9f0a")
                dot(ctx, 1.2, "#000000")
            }
        }
    }
}
