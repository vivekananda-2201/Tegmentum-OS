import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell.Wayland

PanelWindow {
    id: main

    property int speed: 5000
    property int animDuration: 250
    property real zoomScale: 0.8
    property real edgeScale: 0.3
    property real skewFactor: 0
    property real baseSpacing: 0
    property real edgeSpacing: 80
    property int startPosition: 4
    property bool shadowEnabled: true
    property color shadowColor: "#000000"
    property real shadowOpacity: 0.4
    property real shadowBlur: 0.45
    property real shadowX: 6
    property real shadowY: 6

    property string baseWallpaperPath: {
        let p = (configs && configs.wallpaper_path && configs.wallpaper_path.length > 0)
                ? configs.wallpaper_path
                : "$HOME/Pictures/Wallpapers"
        return p.replace("$HOME", Quickshell.env("HOME")).replace(/\/+$/, "")
    }
    property string cachePath: {
        let p = (configs && configs.cache_path && configs.cache_path.length > 0)
                ? configs.cache_path
                : "$HOME/.cache/quickshell/thumbs"
        let res = p.replace("$HOME", Quickshell.env("HOME")).replace(/\/+$/, "")
        return res + "/"
    }
    property string currentWallpaperPath: ""

    // Multi-directory navigation state
    property var directoryList: []
    property int currentDirIndex: 0
    property string currentDirectoryPath: directoryList.length > 0 ? directoryList[currentDirIndex].path : baseWallpaperPath
    property string currentDirectoryName: directoryList.length > 0 ? directoryList[currentDirIndex].name : "Wallpapers"

    property bool showEmpty: false
    readonly property bool looksEmpty: currentDirectoryPath !== ""
                                       && folderModel.status === FolderListModel.Ready
                                       && folderModel.count === 0

    onLooksEmptyChanged: {
        if (looksEmpty) {
            emptyDelay.restart()
        } else {
            emptyDelay.stop()
            showEmpty = false
        }
    }

    implicitHeight: Screen.height
    implicitWidth: Screen.width
    color: "transparent"
    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        Quickshell.execDetached(["bash", Quickshell.shellPath("cache.sh"), Quickshell.shellDir])
        list.forceActiveFocus()
    }

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures
            property string border_color
        }
    }

    FileView {
        path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.cache/current_wallpaper")
        watchChanges: false
        printErrors: false
        onLoaded: {
            let t = text().trim()
            if (t.length > 0) {
                main.currentWallpaperPath = t
                main.matchCurrentWallpaperToDirectory()
            }
        }
    }

    FileView {
        path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.local/state/tegmentum/state.json")
        watchChanges: false
        printErrors: false
        onLoaded: {
            if (!main.currentWallpaperPath) {
                try {
                    let d = JSON.parse(text())
                    if (d.wallpaper) {
                        main.currentWallpaperPath = d.wallpaper
                        main.matchCurrentWallpaperToDirectory()
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: resolveProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let resolved = text.trim()
                if (resolved.length > 0) {
                    main.currentWallpaperPath = resolved
                    for (let d = 0; d < main.directoryList.length; d++) {
                        let dPath = main.directoryList[d].path
                        if (resolved.indexOf(dPath) === 0) {
                            main.loadDirectory(d, true)
                            return
                        }
                    }
                }
            }
        }
    }

    // Discover subdirectories dynamically
    FolderListModel {
        id: subDirModel
        folder: "file://" + main.baseWallpaperPath
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                main.rebuildDirectoryList()
            }
        }
        onCountChanged: main.rebuildDirectoryList()
    }

    // Check if loose wallpapers exist in the base folder
    FolderListModel {
        id: rootFilesCheck
        folder: "file://" + main.baseWallpaperPath
        showDirs: false
        showFiles: true
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        onStatusChanged: {
            if (status === FolderListModel.Ready && subDirModel.status === FolderListModel.Ready) {
                main.rebuildDirectoryList()
            }
        }
    }

    function rebuildDirectoryList() {
        let list = []
        for (let i = 0; i < subDirModel.count; i++) {
            let name = subDirModel.get(i, "fileName")
            let path = subDirModel.get(i, "filePath")
            if (name && path) {
                list.push({ name: name, path: path })
            }
        }
        if (rootFilesCheck.count > 0 || list.length === 0) {
            list.unshift({ name: "All / Root", path: main.baseWallpaperPath })
        }
        main.directoryList = list
        main.matchCurrentWallpaperToDirectory()
    }

    function matchCurrentWallpaperToDirectory() {
        if (main.directoryList.length === 0) return

        let targetIndex = 0
        if (main.currentWallpaperPath) {
            let curr = main.currentWallpaperPath
            for (let d = 0; d < main.directoryList.length; d++) {
                let dPath = main.directoryList[d].path
                if (curr.indexOf(dPath) === 0) {
                    targetIndex = d
                    main.loadDirectory(targetIndex, true)
                    return
                }
            }

            let currName = curr.substring(curr.lastIndexOf("/") + 1)
            resolveProcess.command = ["bash", "-c", "find '" + main.baseWallpaperPath + "' -name '" + currName + "' -print -quit"]
            resolveProcess.running = true
            return
        }

        main.loadDirectory(targetIndex, true)
    }

    function loadDirectory(index, isInitial) {
        if (index < 0 || index >= directoryList.length) return
        currentDirIndex = index
        let dir = directoryList[index]
        currentDirectoryPath = dir.path
        currentDirectoryName = dir.name

        folderModel.folder = "file://" + dir.path

        if (!isInitial) {
            list.userMoved = true
            list.ready = false
            showFolderNotification(dir.name)
        }
    }

    function showFolderNotification(name) {
        folderOsdText.text = name
        folderOsd.opacity = 1.0
        folderOsdTimer.restart()
    }

    function changeDirectory(delta) {
        if (directoryList.length <= 1) return
        let newIndex = (currentDirIndex + delta + directoryList.length) % directoryList.length
        loadDirectory(newIndex, false)
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + main.currentDirectoryPath
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                list.centerOnDirectoryLoaded()
            }
        }
        onCountChanged: {
            if (status === FolderListModel.Ready) {
                list.centerOnDirectoryLoaded()
            }
        }
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        onClicked: Qt.quit()
    }

    Timer {
        id: emptyDelay
        interval: 300
        onTriggered: main.showEmpty = main.looksEmpty
    }

    // Ephemeral Bold Folder Name (appears on folder change, fades out in 1.5s)
    Item {
        id: folderOsd
        anchors.bottom: list.top
        anchors.bottomMargin: 45
        anchors.horizontalCenter: parent.horizontalCenter
        width: folderOsdText.implicitWidth
        height: folderOsdText.implicitHeight
        z: 30
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }

        Text {
            id: folderOsdText
            text: ""
            color: "#ffffff"
            font.pixelSize: 32
            font.bold: true
            font.weight: Font.Bold
            style: Text.Outline
            styleColor: "#000000"
            anchors.centerIn: parent
        }

        Timer {
            id: folderOsdTimer
            interval: 1000
            repeat: false
            onTriggered: folderOsd.opacity = 0
        }
    }

    Column {
        id: emptyState
        anchors.centerIn: parent
        spacing: 10
        z: 2
        visible: main.showEmpty

        Text {
            text: "No wallpapers found in " + main.currentDirectoryName
            color: "#ffffff"
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Press ↑ / K or ↓ / J to switch folder"
            color: "#aaaaaa"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextEdit {
            id: pathText
            text: main.currentDirectoryPath
            color: "#dddddd"
            font.pixelSize: 14
            readOnly: true
            selectByMouse: true
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ListView {
        id: list
        width: parent.width
        height: 500
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        z: 1
        focus: true
        model: folderModel
        orientation: ListView.Horizontal
        spacing: 0
        clip: true
        cacheBuffer: 400
        boundsBehavior: Flickable.StopAtBounds

        property int selectedIndex: main.startPosition
        readonly property real tileWidth: width / configs.number_of_pictures - 10
        readonly property real viewportCenterX: width / 2
        readonly property real step: tileWidth + main.baseSpacing
        readonly property real sideMargin: Math.max(0, viewportCenterX - tileWidth / 2)
        property bool ready: false
        property bool userMoved: false
        property real lastScreenMouseX: -1
        property real lastScreenMouseY: -1

        leftMargin: sideMargin
        rightMargin: sideMargin

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }
        function ensureVisibleAnimated(i) { contentX = i * step - sideMargin }

        function findCurrentIndex() {
            if (count <= 0) return 0
            if (main.currentWallpaperPath) {
                let target = main.currentWallpaperPath
                let targetName = target.substring(target.lastIndexOf("/") + 1)
                for (let i = 0; i < count; i++) {
                    let p = folderModel.get(i, "filePath")
                    let n = folderModel.get(i, "fileName")
                    if (p === target || n === targetName) {
                        return i
                    }
                }
            }
            return clampIndex(main.startPosition)
        }

        function centerOnDirectoryLoaded() {
            if (count <= 0 || configs.number_of_pictures <= 0) {
                selectedIndex = 0
                contentX = 0
                ready = true
                return
            }
            selectedIndex = findCurrentIndex()
            contentX = selectedIndex * step - sideMargin
            ready = true
        }

        function activateCurrent() {
            Quickshell.execDetached(["bash", Quickshell.shellPath("commands.sh"), folderModel.get(selectedIndex, "filePath")])
            Qt.quit()
        }

        function moveSelection(delta, speedMultiplier) {
            userMoved = true
            ready = true
            anim.velocity = main.speed * speedMultiplier
            selectedIndex = clampIndex(selectedIndex + delta)
            ensureVisibleAnimated(selectedIndex)
        }

        onCountChanged: centerOnDirectoryLoaded()
        onWidthChanged: centerOnDirectoryLoaded()

        Connections {
            target: configs
            function onNumber_of_picturesChanged() { list.centerOnDirectoryLoaded() }
        }

        Behavior on contentX {
            enabled: list.ready
            SmoothedAnimation { id: anim; property real velocity: main.speed; duration: main.animDuration }
        }

        delegate: Item {
            id: delegateItem
            width: list.tileWidth
            height: 500

            property bool active: index === list.selectedIndex
            readonly property real baseWidth: list.tileWidth
            readonly property real baseCenterX: x - list.contentX + baseWidth / 2
            readonly property real distance: Math.abs(baseCenterX - list.viewportCenterX)
            readonly property real fraction: Math.min(1, distance / list.viewportCenterX)
            readonly property real compression: { const t = fraction; return t * t * t * t }
            readonly property real edgeOffset: {
                const amount = main.edgeSpacing * compression
                return baseCenterX < list.viewportCenterX ? amount : -amount
            }
            readonly property real scaleFactor: {
                const t = 1 - fraction * fraction * (3 - 2 * fraction)
                return main.edgeScale + (main.zoomScale - main.edgeScale) * t
            }

            Item {
                id: content
                anchors.verticalCenter: parent.verticalCenter
                width: delegateItem.baseWidth * delegateItem.scaleFactor
                height: delegateItem.height * Math.min(1, delegateItem.scaleFactor)
                x: (delegateItem.baseWidth - width) / 2 + delegateItem.edgeOffset

                Image {
                    id: shadowImage
                    x: main.shadowX
                    y: main.shadowY
                    width: parent.width
                    height: parent.height
                    source: img.source
                    sourceSize.width: img.sourceSize.width
                    sourceSize.height: img.sourceSize.height
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    visible: main.shadowEnabled
                    opacity: main.shadowOpacity
                    layer.enabled: true
                    layer.effect: MultiEffect { brightness: -1; blurEnabled: true; blur: main.shadowBlur }
                    transform: Shear { xFactor: main.skewFactor }
                }

                Text {
                    id: alt
                    text: ""
                    color: configs.border_color
                    anchors.centerIn: parent
                    font.pixelSize: 16
                    transform: Shear { xFactor: main.skewFactor }
                }

                Image {
                    id: img
                    anchors.fill: parent
                    opacity: 0.95
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    source: "file://" + main.cachePath + fileName
                    sourceSize.width: delegateItem.baseWidth * main.zoomScale
                    sourceSize.height: delegateItem.height
                    transform: Shear { xFactor: main.skewFactor }

                    Timer {
                        id: retryTimer
                        interval: 1000
                        repeat: false
                        onTriggered: { const s = img.source; img.source = ""; img.source = s }
                    }

                    onStatusChanged: {
                        if (status === Image.Error) {
                            if (source.toString() !== "file://" + main.currentDirectoryPath + "/" + fileName) {
                                source = "file://" + main.currentDirectoryPath + "/" + fileName
                            } else {
                                alt.text = "Caching"
                                retryTimer.start()
                            }
                        }
                    }
                }

                Rectangle {
                    z: 10
                    anchors.fill: parent
                    visible: delegateItem.active
                    color: "transparent"
                    border.width: 2
                    border.color: configs.border_color
                    transform: Shear { xFactor: main.skewFactor }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: list.ready
                onPositionChanged: function(mouse) {
                    let p = mapToItem(main, mouse.x, mouse.y)
                    if (Math.abs(p.x - list.lastScreenMouseX) > 3 || Math.abs(p.y - list.lastScreenMouseY) > 3) {
                        list.lastScreenMouseX = p.x
                        list.lastScreenMouseY = p.y
                        list.userMoved = true
                        list.selectedIndex = index
                    }
                }
                onClicked: {
                    list.selectedIndex = index
                    list.activateCurrent()
                }
                onWheel: function(wheel) { list.flick(-wheel.angleDelta.y * 8, 0); wheel.accepted = true }
            }
        }

        Keys.onPressed: function(event) {
            // Horizontal navigation: wallpapers in current folder
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                list.moveSelection(-1, 1)
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                list.moveSelection(1, 1)
            }
            // Vertical navigation: switch directory (j / down = next, k / up = prev)
            else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                main.changeDirectory(1)
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                main.changeDirectory(-1)
            }
            // Page navigation
            else if (event.key === Qt.Key_PageUp) {
                list.moveSelection(-5, 1)
            } else if (event.key === Qt.Key_PageDown) {
                list.moveSelection(5, 1)
            } else if (event.key === Qt.Key_Home) {
                list.userMoved = true
                list.ready = true
                list.selectedIndex = 0
                list.ensureVisibleAnimated(0)
            } else if (event.key === Qt.Key_End) {
                list.userMoved = true
                list.ready = true
                list.selectedIndex = list.clampIndex(list.count - 1)
                list.ensureVisibleAnimated(list.selectedIndex)
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                list.activateCurrent()
            } else if (event.key === Qt.Key_W || event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                Qt.quit()
            } else {
                return
            }
            event.accepted = true
        }
    }
}
