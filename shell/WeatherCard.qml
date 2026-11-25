import QtQuick

GlassCard {
    id: card

    settingsKey: "weather"

    property string temperature: "--°"
    property string condition: "Loading…"
    property string range: "H:--° L:--°"
    property string icon: "weather-few-clouds"

    property string place
    property real latitude
    property real longitude

    readonly property var icons: [
        {codes: [0], text: "Clear", day: "weather-clear", night: "weather-clear-night"},
        {codes: [1], text: "Mainly Clear", day: "weather-clear", night: "weather-clear-night"},
        {codes: [2], text: "Partly Cloudy", day: "weather-few-clouds", night: "weather-few-clouds-night"},
        {codes: [3], text: "Overcast", day: "weather-overcast", night: "weather-overcast"},
        {codes: [45, 48], text: "Fog", day: "weather-fog", night: "weather-fog"},
        {codes: [51, 53, 55, 56, 57], text: "Drizzle", day: "weather-showers-scattered", night: "weather-showers-scattered"},
        {codes: [61, 63, 65, 66, 67], text: "Rain", day: "weather-showers", night: "weather-showers"},
        {codes: [71, 73, 75, 77], text: "Snow", day: "weather-snow", night: "weather-snow"},
        {codes: [80, 81, 82], text: "Showers", day: "weather-showers", night: "weather-showers"},
        {codes: [85, 86], text: "Snow Showers", day: "weather-snow", night: "weather-snow"},
        {codes: [95, 96, 99], text: "Thunderstorm", day: "weather-storm", night: "weather-storm"}
    ]

    width: 364
    height: 170
    radius: 22

    function degrees(value) {
        return Math.round(Number(value)) + "°"
    }

    function get(url, done) {
        var request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return
            try {
                if (request.status !== 200)
                    throw new Error("HTTP " + request.status)
                done(JSON.parse(request.responseText))
            } catch (error) {
                card.condition = "Weather unavailable"
            }
        }
        request.open("GET", url)
        request.send()
    }

    function forecast() {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"
            + (config?.unit === "fahrenheit" ? "&temperature_unit=fahrenheit" : "")
        get(url, function(data) {
            var code = data.current.weather_code
            var entry = icons.find(function(candidate) { return candidate.codes.indexOf(code) >= 0 })
            card.icon = !entry ? "weather-severe-alert" : data.current.is_day ? entry.day : entry.night
            card.condition = entry ? entry.text : "Unknown"
            card.temperature = degrees(data.current.temperature_2m)
            card.range = "H:" + degrees(data.daily.temperature_2m_max[0]) + " L:" + degrees(data.daily.temperature_2m_min[0])
        })
    }

    function refresh() {
        var city = String(config?.city ?? "Bucharest")
        if (city === place) {
            forecast()
            return
        }
        var pair = city.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        if (pair) {
            place = city
            latitude = Number(pair[1])
            longitude = Number(pair[2])
            forecast()
            return
        }
        get("https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(city) + "&count=1&language=en&format=json", function(data) {
            place = city
            latitude = data.results[0].latitude
            longitude = data.results[0].longitude
            forecast()
        })
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