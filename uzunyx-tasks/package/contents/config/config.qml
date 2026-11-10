import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    readonly property string domain: "plasma_applet_org.kde.plasma.taskmanager"

    ConfigCategory {
        name: i18ndc(domain, "@title:group for configuration dialog page", "Appearance")
        icon: "preferences-desktop-color"
        source: "ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18ndc(domain, "@title:group for configuration dialog page", "Behavior")
        icon: "preferences-desktop"
        source: "ConfigBehavior.qml"
    }
}
