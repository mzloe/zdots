// Skewed-slice image carousel, used for picking themes and wallpapers.
// Adapted from omarchy's shell/plugins/image-picker/ImagePicker.qml into a one-shot Quickshell
// config: ze_pick_image launches it with the ZE_PICKER_* environment, it writes the choice and quits.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "ImagePickerModel.js" as ImagePickerModel

ShellRoot {
  id: root

  property string selectionFile: Quickshell.env("ZE_PICKER_SELECTION_FILE")
  property string selectedImage: Quickshell.env("ZE_PICKER_SELECTED")
  property bool showLabels: Quickshell.env("ZE_PICKER_SHOW_LABELS") === "true"
  property bool filterable: Quickshell.env("ZE_PICKER_FILTERABLE") === "true"

  property color background: Quickshell.env("ZE_PICKER_BACKGROUND") || "#1e1e2e"
  property color foreground: Quickshell.env("ZE_PICKER_FOREGROUND") || "#cdd6f4"
  property color accent: Quickshell.env("ZE_PICKER_ACCENT") || "#89b4fa"

  // `dimColor` tints unselected slices and text outlines on top of the scrim
  property color dimColor: background
  property color scrim: alpha(background, 0.5)
  property color selectedBorder: accent
  property color unselectedBorder: alpha(foreground, 0.28)

  property var imageArray: []
  property int selectedIndex: 0
  property string filterText: ""

  property int expandedWidth: 768
  property int expandedHeight: 475
  property int sliceWidth: 108
  property int sliceHeight: 432
  property int sliceSpacing: -30
  property int skewOffset: 28
  property int bottomChromeHeight: showLabels ? (filterable ? 104 : 74) : (filterable ? 60 : 30)

  function alpha(color, amount) {
    return Qt.rgba(color.r, color.g, color.b, amount)
  }

  function fileUrl(path) {
    if (!path) return ""
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
  }

  function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
  }

  function currentPath() {
    if (imageArray.length === 0 || !itemMatches(selectedIndex)) return ""
    return imageArray[selectedIndex].filePath
  }

  function currentLabel() {
    var path = currentPath()
    if (!path) return filterText ? "No matches" : ""
    return ImagePickerModel.labelForPath(path)
  }

  function itemMatches(index) {
    return ImagePickerModel.itemMatches(imageArray, index, filterText)
  }

  function select(index) {
    if (index < 0 || index >= imageArray.length || !itemMatches(index)) return
    selectedIndex = index
  }

  function selectAdjacent(direction) {
    var count = imageArray.length
    var index = selectedIndex
    for (var i = 0; i < count; i++) {
      index = (index + direction + count) % count
      if (itemMatches(index)) {
        selectedIndex = index
        return
      }
    }
  }

  function updateFilter(nextFilterText) {
    filterText = nextFilterText

    var next = ImagePickerModel.nextSelectedIndexForFilter(imageArray, selectedIndex, filterText)
    if (next >= 0) selectedIndex = next
  }

  function applySelected() {
    var path = currentPath()
    if (!path || !selectionFile) {
      Qt.quit()
      return
    }

    applyProc.command = ["bash", "-c", "printf '%s\\n' " + shellQuote(path) + " > " + shellQuote(selectionFile)]
    applyProc.running = true
  }

  Process {
    id: applyProc
    onExited: Qt.quit()
  }

  FileView {
    path: Quickshell.env("ZE_PICKER_ROWS_FILE")
    blockLoading: true
    onLoaded: {
      var images = ImagePickerModel.loadRows(text())
      root.selectedIndex = ImagePickerModel.indexForSelectedImage(images, root.selectedImage)
      root.imageArray = images
      if (images.length === 0) Qt.quit()
    }
    onLoadFailed: Qt.quit()
  }

  PanelWindow {
    id: panel

    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "ze-image-selector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: Qt.quit()
    }

    Item {
      id: card
      visible: root.imageArray.length > 0
      width: Math.min(parent.width - 80, root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing) + 40)
      height: root.expandedHeight + 30 + root.bottomChromeHeight
      anchors.centerIn: parent

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: carousel
        anchors.top: parent.top
        anchors.topMargin: 30
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomChromeHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing)
        focus: true

        readonly property real itemStep: root.sliceWidth + root.sliceSpacing
        readonly property real previewX: (width - root.expandedWidth) / 2

        Keys.onPressed: function(event) {
          var plain = event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier

          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.updateFilter("")
            else Qt.quit()
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelected()
          } else if (root.filterText && event.key === Qt.Key_Backspace) {
            root.updateFilter(event.modifiers & Qt.ControlModifier ? "" : root.filterText.slice(0, -1))
          } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            root.selectAdjacent(-1)
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            root.selectAdjacent(1)
          } else if (root.filterable && plain && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.updateFilter(root.filterText + event.text)
          } else {
            return
          }
          event.accepted = true
        }

        Component.onCompleted: forceActiveFocus()

        Repeater {
          model: root.imageArray.length

          delegate: Item {
            id: item
            required property int index

            readonly property var imageData: root.imageArray[index]
            readonly property bool matched: root.itemMatches(index)
            readonly property int relativeIndex: ImagePickerModel.filteredPosition(root.imageArray, index, root.filterText) - ImagePickerModel.selectedFilteredPosition(root.imageArray, root.selectedIndex, root.filterText)
            readonly property bool selected: matched && index === root.selectedIndex
            readonly property bool nearby: matched && Math.abs(relativeIndex) <= 16
            // Load only slices that have come near, but keep them once loaded
            property bool sourceActivated: nearby
            onNearbyChanged: if (nearby) sourceActivated = true

            visible: nearby
            x: selected ? carousel.previewX : (relativeIndex < 0 ? carousel.previewX + relativeIndex * carousel.itemStep : carousel.previewX + root.expandedWidth + root.sliceSpacing + (relativeIndex - 1) * carousel.itemStep)
            width: selected ? root.expandedWidth : root.sliceWidth
            height: selected ? root.expandedHeight : root.sliceHeight
            y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
            z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

            // Parallelogram corners, leaning right
            readonly property real topLeft: root.skewOffset
            readonly property real topRight: width
            readonly property real bottomRight: width - root.skewOffset
            readonly property real bottomLeft: 0

            Item {
              id: maskShape
              anchors.fill: parent
              visible: false
              layer.enabled: true

              Shape {
                anchors.fill: parent
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                  fillColor: "white"
                  strokeColor: "transparent"
                  startX: item.topLeft; startY: 0
                  PathLine { x: item.topRight; y: 0 }
                  PathLine { x: item.bottomRight; y: item.height }
                  PathLine { x: item.bottomLeft; y: item.height }
                  PathLine { x: item.topLeft; y: 0 }
                }
              }
            }

            Item {
              anchors.fill: parent
              layer.enabled: true
              layer.smooth: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskShape
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.3
              }

              Image {
                anchors.fill: parent
                source: item.sourceActivated && item.imageData ? root.fileUrl(item.imageData.thumbnailPath) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                smooth: true
              }

              Rectangle {
                anchors.fill: parent
                color: root.alpha(root.dimColor, item.selected ? 0 : 0.42)
              }
            }

            Shape {
              anchors.fill: parent
              antialiasing: true
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                fillColor: "transparent"
                strokeColor: item.selected ? root.selectedBorder : root.unselectedBorder
                strokeWidth: item.selected ? 3 : 1
                startX: item.topLeft; startY: 0
                PathLine { x: item.topRight; y: 0 }
                PathLine { x: item.bottomRight; y: item.height }
                PathLine { x: item.bottomLeft; y: item.height }
                PathLine { x: item.topLeft; y: 0 }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: item.selected ? root.applySelected() : root.select(item.index)
            }
          }
        }
      }

      Text {
        id: selectedLabel
        textFormat: Text.PlainText
        visible: root.showLabels
        anchors.top: carousel.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: carousel.horizontalCenter
        width: root.expandedWidth
        text: root.currentLabel()
        color: root.foreground
        style: Text.Outline
        styleColor: root.alpha(root.dimColor, 0.7)
        font.pixelSize: 24
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        visible: root.filterable && root.filterText
        anchors.top: selectedLabel.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: carousel.horizontalCenter
        width: root.expandedWidth
        text: root.filterText
        color: root.foreground
        opacity: 0.85
        style: Text.Outline
        styleColor: root.alpha(root.dimColor, 0.7)
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }
    }
  }
}
