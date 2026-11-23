import Quickshell
import Quickshell.Io
import QtQuick
import "." as LockUi

// Standalone wrapper for the uthman_dotfiles lockscreen stack. It runs beside
// Caelestia; `ipc call lockscreen lock` engages the session lock.
ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string notifPath: home + "/.local/state/caelestia/notifs.json"

    property var notifications: []

    Colors {
        id: palette
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            notifFile.path = ""
            notifFile.path = root.notifPath
        }
    }

    FileView {
        id: notifFile
        path: root.notifPath
        printErrors: false

        onLoaded: {
            var raw = []
            try { raw = JSON.parse(text()) || [] } catch (e) { return }
            raw.sort(function (a, b) {
                return String(b.time || "").localeCompare(String(a.time || ""))
            })

            var out = []
            for (var i = 0; i < Math.min(raw.length, 5); i++) {
                var n = raw[i]
                var stamp = String(n.time || "")
                var d = stamp ? new Date(stamp) : null
                out.push({
                    appName: String(n.appName || "app"),
                    summary: String(n.summary || n.body || ""),
                    body: String(n.body || ""),
                    time: d ? Qt.formatTime(d, "hh:mm") : "",
                    urgent: Number(n.urgency || 0) >= 2
                })
            }
            root.notifications = out
        }
    }

    LockUi.LockScreen {
        palette: palette
        notifications: root.notifications
    }
}
