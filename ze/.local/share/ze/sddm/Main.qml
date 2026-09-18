// ze SDDM greeter. Layout and behaviour derived from sddm-astronaut-theme by Keyitdev.
// Colours and wallpaper come from current/theme.conf, which `ze theme set` /
// `ze bg set --login` write.

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtMultimedia
import "Components"

Pane {
    id: root

    height: Screen.height
    width: Screen.width
    padding: 0
    palette.window: config.FormBackground
    palette.highlight: config.DropdownSelected
    palette.highlightedText: config.Text
    palette.buttonText: config.Accent
    font.family: config.Font
    font.pointSize: config.FontSize !== "" ? config.FontSize : parseInt(height / 80) || 13
    focus: true

    readonly property bool hasVideo: config.BackgroundVideo !== undefined && config.BackgroundVideo !== ""

    Item {
        id: background
        anchors.fill: parent

        AnimatedImage {
            id: backgroundImage
            anchors.fill: parent
            source: config.Background || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            clip: true
            mipmap: true
            // The still image stays underneath until the video has its first frame
            visible: !root.hasVideo || player.playbackState !== MediaPlayer.PlayingState
        }

        MediaPlayer {
            id: player
            videoOutput: videoOutput
            source: root.hasVideo ? Qt.resolvedUrl(config.BackgroundVideo) : ""
            loops: MediaPlayer.Infinite
            Component.onCompleted: if (root.hasVideo) play()
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            visible: root.hasVideo
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.forceActiveFocus()
    }

    // Blur only what sits behind the card, like astronaut's PartialBlur
    ShaderEffectSource {
        id: blurSource
        anchors.fill: card
        sourceItem: background
        sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
        visible: false
    }

    MultiEffect {
        anchors.fill: card
        source: blurSource
        blurEnabled: true
        autoPaddingEnabled: false
        blur: 1.0
        blurMax: 48
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: cardMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.5
        }
    }

    Rectangle {
        id: cardMask
        anchors.fill: card
        radius: config.RoundCorners * 1.5
        visible: false
        layer.enabled: true
    }

    Rectangle {
        id: card
        width: Math.min(parent.width * 0.32, 520)
        height: form.implicitHeight + root.font.pointSize * 6
        anchors.centerIn: parent
        radius: config.RoundCorners * 1.5
        color: config.FormBackground
        opacity: 0.72
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
    }

    ColumnLayout {
        id: form
        width: card.width - root.font.pointSize * 4
        anchors.centerIn: card
        spacing: root.font.pointSize * 1.5

        Clock {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
        }

        Input {
            id: input
            Layout.fillWidth: true
            selectedSession: sessionSelect.selectedSession
            nextFocus: sessionSelect.exposeSession
        }

        SessionButton {
            id: sessionSelect
            Layout.alignment: Qt.AlignHCenter
        }

        SystemButtons {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root.font.pointSize
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            input.failed = true
            input.clearPassword()
        }
        function onLoginSucceeded() {
            input.failed = false
        }
    }
}
