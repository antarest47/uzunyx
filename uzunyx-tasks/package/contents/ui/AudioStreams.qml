/*
 * The apps' audio streams, in a file of its own: it's loaded with a Loader, so
 * the task manager still works without plasma-pa.
 */
import QtQuick
import org.kde.plasma.private.volume as PlasmaPa

Item {
    id: audio

    signal streamsChanged()

    readonly property int minimalVolume: PlasmaPa.PulseAudio.MinimalVolume
    readonly property int normalVolume: PlasmaPa.PulseAudio.NormalVolume

    // Once an app's streams are found by process id, the name is no longer used
    // for it: with two instances, only the one playing should show the indicator.
    property var pidMatches: new Set()

    function find(test) {
        const streams = [];
        for (let i = 0; i < instantiator.count; i++) {
            const stream = instantiator.objectAt(i);
            if (stream && test(stream)) {
                streams.push(stream);
            }
        }
        return streams;
    }

    function streamsFor(appId, pid, appName) {
        let streams = find(s => s.portalAppId !== "" && s.portalAppId === appId);
        if (streams.length > 0) {
            return streams;
        }
        streams = find(s => s.pid === pid && s.portalAppId === "");
        if (streams.length > 0) {
            pidMatches.add(appName);
            return streams;
        }
        return pidMatches.has(appName) ? [] : find(s => s.appName === appName);
    }

    Instantiator {
        id: instantiator
        model: PlasmaPa.PulseObjectFilterModel {
            filters: [{ role: "VirtualStream", value: false }]
            sourceModel: PlasmaPa.SinkInputModel {}
        }
        delegate: QtObject {
            required property var model
            readonly property int pid: model.Client?.properties["application.process.id"] ?? 0
            readonly property string appName: model.Client?.properties["application.name"] ?? ""
            readonly property string portalAppId: model.Client?.properties["pipewire.access.portal.app_id"] ?? ""
            readonly property bool muted: model.Muted
            readonly property bool corked: model.Corked
            readonly property int volume: model.Volume

            onMutedChanged: audio.streamsChanged()
            onCorkedChanged: audio.streamsChanged()
        }
        onObjectAdded: audio.streamsChanged()
        onObjectRemoved: audio.streamsChanged()
    }
}
