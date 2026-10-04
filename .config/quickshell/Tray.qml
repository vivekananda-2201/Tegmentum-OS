// Tray.qml — Collapsible Animated System Tray for Tegmentum-OS Bar
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu

Item {
    id: root

    required property var barWindow
    property bool isRightBarHovered: false
    property int iconYOffset: 0

    property bool expanded: false
    property bool pinned: false
    property bool menuOpen: false

    property int hoveredItemCount: 0

    readonly property int itemCount: SystemTray.items.values ? SystemTray.items.values.length : 0
    readonly property bool hasItems: itemCount > 0
    readonly property bool chevronVisible: (isRightBarHovered || expanded || pinned || menuOpen) && hasItems
    readonly property bool hovered: chevronMa.containsMouse || drawerHover.hovered || hoveredItemCount > 0 || expanded || pinned || menuOpen

    implicitHeight: 18
    implicitWidth: trayRow.implicitWidth

    // Fire-and-forget process runner
    Process { id: runner }
    function run(cmd) {
        runner.command = ["sh", "-c", cmd];
        runner.running = true;
    }

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

    // Activate item and focus Hyprland window/workspace
    function activateItem(item) {
        if (!item) return;
        item.activate();

        const id = (item.id || "").toLowerCase();
        const title = (item.title || "").toLowerCase();

        // Search for matching window in Hyprland
        const toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
        const toplevel = toplevels.find(t => {
            const ipc = t.lastIpcObject || {};
            const c = String(ipc.class || "").toLowerCase();
            const ic = String(ipc.initialClass || "").toLowerCase();
            const tTitle = String(t.title || "").toLowerCase();
            return (c && (id.includes(c) || c.includes(id)))
                || (ic && (id.includes(ic) || ic.includes(id)))
                || (title && (tTitle.includes(title) || title.includes(tTitle)));
        });

        if (toplevel) {
            if (toplevel.workspace) {
                toplevel.workspace.activate();
            }
            root.run("hyprctl dispatch 'hl.dsp.focus({window=\"address:" + toplevel.address + "\"})'");
        } else {
            // App may be unminimizing now; retry focus after short delay
            focusDelayTimer.targetId = id;
            focusDelayTimer.targetTitle = title;
            focusDelayTimer.restart();
        }
    }

    // Delayed focus for windows unminimizing from tray
    Timer {
        id: focusDelayTimer
        interval: 150
        property string targetId: ""
        property string targetTitle: ""
        onTriggered: {
            const toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
            const toplevel = toplevels.find(t => {
                const ipc = t.lastIpcObject || {};
                const c = String(ipc.class || "").toLowerCase();
                const ic = String(ipc.initialClass || "").toLowerCase();
                const tTitle = String(t.title || "").toLowerCase();
                return (c && (targetId.includes(c) || c.includes(targetId)))
                    || (ic && (targetId.includes(ic) || ic.includes(targetId)))
                    || (targetTitle && (tTitle.includes(targetTitle) || targetTitle.includes(tTitle)));
            });
            if (toplevel) {
                if (toplevel.workspace) {
                    toplevel.workspace.activate();
                }
                root.run("hyprctl dispatch 'hl.dsp.focus({window=\"address:" + toplevel.address + "\"})'");
            }
        }
    }

    // Completely terminate background application
    function quitApp(item) {
        if (!item) return;
        const id = (item.id || "").toLowerCase();
        const title = (item.title || "").toLowerCase();

        // 1. Try to find exact PID from Hyprland toplevels
        let targetPid = null;
        const toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
        const toplevel = toplevels.find(t => {
            const ipc = t.lastIpcObject || {};
            const c = String(ipc.class || "").toLowerCase();
            const ic = String(ipc.initialClass || "").toLowerCase();
            const tTitle = String(t.title || "").toLowerCase();
            return (c && (id.includes(c) || c.includes(id)))
                || (ic && (id.includes(ic) || ic.includes(id)))
                || (title && (tTitle.includes(title) || title.includes(tTitle)));
        });

        if (toplevel && toplevel.lastIpcObject && toplevel.lastIpcObject.pid) {
            targetPid = toplevel.lastIpcObject.pid;
        }

        if (targetPid) {
            root.run("kill -15 " + targetPid + " 2>/dev/null; sleep 0.2; kill -9 " + targetPid + " 2>/dev/null || true");
        } else {
            const rawName = item.id || item.title || "";
            const cleanName = rawName.split(".").pop().toLowerCase();
            root.run("pkill -15 -x '" + rawName + "' 2>/dev/null || pkill -15 -x '" + cleanName + "' 2>/dev/null || pkill -15 -i -f '" + cleanName + "' 2>/dev/null; sleep 0.2; pkill -9 -x '" + cleanName + "' 2>/dev/null || true");
        }

        root.menuOpen = false;
        root.activeMenuItem = null;
        root.activeMenuItemDelegate = null;
    }

    // Debounce timer for smooth collapse without jitter
    Timer {
        id: closeTimer
        interval: 450
        onTriggered: {
            const isMouseInTray = chevronMa.containsMouse || drawerHover.hovered || root.hoveredItemCount > 0 || (menuBoxHover.hovered);
            if (!root.pinned && !isMouseInTray) {
                root.expanded = false;
                root.menuOpen = false;
                root.activeMenuItem = null;
                root.activeMenuItemDelegate = null;
                root.activeTooltipItem = null;
            }
        }
    }

    // Tooltip & Context Menu properties
    property var activeTooltipItem: null
    property string activeTooltipTitle: ""
    property string activeTooltipDesc: ""

    property var activeMenuItem: null
    property var activeMenuItemDelegate: null
    property var activeMenuItemAnchor: null

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
                color: chevronMa.containsMouse ? Qt.alpha(Theme.text, 0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Text {
                id: chevronGlyph
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.iconYOffset
                text: "\uDB80\uDD41" // nf-md chevron_left
                color: (chevronMa.containsMouse || root.pinned || root.menuOpen) ? Theme.accent : Theme.textDim
                font.family: Theme.iconFont
                font.pixelSize: 13
                rotation: (root.expanded || root.menuOpen) ? 180 : 0

                Behavior on rotation {
                    NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            MouseArea {
                id: chevronMa
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onEntered: {
                    closeTimer.stop();
                    root.expanded = true;
                }
                onExited: {
                    if (!root.pinned && !root.menuOpen && !drawerHover.hovered && root.hoveredItemCount === 0) {
                        closeTimer.restart();
                    }
                }
                onClicked: {
                    if (root.menuOpen) root.menuOpen = false;
                    root.pinned = !root.pinned;
                    root.expanded = root.pinned || chevronMa.containsMouse;
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

            HoverHandler {
                id: drawerHover
                onHoveredChanged: {
                    if (hovered) {
                        closeTimer.stop();
                        root.expanded = true;
                    } else {
                        if (!root.pinned && !root.menuOpen && !chevronMa.containsMouse && root.hoveredItemCount === 0) {
                            closeTimer.restart();
                        }
                    }
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

                        readonly property bool isSelected: root.menuOpen && root.activeMenuItem === modelData

                        // Hover capsule background
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 4
                            color: itemDelegate.isSelected ? Qt.alpha(Theme.accent, 0.25)
                                 : itemMa.containsMouse ? Qt.alpha(Theme.accent, 0.14) : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
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

                        // Native DBus context menu anchor
                        QsMenuAnchor {
                            id: menuAnchor
                            anchor.window: root.barWindow
                            anchor.item: itemDelegate
                            menu: modelData.menu
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onEntered: {
                                root.hoveredItemCount++;
                                closeTimer.stop();
                                root.expanded = true;
                                if (!root.menuOpen) {
                                    root.activeTooltipItem = itemDelegate;
                                    root.activeTooltipTitle = (modelData.tooltipTitle || modelData.title || "").trim();
                                    root.activeTooltipDesc = (modelData.tooltipDescription || "").trim();
                                }
                            }
                            onExited: {
                                root.hoveredItemCount = Math.max(0, root.hoveredItemCount - 1);
                                if (root.activeTooltipItem === itemDelegate && !root.menuOpen) {
                                    root.activeTooltipItem = null;
                                    root.activeTooltipTitle = "";
                                    root.activeTooltipDesc = "";
                                }
                                if (!root.pinned && !root.menuOpen && !drawerHover.hovered && !chevronMa.containsMouse) {
                                    closeTimer.restart();
                                }
                            }
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    // Toggle if clicking the same item, otherwise switch to it
                                    if (root.menuOpen && root.activeMenuItem === modelData) {
                                        root.menuOpen = false;
                                        root.activeMenuItem = null;
                                        root.activeMenuItemDelegate = null;
                                    } else {
                                        root.activeTooltipItem = null;
                                        root.activeMenuItem = modelData;
                                        root.activeMenuItemDelegate = itemDelegate;
                                        root.activeMenuItemAnchor = menuAnchor;
                                        root.menuOpen = true;
                                        closeTimer.stop();
                                        root.expanded = true;
                                    }
                                } else if (mouse.button === Qt.LeftButton) {
                                    root.menuOpen = false;
                                    if (modelData.onlyMenu) {
                                        if (modelData.hasMenu && modelData.menu) {
                                            menuAnchor.open();
                                        }
                                    } else {
                                        root.activateItem(modelData);
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    root.menuOpen = false;
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

    // Shared Tooltip Popup Window (only visible when context menu is closed)
    PopupWindow {
        id: tooltipPopup
        anchor.window: root.barWindow
        anchor.item: root.activeTooltipItem ? root.activeTooltipItem : root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6
        visible: !root.menuOpen && root.activeTooltipItem !== null && (root.activeTooltipTitle !== "" || root.activeTooltipDesc !== "")
        implicitWidth: tipCol.implicitWidth + 14
        implicitHeight: tipCol.implicitHeight + 8
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: Theme.bgCard
            border.width: 1
            border.color: Theme.border

            Column {
                id: tipCol
                anchors.centerIn: parent
                spacing: 1

                Text {
                    text: root.activeTooltipTitle
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    visible: text !== ""
                }
                Text {
                    text: root.activeTooltipDesc
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    visible: text !== ""
                }
            }
        }
    }

    // Right-Click Context Menu Popup (with Quit & Terminate options!)
    PopupWindow {
        id: contextMenuPopup
        anchor.window: root.barWindow
        anchor.item: root.activeMenuItemDelegate ? root.activeMenuItemDelegate : root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6
        visible: root.menuOpen && root.activeMenuItem !== null
        implicitWidth: menuBox.width
        implicitHeight: menuBox.height
        color: "transparent"

        Rectangle {
            id: menuBox
            width: Math.max(160, menuCol.implicitWidth + 24)
            height: menuCol.implicitHeight + 16
            radius: 8
            color: Theme.bgCard
            border.width: 1
            border.color: Theme.border

            HoverHandler {
                id: menuBoxHover
                onHoveredChanged: {
                    if (hovered) {
                        closeTimer.stop();
                    } else {
                        if (!root.pinned && !chevronMa.containsMouse && !drawerHover.hovered && root.hoveredItemCount === 0) {
                            closeTimer.restart();
                        }
                    }
                }
            }

            Column {
                id: menuCol
                anchors.centerIn: parent
                width: parent.width - 16
                spacing: 4

                // Header: App Icon + App Name
                Row {
                    spacing: 8
                    height: 22
                    width: parent.width

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14
                        source: root.activeMenuItem ? root.resolveIcon(root.activeMenuItem.icon) : ""
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.activeMenuItem ? (root.activeMenuItem.title || root.activeMenuItem.id || "App") : ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width - 24
                    }
                }

                // Divider line
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Theme.borderAccent, 0.6)
                }

                // Action 1: Focus Window / Open
                Rectangle {
                    width: parent.width
                    height: 24
                    radius: 4
                    color: focusBtnMa.containsMouse ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uDB80\uDF73" // nf-md open_in_app / focus
                            color: focusBtnMa.containsMouse ? Theme.accent : Theme.textDim
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Focus Window"
                            color: focusBtnMa.containsMouse ? Theme.text : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: focusBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.activeMenuItem) {
                                root.activateItem(root.activeMenuItem);
                            }
                            root.menuOpen = false;
                        }
                    }
                }

                // Action 2: App Native DBus Menu (if provided)
                Rectangle {
                    visible: root.activeMenuItem !== null && root.activeMenuItem.hasMenu && root.activeMenuItem.menu !== null
                    width: parent.width
                    height: visible ? 24 : 0
                    radius: 4
                    color: nativeBtnMa.containsMouse ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uDB80\uDE8B" // nf-md dots_horizontal
                            color: nativeBtnMa.containsMouse ? Theme.accent : Theme.textDim
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "App Menu"
                            color: nativeBtnMa.containsMouse ? Theme.text : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: nativeBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const anchor = root.activeMenuItemAnchor;
                            root.menuOpen = false;
                            if (anchor) {
                                anchor.open();
                            }
                        }
                    }
                }

                // Action 3: Quit / Terminate Application
                Rectangle {
                    width: parent.width
                    height: 24
                    radius: 4
                    color: quitBtnMa.containsMouse ? Qt.alpha(Theme.danger, 0.22) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u23FB" // power icon
                            color: Theme.danger
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Quit Application"
                            color: quitBtnMa.containsMouse ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: quitBtnMa.containsMouse
                        }
                    }

                    MouseArea {
                        id: quitBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.activeMenuItem) {
                                root.quitApp(root.activeMenuItem);
                            }
                        }
                    }
                }
            }
        }
    }
}
