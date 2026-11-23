import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "components"

// Dynamic island — always-on top-center capsule with the PixelBot head,
// now playing, live stats, clock/date, and notification expansion.
// Notifications come from Caelestia's persisted notifs.json (no second daemon).
ShellRoot {
    id: root

    property string appName: ""
    property string summary: ""
    property string body: ""
    property string lastTime: ""
    property bool primed: false
    property bool open: false

    property string clockTime: ""
    property string clockDate: ""

    readonly property string storePath: Quickshell.env("HOME") +
        "/.local/state/caelestia/notifs.json"

    // Fixed dark palette — the island no longer follows the wallpaper scheme.
    // The top 18px of the capsule is clipped off-screen so only the rounded
    // bottom corners show, making it look attached to the top bar.
    readonly property int topClip: 18

    QtObject {
        id: palette

        property color background: "#0a0a0c"
        property color foreground: "#f2f2f5"
        property color primary: "#c9c9d1"
        property color secondary: "#9a9aa6"
        property color tertiary: "#7c7c88"
        property color error: "#ff6b6b"
        property color surface: "#121216"
        property color on_surface: "#f2f2f5"
        property color surfaceVariant: "#24242b"
        property color outline: "#3a3a44"

        readonly property string fontSans: "FiraCode Nerd Font"
        readonly property string fontHeading: "FiraCode Nerd Font"

        function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    }

    NetRate {
        id: net
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const d = new Date()
            root.clockTime = Qt.formatTime(d, "hh:mm")
            root.clockDate = Qt.formatDate(d, "ddd dd MMM")
        }
    }

    // ---------- notifications ----------
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            nfile.path = ""
            nfile.path = root.storePath
        }
    }

    FileView {
        id: nfile
        path: root.storePath
        printErrors: false

        onLoaded: {
            var list = []
            try { list = JSON.parse(text()) || [] } catch (e) { return }
            if (!list.length) return

            list.sort(function (a, b) { return String(b.time).localeCompare(String(a.time)) })
            var latest = list[0]
            var stamp = String(latest.time || "")

            if (!root.primed) {
                root.primed = true
                root.lastTime = stamp
                return
            }
            if (stamp === root.lastTime) return

            root.lastTime = stamp
            root.appName = String(latest.appName || "Notification")
            root.summary = String(latest.summary || "")
            root.body = String(latest.body || "").replace(/<[^>]*>/g, "")
            root.open = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: root.open = false
    }

    function reveal(): void {
        root.open = true
        hideTimer.restart()
    }

    IpcHandler {
        target: "island"
        function reveal(): void { root.reveal() }
        function dismiss(): void { root.open = false }
        function toggle(): void { root.open ? root.open = false : root.reveal() }
        function state(): string {
            return "open=" + root.open
                + " width=" + Math.round(capsule.width)
                + " height=" + Math.round(capsule.height - root.topClip)
        }
        function botStatus(): string { return bot.status() }
    }

    // ---------- window ----------
    PanelWindow {
        anchors { top: true; left: true; right: true }
        margins { top: -10; left: -60; right: -10 }
        implicitHeight: 72
        // Reserve a top strip so windows (browser, terminal, etc.) start
        // below the island instead of underneath it.
        exclusiveZone: 64
        color: "transparent"
        WlrLayershell.namespace: "qs-notif-island"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        visible: true

        mask: Region { item: capsule }

        Rectangle {
            id: capsule
            anchors {
                top: parent.top
                topMargin: -root.topClip
                horizontalCenter: parent.horizontalCenter
            }
            width: root.open ? 880 : Math.min(680, Math.max(520, topRow.implicitWidth + 36))
            height: 72
            radius: 26
            color: "#101014"
            border.width: 1
            border.color: "#2a2a31"
            scale: 1

            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                z: 0
                cursorShape: root.open ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.open = false
            }

            RowLayout {
                id: topRow
                z: 1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 12
                    rightMargin: 12
                    topMargin: 8
                    bottomMargin: 8
                }
                spacing: 10

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: palette.alpha(palette.primary, 0.12)
                    Layout.alignment: Qt.AlignVCenter

                    PixelBot {
                        id: bot
                        anchors.centerIn: parent
                        colors: palette
                        pixelScale: 2
                        roamWidth: 16
                        registerIpc: true
                        moodSounds: true
                    }
                }

                Rectangle {
                    width: 1
                    height: 26
                    color: palette.alpha(palette.outline, 0.25)
                    Layout.alignment: Qt.AlignVCenter
                }

                NowPlayingMini {
                    colors: palette
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: 210
                }

                Rectangle {
                    width: 1
                    height: 26
                    color: palette.alpha(palette.outline, 0.25)
                    Layout.alignment: Qt.AlignVCenter
                }

                RowLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "CPU " + Math.round(bot.cpu) + "%"
                        color: palette.alpha(palette.foreground, 0.78)
                        font.family: palette.fontSans
                        font.pixelSize: 9
                    }
                    Text {
                        text: "NET " + net.fmt(net.rxKbs + net.txKbs)
                        color: palette.alpha(palette.foreground, 0.78)
                        font.family: palette.fontSans
                        font.pixelSize: 9
                    }
                    Text {
                        text: "BAT " + Math.round(bot.battery) + "%"
                        color: palette.alpha(palette.foreground, 0.78)
                        font.family: palette.fontSans
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    width: 1
                    height: 26
                    color: palette.alpha(palette.outline, 0.25)
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: root.clockTime
                        color: palette.foreground
                        font.family: palette.fontSans
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.clockDate
                        color: palette.alpha(palette.foreground, 0.55)
                        font.family: palette.fontSans
                        font.pixelSize: 8
                    }
                }
            }

            // Notification replaces the right-hand content inside the same
            // 54px bar slice — no downward growth into the workspace.
            Rectangle {
                id: notificationRow
                visible: root.open
                z: 2
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    leftMargin: 62
                    rightMargin: 12
                    topMargin: 8
                    bottomMargin: 8
                }
                radius: 18
                color: "#101014"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        width: 3
                        height: 28
                        radius: 2
                        color: palette.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: root.appName
                                color: palette.primary
                                font.family: palette.fontSans
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                text: root.summary
                                color: palette.foreground
                                font.family: palette.fontSans
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: root.body
                            color: palette.alpha(palette.foreground, 0.72)
                            font.family: palette.fontSans
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                }
            }
        }
    }
}
