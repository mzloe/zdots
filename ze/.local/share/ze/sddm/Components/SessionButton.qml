import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: sessionButton
    implicitHeight: selectSession.implicitHeight
    implicitWidth: selectSession.implicitWidth

    property var selectedSession: selectSession.currentIndex
    property ComboBox exposeSession: selectSession

    ComboBox {
        id: selectSession
        hoverEnabled: true
        model: sessionModel
        currentIndex: model.lastIndex
        textRole: "name"
        Keys.onPressed: function(event) {
            if ((event.key == Qt.Key_Left || event.key == Qt.Key_Right) && !popup.opened) popup.open()
        }
        indicator: Item {}
        contentItem: Text {
            id: displayedItem
            text: "Session: " + selectSession.currentText
            color: selectSession.hovered || selectSession.visualFocus ? config.Accent : config.TextMuted
            font.pointSize: root.font.pointSize * 0.85
            font.family: root.font.family
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        background: Item { implicitWidth: displayedItem.implicitWidth + 20; implicitHeight: root.font.pointSize * 2.2 }

        delegate: ItemDelegate {
            width: popupHandler.width - 20
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
            contentItem: Text {
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: model.name
                font.pointSize: root.font.pointSize * 0.85
                font.family: root.font.family
                color: config.Text
            }
            background: Rectangle {
                radius: config.RoundCorners / 2
                color: selectSession.highlightedIndex === index ? config.DropdownSelected : "transparent"
            }
        }

        popup: Popup {
            id: popupHandler
            width: Math.max(sessionButton.width * 2, 220)
            x: (sessionButton.width - width) / 2
            y: parent.height + 4
            padding: 10
            implicitHeight: contentItem.implicitHeight
            contentItem: ListView {
                implicitHeight: contentHeight + 20
                clip: true
                model: selectSession.popup.visible ? selectSession.delegateModel : null
                currentIndex: selectSession.highlightedIndex
            }
            background: Rectangle {
                radius: config.RoundCorners
                color: config.Dropdown
            }
        }
    }
}
