import Quickshell
import Quickshell.Io
import QtQuick
import "." as ClockUi
import "components" as ClockComponents

// Wallpaper clock wrapper for Caelestia.
// The visual design is the full DesktopClock stack: wallpaper -> frosted time
// -> subject cutout -> date. Wallpaper changes come from Caelestia's path.txt.
ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallListPath: home + "/.local/state/caelestia/wallpaper/path.txt"
    property string lastWallpaper: ""

    ClockComponents.Colors {
        id: palette
    }

    ClockUi.DesktopClock {
        id: desktopClock
        colors: palette
    }

    // Regenerate blur + subject cutout + placement sidecar for a new wallpaper.
    Process {
        id: regen
        command: ["sh", "-c", "\"$HOME/.local/bin/wallcut\" \"$1\"", "sh", root.lastWallpaper]
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wallFile.path = ""
            wallFile.path = root.wallListPath
        }
    }

    FileView {
        id: wallFile
        path: root.wallListPath
        printErrors: false
        onLoaded: {
            const p = text().trim()
            if (!p || p === root.lastWallpaper) return
            root.lastWallpaper = p
            if (!regen.running) regen.running = true
        }
    }

    function regen(): void {
        if (root.lastWallpaper !== "" && !regen.running) regen.running = true
    }

    // Keep the original wallclock IPC commands working alongside the
    // upstream desktopclock target.
    IpcHandler {
        target: "wallclock"
        function toggle(): void { desktopClock.show(!desktopClock.showClock) }
        function reveal(): void { desktopClock.show(true) }
        function conceal(): void { desktopClock.show(false) }
        function regen(): void { root.regen() }
        function state(): string {
            return "enabled=" + desktopClock.showClock
                + " time=" + desktopClock.hh + ":" + desktopClock.mm
                + " layout=" + desktopClock.layout
                + " cutout=" + desktopClock.cutoutExists
                + " blur=" + desktopClock.blurExists
        }
    }
}
