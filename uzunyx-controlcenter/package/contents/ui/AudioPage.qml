/*
 * Which device plays and which one records, and the microphone's volume.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.volume as PlasmaPa

DetailPage {
    id: page

    readonly property var source: PlasmaPa.PreferredDevice.source
    readonly property int normalVolume: PlasmaPa.PulseAudio.NormalVolume

    title: i18n("Sound")

    PlasmaComponents.Label {
        text: i18n("Output")
        font.weight: Font.DemiBold
    }
    Repeater {
        model: PlasmaPa.SinkModel {}
        delegate: ListRow {
            required property var model
            iconSource: "audio-speakers-symbolic"
            title: model.Description
            current: model.PulseObject.default
            onClicked: model.PulseObject.default = true
        }
    }

    PlasmaComponents.Label {
        Layout.topMargin: Kirigami.Units.smallSpacing
        text: i18n("Input")
        font.weight: Font.DemiBold
    }
    Repeater {
        id: inputs
        model: PlasmaPa.SourceModel {}
        delegate: ListRow {
            required property var model
            iconSource: "audio-input-microphone-symbolic"
            title: model.Description
            current: model.PulseObject.default
            onClicked: model.PulseObject.default = true
        }
    }
    PlasmaComponents.Label {
        visible: inputs.count === 0
        text: i18n("No input devices")
        opacity: 0.8
    }
    RowLayout {
        visible: page.source !== null
        Layout.fillWidth: true
        PlasmaComponents.ToolButton {
            icon.name: page.source && page.source.muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"
            onClicked: page.source.muted = !page.source.muted
        }
        GlassSlider {
            Layout.fillWidth: true
            from: 0
            to: page.normalVolume
            stepSize: page.normalVolume / 100
            value: page.source ? page.source.volume : 0
            onMoved: page.source.volume = value
        }
        PlasmaComponents.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            horizontalAlignment: Text.AlignRight
            text: page.source ? Math.round(page.source.volume / page.normalVolume * 100) + "%" : ""
        }
    }
}
