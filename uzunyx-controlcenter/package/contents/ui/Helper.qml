/*
 * Runs uzunyx-controlcenter-helper, which answers in JSON.
 */
import QtQuick
import org.kde.plasma.plasma5support as P5Support

P5Support.DataSource {
    id: helper

    readonly property string program: "/usr/libexec/uzunyx-controlcenter-helper"
    property var waiting: ({})

    function call(args, callback) {
        const command = program + " " + args.join(" ");
        waiting[command] = callback;
        connectSource(command);
    }

    engine: "executable"
    onNewData: (source, data) => {
        const callback = waiting[source];
        delete waiting[source];
        disconnectSource(source);
        let answer = {};
        try {
            answer = JSON.parse(data.stdout);
        } catch (error) {
            answer = { error: data.stderr || String(error) };
        }
        if (callback) {
            callback(answer.result, answer.error);
        }
    }
}
