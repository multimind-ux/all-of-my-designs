import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// Compact now-playing block for the island: art, title/artist, and four
// activity bars and previous/play-pause/next controls driven by MPRIS.
Item {
    id: root

    property var colors

    readonly property var player: Mpris.players.values.find(function (p) { return p.isPlaying })
        || Mpris.players.values[0] || null
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: hasPlayer ? String(player.trackArtUrl || "") : ""

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 34

    property var levels: [4, 4, 4, 4]
    property int tick: 0

    Timer {
        interval: 130
        running: root.isPlaying
        repeat: true
        onTriggered: {
            root.tick++
            const t = root.tick
            root.levels = [
                4 + (Math.sin(t * 0.9) * 0.5 + 0.5) * 10,
                4 + (Math.sin(t * 1.3 + 1.7) * 0.5 + 0.5) * 10,
                4 + (Math.sin(t * 0.7 + 3.1) * 0.5 + 0.5) * 10,
                4 + (Math.sin(t * 1.7 + 0.6) * 0.5 + 0.5) * 10
            ]
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            width: 28
            height: 28
            radius: 6
            color: root.colors.alpha(root.colors.surface, 0.5)
            border.width: 1
            border.color: root.colors.alpha(root.colors.outline, 0.18)
            clip: true

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !root.hasPlayer || root.artUrl === ""
                text: ""
                color: root.colors.primary
                font.family: root.colors.fontSans
                font.pixelSize: 12
            }
        }

        ColumnLayout {
            Layout.maximumWidth: 132
            spacing: 0
            Text {
                text: root.hasPlayer ? String(root.player.trackTitle || "Unknown") : "Nothing playing"
                color: root.hasPlayer ? root.colors.foreground : root.colors.alpha(root.colors.foreground, 0.5)
                font.family: root.colors.fontSans
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.italic: !root.hasPlayer
                elide: Text.ElideRight
                Layout.maximumWidth: 132
            }
            Text {
                text: root.hasPlayer ? String(root.player.trackArtist || "Unknown artist") : "—"
                color: root.colors.alpha(root.colors.foreground, 0.55)
                font.family: root.colors.fontSans
                font.pixelSize: 8
                elide: Text.ElideRight
                Layout.maximumWidth: 132
                visible: root.hasPlayer
            }
        }

        Row {
            id: visRow
            spacing: 2
            readonly property var barColors: [root.colors.primary, root.colors.secondary, root.colors.tertiary, root.colors.primary]
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 2
                    radius: 1
                    height: root.levels[index] || 4
                    color: visRow.barColors[index % visRow.barColors.length]
                    opacity: root.isPlaying ? 0.9 : 0.3
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }
        }
            Row {
            id: controls
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: prevArea.containsMouse
                    ? root.colors.alpha(root.colors.primary, 0.22)
                    : root.colors.alpha(root.colors.surfaceVariant, 0.55)
                border.width: 1
                border.color: root.colors.alpha(root.colors.outline, 0.35)
                opacity: root.hasPlayer && root.player.canGoPrevious ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: root.colors.foreground
                    font.family: root.colors.fontSans
                    font.pixelSize: 11
                }
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.hasPlayer && root.player.canGoPrevious
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.hasPlayer && root.player.canGoPrevious)
                            root.player.previous()
                    }
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: playArea.containsMouse
                    ? root.colors.alpha(root.colors.primary, 0.30)
                    : root.colors.alpha(root.colors.primary, 0.14)
                border.width: 1
                border.color: root.colors.alpha(root.colors.primary, 0.35)
                opacity: root.hasPlayer && root.player.canTogglePlaying ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "" : ""
                    color: root.colors.foreground
                    font.family: root.colors.fontSans
                    font.pixelSize: 11
                }
                MouseArea {
                    id: playArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.hasPlayer && root.player.canTogglePlaying
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.hasPlayer && root.player.canTogglePlaying)
                            root.player.togglePlaying()
                    }
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: nextArea.containsMouse
                    ? root.colors.alpha(root.colors.primary, 0.22)
                    : root.colors.alpha(root.colors.surfaceVariant, 0.55)
                border.width: 1
                border.color: root.colors.alpha(root.colors.outline, 0.35)
                opacity: root.hasPlayer && root.player.canGoNext ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: root.colors.foreground
                    font.family: root.colors.fontSans
                    font.pixelSize: 11
                }
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.hasPlayer && root.player.canGoNext
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.hasPlayer && root.player.canGoNext)
                            root.player.next()
                    }
                }
            }
        }
    }
}
