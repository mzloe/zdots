import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import SddmComponents 2.0 as SDDM

ColumnLayout {
    id: input
    spacing: root.font.pointSize * 0.8

    property bool failed: false
    property int selectedSession: 0
    property Item nextFocus: null

    SDDM.TextConstants { id: textConstants }

    function clearPassword() {
        password.text = ""
        password.forceActiveFocus()
    }

    function login() {
        var user = username.text
        // The field shows real names; map back to the account name
        for (var i = 0; i < userModel.count; i++) {
            var realName = userModel.data(userModel.index(i, 0), Qt.UserRole + 2)
            var name = userModel.data(userModel.index(i, 0), Qt.UserRole + 1)
            if (user === realName || user === name) {
                user = name
                break
            }
        }
        sddm.login(user, password.text, input.selectedSession)
    }

    component Field: TextField {
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.4
        horizontalAlignment: TextInput.AlignHCenter
        color: config.Text
        placeholderTextColor: config.Placeholder
        selectByMouse: true
        renderType: Text.QtRendering
        leftPadding: root.font.pointSize * 3
        rightPadding: root.font.pointSize * 3
        background: Rectangle {
            radius: config.RoundCorners
            color: config.FieldBackground
            opacity: 0.9
            border.width: parent.activeFocus ? 2 : 0
            border.color: config.Accent
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.4

        Field {
            id: username
            anchors.fill: parent
            placeholderText: textConstants.userName
            // Prefill the last user (real name shown, account name sent by login())
            Component.onCompleted: text = selectUser.currentText || selectUser.currentValue || userModel.lastUser || ""
            onAccepted: password.forceActiveFocus()
            KeyNavigation.down: password
            KeyNavigation.tab: password
        }

        // The icon opens the account list; typing still works
        ComboBox {
            id: selectUser
            width: parent.height
            height: parent.height
            anchors.left: parent.left
            model: userModel
            currentIndex: model.lastIndex
            textRole: "realName"
            valueRole: "name"
            displayText: ""
            onActivated: username.text = currentText || currentValue
            contentItem: Item {}
            background: Item {}
            indicator: Button {
                anchors.fill: parent
                enabled: false
                icon.source: Qt.resolvedUrl("../Assets/User.svg")
                icon.width: parent.height * 0.4
                icon.height: parent.height * 0.4
                icon.color: selectUser.hovered || selectUser.popup.visible ? config.Accent : config.Placeholder
                display: AbstractButton.IconOnly
                background: Item {}
            }

            delegate: ItemDelegate {
                width: popupHandler.width - 20
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                contentItem: Text {
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: model.realName || model.name
                    font.pointSize: root.font.pointSize * 0.9
                    font.family: root.font.family
                    color: config.Text
                }
                background: Rectangle {
                    radius: config.RoundCorners / 2
                    color: selectUser.highlightedIndex === index ? config.DropdownSelected : "transparent"
                }
            }

            popup: Popup {
                id: popupHandler
                width: username.width
                y: parent.height + 4
                padding: 10
                implicitHeight: contentItem.implicitHeight
                contentItem: ListView {
                    implicitHeight: contentHeight + 20
                    clip: true
                    model: selectUser.popup.visible ? selectUser.delegateModel : null
                    currentIndex: selectUser.highlightedIndex
                }
                background: Rectangle {
                    radius: config.RoundCorners
                    color: config.Dropdown
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.4

        Field {
            id: password
            anchors.fill: parent
            focus: true
            echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            placeholderText: textConstants.password
            onAccepted: input.login()
            KeyNavigation.up: username
            KeyNavigation.down: loginButton
            KeyNavigation.tab: loginButton
        }

        Button {
            id: showPassword
            width: parent.height
            height: parent.height
            anchors.left: parent.left
            checkable: true
            hoverEnabled: true
            background: Item {}
            display: AbstractButton.IconOnly
            icon.source: Qt.resolvedUrl(showPassword.checked ? "../Assets/Password.svg" : "../Assets/Password2.svg")
            icon.width: parent.height * 0.4
            icon.height: parent.height * 0.4
            icon.color: showPassword.hovered || showPassword.checked ? config.Accent : config.Placeholder
        }
    }

    Button {
        id: loginButton
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.2
        text: textConstants.login
        font.bold: true
        hoverEnabled: true
        enabled: password.text !== "" || username.text !== ""
        onClicked: input.login()
        Keys.onReturnPressed: input.login()
        Keys.onEnterPressed: input.login()
        KeyNavigation.up: password
        KeyNavigation.down: input.nextFocus
        contentItem: Text {
            text: loginButton.text
            font: loginButton.font
            color: config.FormBackground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: config.RoundCorners
            color: loginButton.down ? Qt.darker(config.Accent, 1.15) : loginButton.hovered || loginButton.activeFocus ? Qt.lighter(config.Accent, 1.1) : config.Accent
            opacity: loginButton.enabled ? 1 : 0.5
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 1.6
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: root.font.pointSize * 0.85
        font.italic: true
        color: config.Warning
        text: input.failed ? textConstants.loginFailed : keyboard.capsLock ? textConstants.capslockWarning : ""
        opacity: text !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
