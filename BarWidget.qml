import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar button for the airdisplay script shipped next to this file. Watches the
// state file the script writes; highlighted while something is streaming to a
// TV. Click opens the menu.
BarWidget {
  id: root
  moduleName: "darkosxl.airdisplay"

  property var stream: ({ active: false })
  readonly property string script: decodeURIComponent(Qt.resolvedUrl("airdisplay").toString().replace("file://", ""))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/airdisplay.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.stream = JSON.parse(text()) } catch (e) { root.stream = { active: false } }
    }
    onLoadFailed: root.stream = { active: false }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.stream.active ? "󰄙" : "󰄘"
    active: root.stream.active === true
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: root.stream.active ? root.stream.title + " → " + root.stream.tv : "AirDisplay"
    onPressed: if (root.bar) root.bar.run("'" + root.script + "' menu")
  }
}
