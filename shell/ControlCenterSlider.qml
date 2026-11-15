import QtQuick

Rectangle {
    id: slider

    property string title
    property url icon
    property real value
    signal moved(real value)
    signal iconClicked

    implicitHeight: 66
    radius: 20
    color: Qt.rgba(1, 1, 1, 0.1)

    BarText {
        x: 16
        y: 9
        text: slider.title
        color: "#ffffff"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    Rectangle {
        id: track
        x: 12
        y: 30
        width: parent.width - 24
        height: 28
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.16)

        Rectangle {
            width: 28 + slider.value * (track.width - 28)
            height: parent.height
            radius: 14
            color: "#ffffff"
        }

        SymbolIcon {
            x: 5 + slider.value * (track.width - 28)
            anchors.verticalCenter: parent.verticalCenter
            source: slider.icon
            color: "#000000"
            size: 18
        }

        MouseArea {
            property bool onKnob
            property bool dragged

            anchors.fill: parent
            onPressed: mouse => {
                dragged = false
                onKnob = Math.abs(mouse.x - 14 - slider.value * (width - 28)) < 14
                if (!onKnob)
                    slider.moved(Math.max(0, Math.min(1, (mouse.x - 14) / (width - 28))))
            }
            onPositionChanged: mouse => {
                dragged = true
                slider.moved(Math.max(0, Math.min(1, (mouse.x - 14) / (width - 28))))
            }
            onReleased: if (onKnob && !dragged) slider.iconClicked()
        }
    }
}
