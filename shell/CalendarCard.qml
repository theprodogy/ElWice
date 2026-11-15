import QtQuick
import Quickshell

GlassCard {
    id: card

    readonly property date today: clock.date
    readonly property int offset: (new Date(today.getFullYear(), today.getMonth(), 1).getDay() + 6) % 7
    readonly property int days: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    width: 364
    height: 170
    radius: 22

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        UiText {
            text: Qt.formatDateTime(card.today, "dddd").toUpperCase()
            color: "#ff453a"
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        UiText {
            text: card.today.getDate()
            font.pixelSize: 64
            font.weight: Font.Medium
        }

        UiText {
            text: Qt.formatDateTime(card.today, "MMMM yyyy")
            color: Qt.rgba(1, 1, 1, 0.65)
        }
    }

    Grid {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        columns: 7

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]

            UiText {
                required property string modelData

                width: 23
                height: 19
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 11
            }
        }

        Repeater {
            model: 42

            Item {
                required property int index
                readonly property int day: index - card.offset + 1
                readonly property bool isToday: day === card.today.getDate()

                width: 23
                height: 19

                Rectangle {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    radius: 10
                    color: "#ff453a"
                    visible: parent.isToday
                }

                UiText {
                    anchors.centerIn: parent
                    visible: parent.day >= 1 && parent.day <= card.days
                    text: parent.day
                    font.pixelSize: 11
                    font.weight: parent.isToday ? Font.Bold : Font.Medium
                }
            }
        }
    }
}
