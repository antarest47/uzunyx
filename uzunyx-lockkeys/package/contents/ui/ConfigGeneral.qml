import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property alias cfg_showNumLock: bothKeys.checked

    Kirigami.FormLayout {
        QQC2.RadioButton {
            id: bothKeys
            Kirigami.FormData.label: i18nc("@label", "Keys:")
            text: i18nc("@option:radio", "Caps Lock and Num Lock")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            leftPadding: bothKeys.indicator.width + bothKeys.spacing
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18nc("@info", "Num Lock is turned on at login.")
        }
        QQC2.RadioButton {
            id: capsOnly
            text: i18nc("@option:radio", "Caps Lock only")
            checked: !bothKeys.checked
            onToggled: bothKeys.checked = !checked
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            leftPadding: capsOnly.indicator.width + capsOnly.spacing
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18nc("@info", "For keyboards without a numeric keypad. Num Lock is left as it is at login.")
        }
    }
}
