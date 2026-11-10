/*
 * All the texts come from Plasma's task manager and use its translations.
 */
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

KCMUtils.SimpleKCM {
    id: page

    readonly property string domain: "plasma_applet_org.kde.plasma.taskmanager"

    property alias cfg_showToolTips: showToolTips.checked
    property alias cfg_highlightWindows: highlightWindows.checked
    property alias cfg_fill: fill.checked
    property int cfg_iconSpacing
    property alias cfg_indicateAudioStreams: indicateAudioStreams.checked
    property alias cfg_interactiveMute: interactiveMute.checked
    property alias cfg_tooltipControls: tooltipControls.checked
    property alias cfg_maxStripes: maxStripes.value

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showToolTips
            Kirigami.FormData.label: i18ndc(page.domain, "@label for several checkboxes", "General:")
            text: i18ndc(page.domain, "@option:check section General", "Show small window previews when hovering over tasks")
        }
        QQC2.CheckBox {
            id: highlightWindows
            enabled: showToolTips.checked
            text: i18ndc(page.domain, "@option:check section General", "Hide other windows when hovering over previews")
        }
        QQC2.CheckBox {
            id: indicateAudioStreams
            text: i18ndc(page.domain, "@option:check section General", "Show an indicator when a task is playing audio")
        }
        QQC2.CheckBox {
            id: interactiveMute
            enabled: indicateAudioStreams.checked
            text: i18ndc(page.domain, "@option:check section General", "Mute task when clicking indicator")
        }
        QQC2.CheckBox {
            id: tooltipControls
            text: i18ndc(page.domain, "@option:check section General", "Show media and volume controls in tooltip")
        }
        QQC2.CheckBox {
            id: fill
            text: i18ndc(page.domain, "@option:check section General", "Fill free space on panel")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.SpinBox {
            id: maxStripes
            Kirigami.FormData.label: page.vertical
                ? i18ndc(page.domain, "@label:spinbox maximum number of columns for tasks", "Maximum columns:")
                : i18ndc(page.domain, "@label:spinbox maximum number of rows for tasks", "Maximum rows:")
            from: 1
            to: 4
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18ndc(page.domain, "@label:listbox", "Spacing between icons:")
            textRole: "label"
            valueRole: "spacing"
            model: [
                { "label": i18ndc(page.domain, "@item:inlistbox Icon spacing", "Small"), "spacing": 0 },
                { "label": i18ndc(page.domain, "@item:inlistbox Icon spacing", "Normal"), "spacing": 2 },
                { "label": i18ndc(page.domain, "@item:inlistbox Icon spacing", "Large"), "spacing": 6 },
            ]
            onActivated: page.cfg_iconSpacing = currentValue
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_iconSpacing)
        }
    }
}
