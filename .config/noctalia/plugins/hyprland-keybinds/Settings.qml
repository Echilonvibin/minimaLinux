import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string valueConfigPath: cfg.configPath ?? defaults.configPath
  property string valueIconColor: cfg.iconColor ?? defaults.iconColor
  property string valueIconName: cfg.iconName ?? defaults.iconName

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("HyprlandKeybinds", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NComboBox {
      label: pluginApi?.tr("settings.iconColor.label")
      description: pluginApi?.tr("settings.iconColor.desc")
      model: Color.colorKeyModel
      currentKey: root.valueIconColor
      onSelected: key => root.valueIconColor = key
    }

    NTextInput {
      Layout.fillWidth: true
      label: "Icon"
      description: "Icon name (e.g., keyboard, settings, tools, input-gamepad)"
      placeholderText: "keyboard"
      text: root.valueIconName
      onTextChanged: root.valueIconName = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.configPath.label")
      description: pluginApi?.tr("settings.configPath.desc")
      placeholderText: pluginApi?.tr("settings.configPath.placeholder")
      text: root.valueConfigPath
      onTextChanged: root.valueConfigPath = text
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("HyprlandKeybinds", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.configPath = root.valueConfigPath;
    pluginApi.pluginSettings.iconColor = root.valueIconColor;
    pluginApi.pluginSettings.iconName = root.valueIconName;
    pluginApi.saveSettings();

    Logger.d("HyprlandKeybinds", "Settings saved successfully");
  }
}
