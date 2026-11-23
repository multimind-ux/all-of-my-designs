import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

// WallClock — frosted time/date drawn on the Background layer, above the
// wallpaper but below every window. The digits are masked from a blurred copy
// of the current wallpaper, so they read as glass instead of flat text.
ShellRoot {
    id: root

    property bool enabled: true
    property string lastWallpaper: ""

    // Tall, condensed digits — stretched vertically, never horizontally.
    property real timeScaleX: 1.0
    property real timeScaleY: 1.55

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallListPath: home + "/.local/state/caelestia/wallpaper/path.txt"
    readonly property string blurPath: home + "/.cache/desktopclock/blur.jpg"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string hh: String(clock.hours).padStart(2, "0")
    readonly property string mm: String(clock.minutes).padStart(2, "0")
    readonly property string timeText: hh + ":" + mm

    readonly property string dateText: {
        const d = clock.date
        if (!d) return ""
        return Qt.locale().dayName(d.getDay(), Locale.LongFormat).toUpperCase()
            + "  ·  " + d.getDate() + " " + Qt.locale().monthName(d.getMonth(), Locale.LongFormat).toUpperCase()
            + " " + d.getFullYear()
    }

    // Regenerate the frost texture when the wallpaper changes.
    Process {
        id: regenBlur
        command: ["sh", "-c",
            "mkdir -p \"$HOME/.cache/desktopclock\" && " +
            "if command -v magick >/dev/null 2>&1; then " +
            "  magick \"$HOME/.local/state/caelestia/wallpaper/current\" -auto-orient -resize 25% -blur 0x16 -quality 82 \"$HOME/.cache/desktopclock/blur.jpg\"; " +
            "else " +
            "  convert \"$HOME/.local/state/caelestia/wallpaper/current\" -auto-orient -resize 25% -blur 0x16 -quality 82 \"$HOME/.cache/desktopclock/blur.jpg\"; " +
            "fi"]
        onExited: function (code) {
            if (code !== 0) return
            wallBlur.source = ""
            wallBlur.source = root.blurPath
        }
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
            if (!regenBlur.running) regenBlur.running = true
        }
    }

    function regen(): void {
        if (!regenBlur.running) regenBlur.running = true
    }

    IpcHandler {
        target: "wallclock"
        function toggle(): void { root.enabled = !root.enabled }
        function reveal(): void { root.enabled = true }
        function conceal(): void { root.enabled = false }
        function regen(): void { root.regen() }
        function state(): string {
            return "enabled=" + root.enabled + " time=" + root.timeText
        }
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.enabled
        WlrLayershell.namespace: "qs-wall-clock"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: face
            anchors.centerIn: parent
            width: Math.min(960, parent.width * 0.72)
            height: 400

            // Cutout fill: darkened blurred wallpaper masked into the glyphs,
            // so the time reads as if it sits behind the wallpaper surface.
            Item {
                id: glass
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: maskGlyphs
                }

                Image {
                    id: wallBlur
                    anchors.fill: parent
                    source: root.blurPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: false
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.00; color: Qt.rgba(0.02, 0.04, 0.07, 0.52) }
                        GradientStop { position: 0.55; color: Qt.rgba(0.01, 0.02, 0.04, 0.34) }
                        GradientStop { position: 1.00; color: Qt.rgba(0.04, 0.06, 0.10, 0.48) }
                    }
                }
            }

            // Alpha mask — same geometry/font as the visible glyphs.
            Text {
                id: maskGlyphs
                anchors.fill: parent
                text: root.timeText
                color: "white"
                font.family: "Fira Sans Compressed"
                font.pixelSize: Math.min(260, face.width / 3.8)
                font.weight: Font.Black
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: false
                layer.enabled: true

                transform: Scale {
                    xScale: root.timeScaleX
                    yScale: root.timeScaleY
                }
            }

            // Very faint cool rim — reads as the edge of a cutout, not a glow.
            Text {
                anchors.fill: parent
                text: root.timeText
                color: "transparent"
                font.family: "Fira Sans Compressed"
                font.pixelSize: Math.min(260, face.width / 3.8)
                font.weight: Font.Black
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: Qt.rgba(0.78, 0.86, 1.0, 0.22)

                transform: Scale {
                    xScale: root.timeScaleX
                    yScale: root.timeScaleY
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 42
            }
            text: root.dateText
            color: Qt.rgba(1, 1, 1, 0.72)
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 19
            font.letterSpacing: 3
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
