// Tray.qml — Collapsible Animated System Tray for Tegmentum-OS Bar
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Item {
    id: root

    required property var barWindow
    property bool isRightBarHovered: false
    property int iconYOffset: 0

    property bool expanded: false
    property bool pinned: false

    // Context menu state
    property var contextMenuItem: null
    property var contextMenuModelData: null
    property string contextMenuTitle: ""

    readonly property bool menuOpen: contextMenuItem !== null
    readonly property bool hovered: trayAreaHover.hovered || chevronMa.containsMouse || expanded || pinned || menuOpen
    readonly property int itemCount: SystemTray.items.values ? SystemTray.items.values.length : 0
    readonly property bool hasItems: itemCount > 0
    readonly property bool chevronVisible: (isRightBarHovered || expanded || pinned || menuOpen) && hasItems

    implicitHeight: 18
    implicitWidth: trayRow.implicitWidth
    width: trayRow.implicitWidth
    height: 18

    // Resolve icon path from freedesktop theme, image provider, or filesystem
    function resolveIcon(icon) {
        if (!icon) return "";
        if (icon.startsWith("image://") || icon.startsWith("file://") || icon.startsWith("qrc://")) {
            return icon;
        }
        if (icon.startsWith("/")) {
            return "file://" + icon;
        }
        try {
            const p = Quickshell.iconPath(icon);
            if (p) {
                if (p.startsWith("image://") || p.startsWith("file://")) return p;
                if (p.startsWith("/")) return "file://" + p;
                return p;
            }
        } catch (e) {
            // ignore
        }
        return "image://icon/" + icon;
    }

    // Activate item and focus Hyprland window/workspace (state-aware)
    function activateItem(item) {
        if (!item) return;
        Quickshell.execDetached([
            "python3",
            Quickshell.env("HOME") + "/.config/tegmentum/bin/tray-control.py",
            "activate",
            item.id || "",
            item.title || ""
        ]);
    }

    // Terminate item completely (Quit / Exit)
    function terminateItem(item) {
        if (!item) return;
        Quickshell.execDetached([
            "python3",
            Quickshell.env("HOME") + "/.config/tegmentum/bin/tray-control.py",
            "quit",
            item.id || "",
            item.title || ""
        ]);
    }

    function openContextMenu(delegateItem, modelData) {
        root.contextMenuItem = delegateItem;
        root.contextMenuModelData = modelData;
        root.contextMenuTitle = (modelData.title || modelData.id || "Application").trim();
        menuCloseTimer.stop();
        closeTimer.stop();
        root.expanded = true;
    }

    function closeContextMenu() {
        root.contextMenuItem = null;
        root.contextMenuModelData = null;
        root.contextMenuTitle = "";
        menuCloseTimer.stop();
        if (!root.pinned && !trayAreaHover.hovered) {
            closeTimer.restart();
        }
    }

    // Debounce timer for smooth collapse without jitter
    Timer {
        id: closeTimer
        interval: 450
        onTriggered: {
            if (!root.pinned && !root.menuOpen && !trayAreaHover.hovered) {
                root.expanded = false;
            }
        }
    }

    // Context menu auto-close timer when mouse leaves menu area
    Timer {
        id: menuCloseTimer
        interval: 800
        onTriggered: {
            if (!menuBoxHover.hovered && !trayAreaHover.hovered) {
                root.closeContextMenu();
            }
        }
    }

    // Enclosing hover detector covering the whole tray component
    HoverHandler {
        id: trayAreaHover
        onHoveredChanged: {
            if (hovered) {
                closeTimer.stop();
                if (root.menuOpen) menuCloseTimer.stop();
            } else {
                if (!root.pinned && !root.menuOpen) {
                    closeTimer.restart();
                } else if (root.menuOpen) {
                    menuCloseTimer.restart();
                }
            }
        }
    }

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // 1. CHEVRON TRIGGER BUTTON (leads motion to the left)
        Item {
            id: chevronBtn
            height: 18
            width: root.chevronVisible ? 18 : 0
            opacity: root.chevronVisible ? 1 : 0
            clip: true
            visible: width > 0

            Behavior on width {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 4
                color: (chevronHover.hovered || chevronMa.containsMouse) ? Qt.alpha(Theme.text, 0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Text {
                id: chevronGlyph
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.iconYOffset
                text: "\uDB80\uDD41" // nf-md chevron_left
                color: (chevronHover.hovered || chevronMa.containsMouse || root.pinned || root.expanded) ? Theme.accent : Theme.textDim
                font.family: Theme.iconFont
                font.pixelSize: 13
                rotation: (root.expanded || root.pinned) ? 180 : 0

                Behavior on rotation {
                    NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            HoverHandler {
                id: chevronHover
                onHoveredChanged: {
                    if (hovered) {
                        closeTimer.stop();
                        root.expanded = true;
                    }
                }
            }

            MouseArea {
                id: chevronMa
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    closeTimer.stop();
                    root.expanded = true;
                }
                onClicked: {
                    root.pinned = !root.pinned;
                    root.expanded = root.pinned || trayAreaHover.hovered || chevronHover.hovered;
                }
            }
        }

        // 2. APPS DRAWER
        Item {
            id: drawer
            height: 18
            clip: true
            width: (root.expanded || root.pinned || root.menuOpen) ? itemsRow.implicitWidth : 0

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animMed
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: itemsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                leftPadding: 4
                rightPadding: 2

                Repeater {
                    model: SystemTray.items

                    delegate: Item {
                        id: itemDelegate
                        required property var modelData
                        width: 20
                        height: 18

                        // Hover capsule background
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 4
                            color: (root.contextMenuItem === itemDelegate) ? Qt.alpha(Theme.accent, 0.22)
                                 : (itemHover.hovered || itemMa.containsMouse) ? Qt.alpha(Theme.accent, 0.14) : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        HoverHandler {
                            id: itemHover
                            onHoveredChanged: {
                                if (hovered) {
                                    closeTimer.stop();
                                    root.expanded = true;
                                }
                            }
                        }

                        // Icon image
                        Image {
                            id: iconImg
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: root.iconYOffset
                            width: 14; height: 14
                            sourceSize.width: 16; sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            source: root.resolveIcon(modelData.icon)
                            smooth: true
                            mipmap: true
                        }

                        // Text fallback if icon image cannot be resolved
                        Text {
                            visible: iconImg.status !== Image.Ready
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: root.iconYOffset
                            text: {
                                const name = modelData.title || modelData.id || "";
                                return name.length > 0 ? name.charAt(0).toUpperCase() : "\uf013";
                            }
                            color: Theme.textDim
                            font.family: Theme.iconFont
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onEntered: {
                                closeTimer.stop();
                                root.expanded = true;
                            }
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (root.contextMenuItem === itemDelegate) {
                                        root.closeContextMenu();
                                    } else {
                                        root.openContextMenu(itemDelegate, modelData);
                                    }
                                } else if (mouse.button === Qt.LeftButton) {
                                    root.closeContextMenu();
                                    root.activateItem(modelData);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    root.closeContextMenu();
                                    modelData.secondaryActivate();
                                }
                            }
                            onWheel: wheel => {
                                modelData.scroll(wheel.angleDelta.y, false);
                            }
                        }
                    }
                }
            }
        }
    }

    // Context Menu Popup Window (anchored right below the clicked app icon)
    PopupWindow {
        id: contextMenuPopup
        anchor.window: root.barWindow
        anchor.item: root.contextMenuItem ? root.contextMenuItem : root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 4
        anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX
        visible: root.contextMenuItem !== null
        implicitWidth: 160
        implicitHeight: menuBox.implicitHeight
        color: "transparent"

        onClosed: {
            if (root.contextMenuItem !== null) {
                root.closeContextMenu();
            }
        }

        Rectangle {
            id: menuBox
            width: 160
            implicitWidth: 160
            implicitHeight: menuCol.implicitHeight + 16
            radius: 6
            color: Theme.bgCard
            border.width: 1
            border.color: Theme.borderAccent

            HoverHandler {
                id: menuBoxHover
                onHoveredChanged: {
                    if (hovered) {
                        menuCloseTimer.stop();
                        closeTimer.stop();
                    } else {
                        menuCloseTimer.restart();
                    }
                }
            }

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 6

                // Header with App Name
                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: root.contextMenuTitle
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Theme.text, 0.12)
                }

                // Action: Open / Focus
                Rectangle {
                    width: parent.width
                    height: 26
                    radius: 4
                    color: openMa.containsMouse ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "\uf08e" // nf-fa-external_link
                            color: openMa.containsMouse ? Theme.accent : Theme.textDim
                            font.family: Theme.iconFont
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Open / Focus"
                            color: openMa.containsMouse ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: openMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const item = root.contextMenuModelData;
                            root.closeContextMenu();
                            if (item) root.activateItem(item);
                        }
                    }
                }

                // Action: Quit / Exit (Completely terminates the application)
                Rectangle {
                    width: parent.width
                    height: 26
                    radius: 4
                    color: quitMa.containsMouse ? Qt.alpha(Theme.danger, 0.22) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "\uf011" // nf-fa-power_off
                            color: quitMa.containsMouse ? Theme.danger : Theme.textDim
                            font.family: Theme.iconFont
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Quit / Exit"
                            color: quitMa.containsMouse ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: quitMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const item = root.contextMenuModelData;
                            root.closeContextMenu();
                            if (item) root.terminateItem(item);
                        }
                    }
                }
            }
        }
    }
}
