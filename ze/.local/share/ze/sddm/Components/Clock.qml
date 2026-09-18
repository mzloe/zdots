import QtQuick 2.15
import QtQuick.Controls 2.15

Column {
    id: clock
    spacing: 0

    Label {
        id: timeLabel
        anchors.horizontalCenter: parent.horizontalCenter
        font.pointSize: root.font.pointSize * 5
        font.bold: true
        color: config.Text
        renderType: Text.QtRendering
        function update() {
            text = new Date().toLocaleTimeString(Qt.locale(), config.HourFormat || Locale.ShortFormat)
        }
    }

    Label {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        font.pointSize: root.font.pointSize * 1.2
        color: config.TextMuted
        renderType: Text.QtRendering
        function update() {
            text = new Date().toLocaleDateString(Qt.locale(), config.DateFormat || Locale.LongFormat)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            timeLabel.update()
            dateLabel.update()
        }
    }

    Component.onCompleted: {
        timeLabel.update()
        dateLabel.update()
    }
}
