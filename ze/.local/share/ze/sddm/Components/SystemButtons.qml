import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

RowLayout {
    spacing: root.font.pointSize * 1.5

    Repeater {
        model: [
            { icon: "Suspend",   label: textConstants.suspend,   enabled: sddm.canSuspend,   run: function() { sddm.suspend() } },
            { icon: "Hibernate", label: textConstants.hibernate, enabled: sddm.canHibernate, run: function() { sddm.hibernate() } },
            { icon: "Reboot",    label: textConstants.reboot,    enabled: sddm.canReboot,    run: function() { sddm.reboot() } },
            { icon: "Shutdown",  label: textConstants.shutdown,  enabled: sddm.canPowerOff,  run: function() { sddm.powerOff() } }
        ]

        RoundButton {
            id: button
            required property var modelData
            visible: modelData.enabled
            hoverEnabled: true
            text: modelData.label
            font.pointSize: root.font.pointSize * 0.75
            display: AbstractButton.TextUnderIcon
            icon.source: Qt.resolvedUrl("../Assets/" + modelData.icon + ".svg")
            icon.width: root.font.pointSize * 2.2
            icon.height: root.font.pointSize * 2.2
            icon.color: hovered || activeFocus ? config.Accent : config.TextMuted
            palette.buttonText: hovered || activeFocus ? config.Accent : config.TextMuted
            background: Item {}
            onClicked: modelData.run()
            Keys.onReturnPressed: clicked()
        }
    }
}
