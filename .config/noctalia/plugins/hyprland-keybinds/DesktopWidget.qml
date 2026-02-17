import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root
  property var pluginApi: null

  readonly property string configPath: pluginApi?.pluginSettings?.configPath || "~/.config/hypr/keybinds.conf"
  readonly property string iconName: pluginApi?.pluginSettings?.iconName ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconName ?? "keyboard"

  implicitWidth: 200
  implicitHeight: 120

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginS

    NIcon {
      icon: iconName
      pointSize: Style.fontSizeXXL
      Layout.alignment: Qt.AlignHCenter
    }

    NText {
      text: "Hyprland Keybinds"
      font.pointSize: Style.fontSizeM
      Layout.alignment: Qt.AlignHCenter
    }

    NText {
      text: configPath
      font.pointSize: Style.fontSizeXS
      color: Color.mOnSurfaceVariant
      Layout.alignment: Qt.AlignHCenter
      elide: Text.ElideMiddle
    }
  }
}
