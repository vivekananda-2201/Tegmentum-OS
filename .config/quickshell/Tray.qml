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

    readonly property bool hovered: chevronMa.containsMouse || drawerMa.containsMouse || expanded || pinned
    readonly property int itemCount: SystemTray.items.values ? SystemTray.items.values.length : 0
    readonly property bool hasItems: itemCount > 0
    readonly property bool chevronVisible: (isRightBarHovered || expanded || pinned) && hasItems

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
        }
    }

    // Debounce timer for smooth collapse without jitter
    Timer {
        id: closeTimer
        interval: 350
        onTriggered: {
            if (!root.pinned && !chevronMa.containsMouse && !drawerMa.containsMouse) {
                root.expanded = false;
            }
        }
    }

    // Tooltip properties
    property var activeTooltipItem: null
    property string activeTooltipTitle: ""
    property string activeTooltipDesc: ""

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
                color: (chevronMa.containsMouse || root.pinned) ? Theme.accent : Theme.textDim
                font.family: Theme.iconFont
                font.pixelSize: 13
                rotation: root.expanded ? 180 : 0

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
                    if (!root.pinned) closeTimer.restart();
                }
                onClicked: {
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
            width: (root.expanded || root.pinned) ? itemsRow.implicitWidth : 0

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animMed
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                id: drawerMa
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: {
                    closeTimer.stop();
                    root.expanded = true;
                }
                onExited: {
                    if (!root.pinned) closeTimer.restart();
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
                            color: itemHover.hovered ? Qt.alpha(Theme.accent, 0.14) : "transparent"
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

                        // Context menu anchor for SNI right-click
                        QsMenuAnchor {
                            id: menuAnchor
                            anchor.window: root.barWindow
                            anchor.item: itemDelegate
                            menu: modelData.menu
                        }

                        HoverHandler {
                            id: itemHover
                            onHoveredChanged: {
                                if (hovered) {
                                    closeTimer.stop();
                                    root.activeTooltipItem = itemDelegate;
                                    root.activeTooltipTitle = (modelData.tooltipTitle || modelData.title || "").trim();
                                    root.activeTooltipDesc = (modelData.tooltipDescription || "").trim();
                                } else {
                                    if (root.activeTooltipItem === itemDelegate) {
                                        root.activeTooltipItem = null;
                                        root.activeTooltipTitle = "";
                                        root.activeTooltipDesc = "";
                                    }
                                    if (!root.pinned) closeTimer.restart();
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && modelData.onlyMenu)) {
                                    if (modelData.hasMenu && modelData.menu) {
                                        menuAnchor.open();
                                    }
                                } else if (mouse.button === Qt.LeftButton) {
                                    root.activateItem(modelData);
                                } else if (mouse.button === Qt.MiddleButton) {
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

    // Shared Tooltip Popup Window
    PopupWindow {
        id: tooltipPopup
        anchor.window: root.barWindow
        anchor.item: root.activeTooltipItem ? root.activeTooltipItem : root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 4
        visible: root.activeTooltipItem !== null && (root.activeTooltipTitle !== "" || root.activeTooltipDesc !== "")
        implicitWidth: tipCol.implicitWidth + 12
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
}
