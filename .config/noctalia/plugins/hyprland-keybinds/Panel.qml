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

  property real contentPreferredWidth: 800 * Style.uiScaleRatio
  property real contentPreferredHeight: 700 * Style.uiScaleRatio

  readonly property bool allowAttach: true

  property var mainComponent: null
  property int filterMode: 0 // 0: all, 1: binds only, 2: variables only

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
  }

  function saveKeybinds() {
    if (mainComponent) {
      mainComponent.saveKeybinds();
    }
  }

  function reloadKeybinds() {
    if (mainComponent) {
      mainComponent.readKeybinds();
    }
  }

  function addNewKeybind() {
    if (mainComponent) {
      mainComponent.addKeybind("SUPER", "", "exec", "", "");
    }
  }

  Connections {
    target: mainComponent
    function onKeybindsListChanged() {
      // Trigger view refresh
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
          icon: "add"
          tooltipText: "Add Keybind"
          onClicked: addNewKeybind()
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

      // Filter tabs
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NButton {
          text: "All"
          onClicked: filterMode = 0
        }

        NButton {
          text: "Keybinds Only"
          onClicked: filterMode = 1
        }

        NButton {
          text: "Variables"
          onClicked: filterMode = 2
        }

        Item { Layout.fillWidth: true }

        NText {
          text: {
            if (!mainComponent || !mainComponent.keybindsList) return "0 items";
            var filtered = getFilteredKeybinds();
            return filtered.length + " item" + (filtered.length !== 1 ? "s" : "");
          }
          color: Color.mOnSurfaceVariant
          font.pointSize: Style.fontSizeS
        }
      }

      // Keybinds list
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusL

        ScrollView {
          anchors.fill: parent
          anchors.margins: Style.marginS
          clip: true

          ListView {
            id: keybindsList
            model: mainComponent ? getFilteredKeybinds() : []
            spacing: Style.marginS

            delegate: Item {
              width: ListView.view.width
              height: delegateContent.height

              property var itemData: modelData

              Rectangle {
                id: delegateContent
                width: parent.width
                height: content.height + Style.marginM * 2
                color: Color.mSurface
                radius: Style.radiusM
                border.color: Color.mOutline
                border.width: 1

                ColumnLayout {
                  id: content
                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Style.marginM
                  }
                  spacing: Style.marginS

                  // Section headers and variables
                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM
                    visible: itemData.type !== "bind"

                    TextField {
                      id: contentField
                      text: itemData.content || ""
                      Layout.fillWidth: true
                      font.pointSize: Style.fontSizeS
                      font.family: Settings.data.ui.fontFixed
                      background: Rectangle {
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS
                      }
                      color: itemData.type === "comment" ? Color.mPrimary : Color.mOnSurface
                      onEditingFinished: {
                        if (mainComponent && text !== itemData.content) {
                          mainComponent.updateKeybind(getActualIndex(index), { content: text });
                        }
                      }
                    }

                    NIconButton {
                      icon: "delete"
                      tooltipText: "Remove"
                      visible: itemData.type !== "empty"
                      onClicked: {
                        if (mainComponent) {
                          mainComponent.removeKeybind(getActualIndex(index));
                        }
                      }
                    }
                  }

                  // Keybind fields
                  GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Style.marginS
                    columnSpacing: Style.marginM
                    visible: itemData.type === "bind"

                    // Modifier
                    NText {
                      text: "Modifier:"
                      color: Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeS
                    }

                    TextField {
                      id: modifierField
                      text: itemData.modifier || ""
                      Layout.fillWidth: true
                      font.pointSize: Style.fontSizeS
                      placeholderText: "e.g., SUPER, SUPER SHIFT"
                      background: Rectangle {
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS
                      }
                      color: Color.mOnSurface
                      onEditingFinished: {
                        if (mainComponent && text !== itemData.modifier) {
                          mainComponent.updateKeybind(getActualIndex(index), { modifier: text });
                        }
                      }
                    }

                    // Key
                    NText {
                      text: "Key:"
                      color: Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeS
                    }

                    TextField {
                      id: keyField
                      text: itemData.key || ""
                      Layout.fillWidth: true
                      font.pointSize: Style.fontSizeS
                      placeholderText: "e.g., Q, Return, Space"
                      background: Rectangle {
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS
                      }
                      color: Color.mOnSurface
                      onEditingFinished: {
                        if (mainComponent && text !== itemData.key) {
                          mainComponent.updateKeybind(getActualIndex(index), { key: text });
                        }
                      }
                    }

                    // Action
                    NText {
                      text: "Action:"
                      color: Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeS
                    }

                    TextField {
                      id: actionField
                      text: itemData.action || ""
                      Layout.fillWidth: true
                      font.pointSize: Style.fontSizeS
                      placeholderText: "e.g., exec, killactive, workspace"
                      background: Rectangle {
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS
                      }
                      color: Color.mOnSurface
                      onEditingFinished: {
                        if (mainComponent && text !== itemData.action) {
                          mainComponent.updateKeybind(getActualIndex(index), { action: text });
                        }
                      }
                    }

                    // Command
                    NText {
                      text: "Command:"
                      color: Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeS
                    }

                    TextField {
                      id: commandField
                      text: itemData.command || ""
                      Layout.fillWidth: true
                      font.pointSize: Style.fontSizeS
                      placeholderText: "Command or parameter"
                      background: Rectangle {
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS
                      }
                      color: Color.mOnSurface
                      onEditingFinished: {
                        if (mainComponent && text !== itemData.command) {
                          mainComponent.updateKeybind(getActualIndex(index), { command: text });
                        }
                      }
                    }

                    // Description
                    NText {
                      text: "Description:"
                      color: Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeS
                    }

                    TextField {
                      id: descriptionField
                      text: itemData.description || ""
                      Layout.fillWidth: true
                      font.pointSize: Style.fontSizeS
                      placeholderText: "Optional description"
                      background: Rectangle {
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS
                      }
                      color: Color.mOnSurface
                      onEditingFinished: {
                        if (mainComponent && text !== itemData.description) {
                          mainComponent.updateKeybind(getActualIndex(index), { description: text });
                        }
                      }
                    }

                    // Delete button
                    Item {
                      Layout.columnSpan: 2
                      Layout.fillWidth: true
                      height: deleteBtn.height

                      NButton {
                        id: deleteBtn
                        text: "Remove Keybind"
                        icon: "delete"
                        anchors.right: parent.right
                        onClicked: {
                          if (mainComponent) {
                            mainComponent.removeKeybind(getActualIndex(index));
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Action buttons
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
          text: "Reload"
          icon: "refresh"
          Layout.fillWidth: true
          onClicked: reloadKeybinds()
        }

        NButton {
          text: "Save Changes"
          icon: "check"
          Layout.fillWidth: true
          onClicked: saveKeybinds()
        }
      }
    }
  }

  function getFilteredKeybinds() {
    if (!mainComponent || !mainComponent.keybindsList) return [];
    
    var list = mainComponent.keybindsList;
    if (filterMode === 0) {
      return list;
    } else if (filterMode === 1) {
      var binds = [];
      for (var i = 0; i < list.length; i++) {
        if (list[i].type === "bind") {
          binds.push(list[i]);
        }
      }
      return binds;
    } else if (filterMode === 2) {
      var vars = [];
      for (var j = 0; j < list.length; j++) {
        if (list[j].type === "variable" || list[j].type === "comment") {
          vars.push(list[j]);
        }
      }
      return vars;
    }
    return list;
  }

  function getActualIndex(filteredIndex) {
    if (filterMode === 0) {
      return filteredIndex;
    }
    
    var filtered = getFilteredKeybinds();
    if (filteredIndex >= filtered.length) return -1;
    
    var targetItem = filtered[filteredIndex];
    var fullList = mainComponent.keybindsList;
    
    for (var i = 0; i < fullList.length; i++) {
      if (fullList[i] === targetItem) {
        return i;
      }
    }
    return -1;
  }
}
