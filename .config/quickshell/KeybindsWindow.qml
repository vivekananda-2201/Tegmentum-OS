import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: root
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: root.showing ? backdrop : null
    }

    property bool showing: false
    function show()   { showing = true }
    function hide()   { showing = false }
    function toggle() { showing = !showing }

    readonly property real cardWidth: 750
    readonly property real cardHeight: 600
    readonly property real cardX: (root.width - cardWidth) / 2
    readonly property real cardY: (root.height - cardHeight) / 2

    property string searchQuery: ""
    property int selectedIndex: 0
    property bool locked: false
    property real lockedRowOpacity: 1.0

    onShowingChanged: {
        if (showing) {
            dismissTimer.stop()
            fadeRowAnim.stop()
            root.locked = false
            root.lockedRowOpacity = 1.0
            root.searchQuery = ""
            if (searchInput) {
                searchInput.text = ""
                searchInput.forceActiveFocus()
            }
            root.selectedIndex = 0
            if (keybindList) {
                keybindList.positionViewAtIndex(0, ListView.Beginning)
            }
        } else {
            dismissTimer.stop()
            fadeRowAnim.stop()
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void { root.toggle() }
        function show(): void   { root.show() }
        function hide(): void   { root.hide() }
        function select(): void { root.lockAndDismiss() }
    }

    // Dismiss timer for locked row: stays for 1 second, then fades away
    Timer {
        id: dismissTimer
        interval: 1000
        repeat: false
        onTriggered: {
            fadeRowAnim.restart()
        }
    }

    NumberAnimation {
        id: fadeRowAnim
        target: root
        property: "lockedRowOpacity"
        from: 1.0
        to: 0.0
        duration: 350
        easing.type: Easing.OutCubic
        onFinished: {
            root.hide()
        }
    }

    function lockAndDismiss() {
        if (root.filteredItems.length === 0 || root.locked) return
        var idx = Math.max(0, Math.min(root.selectedIndex, root.filteredItems.length - 1))
        root.selectedIndex = idx
        root.locked = true
        root.lockedRowOpacity = 1.0
        dismissTimer.restart()
    }

    // Comprehensive Keybindings Database
    readonly property var allKeybinds: [
        // Launchers & Essentials
        { keys: "SUPER + RETURN", desc: "Open terminal (kitty)", category: "Launchers" },
        { keys: "SUPER + CTRL + RETURN", desc: "Open floating terminal", category: "Launchers" },
        { keys: "SUPER + SPACE", desc: "Application launcher (rofi)", category: "Launchers" },
        { keys: "SUPER + E", desc: "Open file manager (nautilus)", category: "Launchers" },
        { keys: "SUPER + B", desc: "Hide / unhide floating windows", category: "Windows" },
        { keys: "SUPER + W", desc: "Close focused window", category: "Windows" },
        { keys: "SUPER + F", desc: "Toggle window fullscreen", category: "Windows" },
        { keys: "SUPER + ALT + F", desc: "Toggle float, center & resize (70%)", category: "Windows" },
        { keys: "SUPER + O", desc: "Toggle window opacity", category: "Windows" },
        { keys: "SUPER + S", desc: "Toggle workspace layout (dwindle / scrolling)", category: "Workspaces" },

        // System & Control
        { keys: "SUPER + TAB", desc: "Lock screen (hyprlock)", category: "System" },
        { keys: "SUPER + `", desc: "Power menu (rofi powermenu)", category: "System" },
        { keys: "SUPER + I", desc: "Toggle quickshell settings", category: "System" },
        { keys: "SUPER + K", desc: "Keybindings cheatsheet & search", category: "System" },
        { keys: "SUPER + SHIFT + W", desc: "Wallpaper switcher (hyprquickpaper)", category: "System" },
        { keys: "SUPER + SHIFT + SPACE", desc: "Toggle top bar (waybar)", category: "System" },
        { keys: "SUPER + V", desc: "Clipboard manager (cliphist / rofi)", category: "System" },
        { keys: "SUPER + X", desc: "Switch keyboard layout", category: "System" },
        { keys: "SUPER + R", desc: "Toggle GPU screen recorder", category: "Media" },
        { keys: "SUPER + SHIFT + E", desc: "Exit Hyprland session", category: "System" },

        // Screenshots
        { keys: "Print", desc: "Screenshot fullscreen (grim & copy)", category: "Screenshot" },
        { keys: "SHIFT + Print", desc: "Screenshot area select (slurp)", category: "Screenshot" },

        // Window Focus & Navigation
        { keys: "ALT + TAB", desc: "Cycle focus to next window", category: "Navigation" },
        { keys: "ALT + SHIFT + TAB", desc: "Cycle focus to previous window", category: "Navigation" },
        { keys: "ALT + `", desc: "Cycle next floating window", category: "Navigation" },
        { keys: "ALT + SHIFT + `", desc: "Cycle previous floating window", category: "Navigation" },
        { keys: "ALT + F", desc: "Focus and raise floating window", category: "Navigation" },
        { keys: "SUPER + H", desc: "Focus window left (vim-style)", category: "Navigation" },
        { keys: "SUPER + J", desc: "Focus window down (vim-style)", category: "Navigation" },
        { keys: "SUPER + Up", desc: "Focus window up", category: "Navigation" },
        { keys: "SUPER + L", desc: "Focus window right (vim-style)", category: "Navigation" },

        // Window Moving & Sizing
        { keys: "SUPER + SHIFT + H / J / K / L", desc: "Move window left / down / up / right", category: "Windows" },
        { keys: "SUPER + CTRL + H / J / K / L", desc: "Resize active window (40px delta)", category: "Windows" },
        { keys: "SUPER + ALT + CTRL + Arrows/HJKL", desc: "Move floating window (40px step)", category: "Windows" },
        { keys: "SUPER + Mouse Left Drag", desc: "Move window with mouse cursor", category: "Mouse" },
        { keys: "SUPER + Mouse Right Drag", desc: "Resize window with mouse cursor", category: "Mouse" },
        { keys: "SUPER + Scroll Up / Down", desc: "Zoom desktop in / out", category: "System" },

        // Workspaces
        { keys: "SUPER + 1 .. 0", desc: "Switch to workspace 1 to 10", category: "Workspaces" },
        { keys: "SUPER + SHIFT + 1 .. 0", desc: "Move window to workspace 1 to 10", category: "Workspaces" },

        // Audio & Hardware Keys
        { keys: "XF86AudioRaiseVolume", desc: "Volume up (+5%)", category: "Media" },
        { keys: "XF86AudioLowerVolume", desc: "Volume down (-5%)", category: "Media" },
        { keys: "XF86AudioMute", desc: "Toggle mute audio sink", category: "Media" },
        { keys: "XF86AudioPlay", desc: "Media play / pause (playerctl)", category: "Media" },
        { keys: "XF86AudioNext", desc: "Media next track", category: "Media" },
        { keys: "XF86AudioPrev", desc: "Media previous track", category: "Media" },
        { keys: "XF86MonBrightnessUp", desc: "Brightness up (+5%, fine +1% <10%)", category: "Hardware" },
        { keys: "XF86MonBrightnessDown", desc: "Brightness down (-5%, fine -1% <10%)", category: "Hardware" }
    ]

    readonly property var filteredItems: {
        if (!searchQuery || searchQuery.trim() === "") {
            return allKeybinds
        }
        var q = searchQuery.trim().toLowerCase()
        var terms = q.split(/\s+/)
        var res = []
        for (var i = 0; i < allKeybinds.length; i++) {
            var item = allKeybinds[i]
            var target = (item.keys + " " + item.desc + " " + item.category).toLowerCase()
            var match = true
            for (var t = 0; t < terms.length; t++) {
                if (target.indexOf(terms[t]) === -1) {
                    match = false
                    break
                }
            }
            if (match) {
                res.push(item)
            }
        }
        return res
    }

    // Backdrop for click-outside dismissal
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }
    }

    PerspectivePanel {
        id: card
        x: root.cardX
        y: root.cardY
        width: root.cardWidth
        height: root.cardHeight
        open: root.showing

        Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (searchInput) searchInput.forceActiveFocus()
            }
        }

        // Main card frame matching SettingsWindow aesthetic (vanishes on lock)
        Rectangle {
            id: cardFrame
            anchors.fill: parent
            color: Theme.bg
            radius: Theme.radius
            border.color: Theme.accent
            border.width: 1
            opacity: root.locked ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            // Cyber accent corner brackets (Top-Left)
            Rectangle {
                width: 40; height: 2; color: Theme.accent2
                anchors { top: parent.top; left: parent.left; margins: 14 }
            }
            Rectangle {
                width: 2; height: 40; color: Theme.accent2
                anchors { top: parent.top; left: parent.left; margins: 14 }
            }

            // Cyber accent corner brackets (Bottom-Right)
            Rectangle {
                width: 40; height: 2; color: Theme.accent2
                anchors { bottom: parent.bottom; right: parent.right; margins: 14 }
            }
            Rectangle {
                width: 2; height: 40; color: Theme.accent2
                anchors { bottom: parent.bottom; right: parent.right; margins: 14 }
            }

            // Top handle pill
            Rectangle {
                id: positionHandle
                width: 150
                height: 16
                radius: Theme.radius
                color: Theme.bg
                border.color: Theme.accent
                border.width: 1
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: -8
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    Text { text: "●"; font.family: Theme.fontFamily; font.pixelSize: 8; color: Theme.textDim }
                    Text { text: "●"; font.family: Theme.fontFamily; font.pixelSize: 8; color: Theme.textDim }
                    Text { text: "●"; font.family: Theme.fontFamily; font.pixelSize: 8; color: Theme.textDim }
                }
            }

            // Close button (top right)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: closeMouse.containsMouse ? Theme.alpha(Theme.danger, 0.25) : "transparent"
                border.color: closeMouse.containsMouse ? Theme.danger : "transparent"
                border.width: 1
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 16
                }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: closeMouse.containsMouse ? Theme.danger : Theme.textDim
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hide()
                }
            }
        }

        // Card Inner Content (margins: 28)
        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            // Top Header Row: Title & Navigation hint (vanishes on lock)
            Item {
                width: parent.width
                height: 28
                opacity: root.locked ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌌  KEYBINDINGS"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    font.letterSpacing: 3
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "[↑↓] Navigate · [Enter] Select · [Esc] Close"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            // Search Bar (Keyboard-centric: automatically receives all typing, vanishes on lock)
            Rectangle {
                id: searchBox
                width: parent.width
                height: 40
                radius: Theme.radius
                color: Theme.bgCard
                border.color: (searchInput.activeFocus || root.searchQuery.length > 0) ? Theme.accent2 : Theme.border
                border.width: 1
                opacity: root.locked ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        font.family: Theme.iconFont
                        font.pixelSize: 14
                        color: (root.searchQuery.length > 0) ? Theme.accent2 : Theme.textDim
                    }

                    Item {
                        height: parent.height
                        width: parent.width - 24 - (root.searchQuery.length > 0 ? (badgeBox.width + 10) : 0)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Type anywhere to search keybindings..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textFaint
                            visible: searchInput.text.length === 0
                        }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.text
                            clip: true
                            selectByMouse: true
                            cursorVisible: root.showing && !root.locked
                            focus: root.showing && !root.locked

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Down) {
                                    if (root.filteredItems.length > 0) {
                                        root.selectedIndex = (root.selectedIndex + 1) % root.filteredItems.length
                                        keybindList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    if (root.filteredItems.length > 0) {
                                        root.selectedIndex = (root.selectedIndex - 1 + root.filteredItems.length) % root.filteredItems.length
                                        keybindList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_PageDown) {
                                    if (root.filteredItems.length > 0) {
                                        root.selectedIndex = Math.min(root.filteredItems.length - 1, root.selectedIndex + 8)
                                        keybindList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_PageUp) {
                                    if (root.filteredItems.length > 0) {
                                        root.selectedIndex = Math.max(0, root.selectedIndex - 8)
                                        keybindList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.lockAndDismiss()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    if (root.locked) {
                                        dismissTimer.stop()
                                        fadeRowAnim.stop()
                                        root.hide()
                                    } else if (searchInput.text.length > 0) {
                                        searchInput.text = ""
                                    } else {
                                        root.hide()
                                    }
                                    event.accepted = true
                                }
                            }

                            onTextChanged: {
                                root.searchQuery = text
                                root.selectedIndex = 0
                                if (keybindList) keybindList.positionViewAtIndex(0, ListView.Beginning)
                            }
                        }
                    }

                    // Badge & Clear button
                    Row {
                        id: badgeBox
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        visible: root.searchQuery.length > 0

                        Rectangle {
                            height: 22
                            width: matchCountText.implicitWidth + 14
                            radius: 4
                            color: Theme.alpha(Theme.accent2, 0.15)
                            border.color: Theme.accent2
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: matchCountText
                                anchors.centerIn: parent
                                text: root.filteredItems.length + " match" + (root.filteredItems.length === 1 ? "" : "es")
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accent2
                            }
                        }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: clearMouse.containsMouse ? Theme.alpha(Theme.accent2, 0.3) : Theme.bg
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.text
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            // Two Columns Header Row: Left = KEYBIND, Right = DESCRIPTION (vanishes on lock)
            Rectangle {
                width: parent.width
                height: 26
                color: "transparent"
                opacity: root.locked ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 16

                    Text {
                        width: 280
                        text: "KEYBIND"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                        color: Theme.accent2
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 296
                        text: "DESCRIPTION"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                        color: Theme.accent2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
            }

            // Main Content Area: Keybinds List
            Item {
                width: parent.width
                height: parent.height - 146
                clip: true

                ListView {
                    id: keybindList
                    anchors.fill: parent
                    model: root.filteredItems
                    currentIndex: root.selectedIndex
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: root.locked ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
                        width: 5
                        background: Rectangle {
                            color: Theme.alpha(Theme.border, 0.3)
                            radius: 3
                        }
                        contentItem: Rectangle {
                            color: Theme.accent
                            radius: 3
                        }
                    }

                    delegate: Rectangle {
                        id: rowDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.selectedIndex

                        width: keybindList.width - (vbar.visible ? 8 : 0)
                        height: 38
                        radius: 6
                        color: (root.locked && isSelected) ? Theme.bgPanel : (isSelected ? Theme.alpha(Theme.accent2, 0.15) : ((index % 2 === 1) ? Theme.alpha(Theme.bgCard, 0.35) : "transparent"))
                        border.color: isSelected ? Theme.accent2 : "transparent"
                        border.width: 1

                        // On lock: all other rows vanish to 0 opacity; selected row stays at lockedRowOpacity
                        opacity: isSelected ? (root.locked ? root.lockedRowOpacity : 1.0) : (root.locked ? 0.0 : 1.0)

                        Behavior on opacity {
                            enabled: !root.locked
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 16

                            // Left Column: Keybind badge
                            Item {
                                width: 280
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    height: 26
                                    width: Math.min(270, keyLabel.implicitWidth + 18)
                                    radius: 5
                                    color: rowDelegate.isSelected ? Theme.alpha(Theme.accent2, 0.25) : Theme.bgCard
                                    border.color: rowDelegate.isSelected ? Theme.accent2 : Theme.borderAccent
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: keyLabel
                                        anchors.centerIn: parent
                                        text: rowDelegate.modelData.keys
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: rowDelegate.isSelected ? Theme.accent2 : Theme.text
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Right Column: Description + Category
                            Item {
                                width: parent.width - 296
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    anchors.fill: parent
                                    spacing: 10

                                    Text {
                                        width: parent.width - (catText.implicitWidth + 10)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: rowDelegate.modelData.desc
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: rowDelegate.isSelected ? Theme.text : Theme.textDim
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: catText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: rowDelegate.modelData.category
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.textFaint
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.locked
                            onEntered: {
                                if (!root.locked) {
                                    root.selectedIndex = rowDelegate.index
                                }
                            }
                            onClicked: {
                                root.selectedIndex = rowDelegate.index
                                root.lockAndDismiss()
                            }
                        }
                    }

                    // Empty State if no matches
                    Item {
                        anchors.fill: parent
                        visible: root.filteredItems.length === 0 && !root.locked

                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰮗"
                                font.family: Theme.iconFont
                                font.pixelSize: 32
                                color: Theme.textFaint
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No keybindings found matching \"" + root.searchQuery + "\""
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.textDim
                            }
                        }
                    }
                }
            }
        }
    }
}
