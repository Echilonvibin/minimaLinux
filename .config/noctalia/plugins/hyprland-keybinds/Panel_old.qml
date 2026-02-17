import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Panel Component
Item {
  id: root

  // Plugin API (injected by PluginPanelSlot)
  property var pluginApi: null

  // SmartPanel
  readonly property var geometryPlaceholder: panelContainer

  property real contentPreferredWidth: 600 * Style.uiScaleRatio
  property real contentPreferredHeight: 700 * Style.uiScaleRatio

  readonly property bool allowAttach: true

  property var mainComponent: null
  property string keybindsContent: ""
  property string configPath: ""

  anchors.fill: parent

  Component.onCompleted: {
    tryInitialize();
  }

  onPluginApiChanged: {
    if (pluginApi) {
      tryInitialize();
    }
  }

  function tryInitialize() {
    if (!pluginApi) {
      return;
    }
    
    mainComponent = pluginApi.mainInstance;
    if (mainComponent) {
      // Start polling for updates
      updateTimer.start();
    }
  }

  Timer {
    id: updateTimer
    interval: 300
    repeat: true
    running: false
    triggeredOnStart: true
    onTriggered: {
      updateContent();
      // Stop after 10 attempts (3 seconds)
      if (++updateAttempts >= 10 && keybindsContent.length > 0) {
        stop();
      }
    }
  }
  
  property int updateAttempts: 0

  function updateContent() {
    if (mainComponent) {
      keybindsContent = mainComponent.keybindsContent || "";
      configPath = mainComponent.configPath || "";
    }
  }

  function reloadKeybinds() {
    if (mainComponent) {
      mainComponent.readKeybinds();
      Qt.callLater(updateContent);
    }
  }

  function saveKeybinds() {
    if (mainComponent) {
      mainComponent.writeKeybinds(textEdit.text);
    }
  }

  // Watch for changes in the main component
  Connections {
    target: mainComponent
    function onKeybindsContentChanged() {
      updateContent();
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginL
      }
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "keyboard"
          pointSize: Style.fontSizeXL
        }

        NText {
          text: pluginApi?.tr("panel.title") || "Hyprland Keybinds"
          font.pointSize: Style.fontSizeXL * Style.uiScaleRatio
          font.weight: Font.Bold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "settings"
          tooltipText: pluginApi?.tr("menu.settings")
          onClicked: {
            var screen = pluginApi?.panelOpenScreen;
            if (screen && pluginApi?.manifest) {
              BarService.openPluginSettings(screen, pluginApi.manifest);
            }
          }
        }
      }

      // File path display
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: pathText.implicitHeight + Style.marginS * 2
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        NText {
          id: pathText
          anchors {
            fill: parent
            margins: Style.marginS
          }
          text: (pluginApi?.tr("panel.file-path") || "Config file:") + " " + (configPath || "~/.config/hypr/keybinds.conf")
          font.pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
          elide: Text.ElideMiddle
        }
      }

      // Editor area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Color.mOutline
        border.width: 1

        Flickable {
          id: flickable
          anchors {
            fill: parent
            margins: Style.marginS
          }
          contentWidth: textEdit.paintedWidth
          contentHeight: textEdit.paintedHeight
          clip: true

          TextEdit {
            id: textEdit
            width: flickable.width
            text: keybindsContent || "# Loading keybinds...\n# If this message persists, check the file path in settings."
            font.pointSize: Style.fontSizeS
            font.family: Settings.data.ui.fontFixed
            color: Color.mOnSurface
            selectionColor: Color.mPrimary
            selectedTextColor: Color.mOnPrimary
            wrapMode: TextEdit.NoWrap
            selectByMouse: true
          }
        }
      }

      // Action buttons
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
          text: pluginApi?.tr("panel.reload") || "Reload"
          icon: "refresh"
          Layout.fillWidth: true
          onClicked: reloadKeybinds()
        }

        NButton {
          text: pluginApi?.tr("panel.save") || "Save Changes"
          icon: "check"
          Layout.fillWidth: true
          onClicked: saveKeybinds()
        }
      }

      // Info text
      NText {
        Layout.fillWidth: true
        text: "Edit your Hyprland keybinds and click Save to apply changes."
        font.pointSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
