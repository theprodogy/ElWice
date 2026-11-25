import QtQuick
import Quickshell.Services.Mpris

GlassCard {
    id: card

    settingsKey: "nowplaying"

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    width: 364
    height: 170
    radius: 22

    Rectangle {
        id: art
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        width: 130
        height: 130
        radius: 14
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.18) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.06) }
        }

        Image {
            anchors.fill: parent
            source: card.player?.trackArtUrl ?? ""
            sourceSize: Qt.size(260, 260)
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        UiText {
            width: parent.width
            text: card.player && card.player.trackTitle !== "" ? card.player.trackTitle : "Not Playing"
            elide: Text.ElideRight
            font.pixelSize: 16
            font.weight: Font.Bold
        }

        UiText {
            width: parent.width
            text: card.player && card.player.trackArtist !== "" ? card.player.trackArtist : " "
            elide: Text.ElideRight
            color: Qt.rgba(1, 1, 1, 0.65)
        }

        Row {
            topPadding: 16
            spacing: 14

            Repeater {
                model: ["media-skip-backward", "toggle", "media-skip-forward"]

                Rectangle {
                    required property string modelData

                    width: 34
                    height: 34
                    radius: 17
                    color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.14)
                    scale: area.pressed ? 0.94 : 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1] } }

                    Image {
                        anchors.centerIn: parent
                        source: Qt.resolvedUrl("icons/" + (parent.modelData === "toggle"
                            ? (card.player?.isPlaying ? "media-playback-pause" : "media-playback-start") : parent.modelData) + "-symbolic.svg")
                        sourceSize: Qt.size(36, 36)
                        width: 18
                        height: 18
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!card.player)
                                return
                            if (modelData === "media-skip-backward")
                                card.player.previous()
                            else if (modelData === "media-skip-forward")
                                card.player.next()
                            else
                                card.player.togglePlaying()
                        }
                    }
                }
            }
        }
    }
}
