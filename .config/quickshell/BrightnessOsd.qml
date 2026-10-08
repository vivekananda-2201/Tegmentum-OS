import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root

    function updateScreen() {
        var mon = Hyprland.focusedMonitor
        if (mon) {
            var scr = Quickshell.screens.find(function (s) { return s.name === mon.name })
            if (scr) {
                root.screen = scr
                return
            }
        }
        if (Quickshell.screens.length > 0) {
            root.screen = Quickshell.screens[0]
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (!Quickshell.screens.includes(root.screen)) {
                root.updateScreen()
            }
        }
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 150
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only capture input when OSD is visible and over the flyout capsule
    mask: Region {
        item: root.showing ? flyout : null
    }

    // -------------------------
    // Brightness state
    // -------------------------

    property real brightness: 0.2 // normalized 0.0 to 1.0
    property bool showing: false
    property bool hovered: flyoutArea.containsMouse

    function showOsd() {
        updateScreen()
        showing = true
        hideTimer.restart()
    }

    function triggerOsd() {
        brightnessGet.running = true
        showOsd()
    }

    function setPercentage(val) {
        var num = parseInt(val)
        if (!isNaN(num)) {
            root.brightness = Math.min(Math.max(num / 100.0, 0.0), 1.0)
            root.showOsd()
        } else {
            root.triggerOsd()
        }
    }

    // Read initial / current brightness from brightnessctl
    Process {
        id: brightnessGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3])
                    if (!isNaN(pct)) {
                        root.brightness = Math.min(Math.max(pct / 100.0, 0.0), 1.0)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        root.updateScreen()
        brightnessGet.running = true
    }

    // -------------------------
    // IPC Entrypoint
    //   qs ipc call brightness notify "$pct"
    // -------------------------

    IpcHandler {
        target: "brightness"

        function notify(pct: string): void {
            root.setPercentage(pct)
        }

        function refresh(): void {
            root.triggerOsd()
        }
    }

    // -------------------------
    // Auto-hide Timer
    // -------------------------

    Timer {
        id: hideTimer

        interval: 1200
        repeat: false

        onTriggered: {
            // Stay open while the pointer is over the OSD
            if (root.hovered) {
                hideTimer.restart()
                return
            }
            root.showing = false
        }
    }

    // -------------------------
    // BRIGHTNESS OSD
    // Exact match with VolumeOsd capsule
    // -------------------------

    Rectangle {
        id: flyout

        property bool open: root.showing

        width: 320
        height: 28

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30

        radius: 36
        color: Theme.alpha(Theme.bg, 0.5)

        opacity: open ? 1 : 0
        scale: open ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        // Hover keeps the OSD open
        MouseArea {
            id: flyoutArea

            anchors.fill: parent
            hoverEnabled: true
            enabled: flyout.open
        }

        // Brightness Icon
        Text {
            id: icon

            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter

            text: {
                if (root.brightness <= 0)
                    return "󰃝"
                if (root.brightness <= 0.25)
                    return "󰃞"
                if (root.brightness <= 0.65)
                    return "󰃟"
                return "󰃠"
            }

            font.family: "Symbols Nerd Font"
            font.pixelSize: 20

            color: Theme.text
        }

        // Percentage text
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter

            text: Math.round(root.brightness * 100) + "%"

            font.pixelSize: 12
            font.bold: true

            color: Theme.text
        }

        // Track & Progress bar
        Rectangle {
            anchors.left: icon.right
            anchors.leftMargin: 15

            anchors.right: parent.right
            anchors.rightMargin: 68

            anchors.verticalCenter: parent.verticalCenter

            height: 5
            radius: 4

            color: "#555555"

            Rectangle {
                width: parent.width * Math.min(Math.max(root.brightness, 0), 1)

                height: parent.height
                radius: 4

                color: Theme.text

                Behavior on width {
                    NumberAnimation { duration: 100 }
                }
            }
        }
    }
}
