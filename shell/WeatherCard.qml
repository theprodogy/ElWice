import QtQuick

GlassCard {
    id: card

    property var config
    property string temperature: "--°"
    property string condition: "Loading…"
    property string range: "H:--° L:--°"
    property string icon: "weather-few-clouds"

    readonly property var icons: [
        {codes: [113], day: "weather-clear", night: "weather-clear-night"},
        {codes: [116], day: "weather-few-clouds", night: "weather-few-clouds-night"},
        {codes: [119, 122], day: "weather-overcast", night: "weather-overcast"},
        {codes: [143, 248, 260], day: "weather-fog", night: "weather-fog"},
        {codes: [176, 263, 266, 281, 284, 293, 296, 353], day: "weather-showers-scattered", night: "weather-showers-scattered"},
        {codes: [299, 302, 305, 308, 311, 314, 356, 359], day: "weather-showers", night: "weather-showers"},
        {codes: [179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377], day: "weather-snow", night: "weather-snow"},
        {codes: [200, 386, 389, 392, 395], day: "weather-storm", night: "weather-storm"}
    ]

    width: 364
    height: 170
    radius: 22

    function degrees(value) {
        return Math.round(Number(value)) + "°"
    }

    function refresh() {
        var city = config?.city ?? "Bucharest"
        var fahrenheit = config?.unit === "fahrenheit"
        var request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return
            try {
                if (request.status !== 200)
                    throw new Error("HTTP " + request.status)
                var data = JSON.parse(request.responseText)
                var current = data.current_condition[0]
                var today = data.weather[0]
                var code = Number(current.weatherCode)
                var entry = icons.find(function(candidate) { return candidate.codes.indexOf(code) >= 0 })
                var hour = new Date().getHours()
                var isDay = hour >= 6 && hour < 20
                card.icon = !entry ? "weather-severe-alert" : isDay ? entry.day : entry.night
                card.condition = current.weatherDesc[0].value
                card.temperature = degrees(fahrenheit ? current.temp_F : current.temp_C)
                card.range = "H:" + degrees(fahrenheit ? today.maxtempF : today.maxtempC)
                    + " L:" + degrees(fahrenheit ? today.mintempF : today.mintempC)
            } catch (error) {
                card.condition = "Weather unavailable"
            }
        }
        request.open("GET", "https://wttr.in/" + encodeURIComponent(city) + "?format=j1")
        request.send()
    }

    onConfigChanged: refresh()

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: card.refresh()
    }

    UiText {
        id: city
        x: 20
        y: 18
        text: card.config?.city ?? "Bucharest"
        font.pixelSize: 16
        font.weight: Font.Bold

        Image {
            anchors.left: parent.right
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            source: Qt.resolvedUrl("icons/find-location-symbolic.svg")
            sourceSize: Qt.size(26, 26)
            width: 13
            height: 13
        }
    }

    UiText {
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        text: card.temperature
        font.pixelSize: 62
        font.weight: Font.Light
    }

    Image {
        anchors.right: parent.right
        anchors.rightMargin: 24
        y: 18
        source: Qt.resolvedUrl("icons/" + card.icon + ".svg")
        sourceSize: Qt.size(120, 120)
        width: 60
        height: 60
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        spacing: 2

        UiText {
            anchors.right: parent.right
            width: Math.min(implicitWidth, 160)
            text: card.condition
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }

        UiText {
            anchors.right: parent.right
            text: card.range
            color: Qt.rgba(1, 1, 1, 0.65)
        }
    }
}