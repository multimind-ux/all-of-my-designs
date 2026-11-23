import Quickshell
import Quickshell.Io
import QtQuick
import "components"
import "modules"

// Standalone Wi-Fi panel with live throughput, network list and speedtest.
// Runs alongside Caelestia: qs -c wifi-panel -n -d
ShellRoot {
    id: root

    Colors {
        id: palette
    }

    // Keep the panel palette in sync with Caelestia's wallpaper-derived scheme.
    Process {
        id: themeSync
        command: ["sh", "-c", "$HOME/.local/bin/sync-caelestia-colors"]
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: themeSync.running = true
    }

    PassPrompt {
        colors: palette
    }

    WifiPanel {
        id: wifi
        colors: palette
    }

    IpcHandler {
        target: "wifi"

        function toggle(): void {
            wifi.open = !wifi.open
        }

        function show(): void {
            wifi.open = true
        }

        function hide(): void {
            wifi.open = false
        }
    }
}
