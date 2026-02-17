import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: mainRoot
  property var pluginApi: null

  property string keybindsContent: ""
  property var keybindsList: []
  property string configPath: {
    var homeDir = Quickshell.env("HOME") || "";
    var defaultPath = "~/.config/hypr/keybinds.conf";
    var path = pluginApi?.pluginSettings?.configPath || pluginApi?.manifest?.metadata?.defaultSettings?.configPath || defaultPath;
    return path.replace("~", homeDir);
  }

  Component.onCompleted: {
    readKeybinds();
  }

  Process {
    id: readProcess
    running: false
    command: ["sh", "-c", "cat '" + configPath + "'"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    
    onExited: function(exitCode) {
      var stdoutText = String(readProcess.stdout.text || "");
      var stderrText = String(readProcess.stderr.text || "");
      if (exitCode === 0) {
        mainRoot.keybindsContent = stdoutText;
        mainRoot.parseKeybinds(stdoutText);
        if (mainRoot.keybindsContent.length > 0) {
          ToastService.showNotice("Keybinds loaded");
        }
      } else {
        mainRoot.keybindsContent = "# Error reading file: " + configPath + "\n# " + stderrText;
        ToastService.showError("Failed to read keybinds file");
      }
    }
  }

  Process {
    id: writeProcess
    running: false
    command: []
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    
    property string contentToWrite: ""
    property string targetPath: ""
    
    onExited: function(exitCode) {
      if (exitCode === 0) {
        mainRoot.readKeybinds();
        ToastService.showNotice("Keybinds saved successfully");
      } else {
        var stderrText = String(writeProcess.stderr.text || "");
        ToastService.showError("Failed to save keybinds: " + stderrText);
      }
      contentToWrite = "";
      targetPath = "";
    }
  }

  function parseKeybinds(content) {
    var lines = content.split("\n");
    var parsed = [];
    
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var trimmed = line.trim();
      
      // Check if it's a bind statement
      if (trimmed.startsWith("bind = ") || trimmed.startsWith("bind=")) {
        // Find the content after "bind = " or "bind="
        var bindStart = line.indexOf("bind");
        var eqPos = line.indexOf("=", bindStart);
        if (eqPos === -1) continue;
        
        var bindContent = line.substring(eqPos + 1).trim();
        var description = "";
        
        // Extract description from comment (format: #"description")
        var commentMatch = bindContent.match(/#"([^"]*)"/);
        if (commentMatch) {
          description = commentMatch[1];
          // Remove the comment part from bindContent
          var commentPos = bindContent.indexOf('#');
          bindContent = bindContent.substring(0, commentPos).trim();
        }
        
        // Split by comma - first 3 are modifier, key, action; rest is command
        var components = bindContent.split(",");
        if (components.length >= 2) {
          var modifier = components[0].trim();
          var key = components[1].trim();
          var action = components.length > 2 ? components[2].trim() : "";
          // Everything from component 3 onward is the command (rejoin with comma)
          var command = components.length > 3 ? components.slice(3).join(",").trim() : "";
          
          parsed.push({
            type: "bind",
            modifier: modifier,
            key: key,
            action: action,
            command: command,
            description: description,
            originalLine: line
          });
        }
      } else if (trimmed.length > 0) {
        // Store as raw line (comment or variable), skip empty lines
        parsed.push({
          type: trimmed.startsWith("#") ? "comment" : (trimmed.startsWith("$") ? "variable" : "comment"),
          content: line,
          originalLine: line
        });
      }
    }
    
    mainRoot.keybindsList = parsed;
  }

  function rebuildContent() {
    var lines = [];
    for (var i = 0; i < keybindsList.length; i++) {
      var item = keybindsList[i];
      if (item.type === "bind") {
        var line = "bind = " + item.modifier + ", " + item.key;
        if (item.action) {
          line += ", " + item.action;
          if (item.command) {
            line += ", " + item.command;
          }
        }
        if (item.description) {
          line += ' #"' + item.description + '"';
        }
        lines.push(line);
      } else {
        lines.push(item.content);
      }
    }
    return lines.join("\n");
  }

  function readKeybinds() {
    readProcess.running = true;
    return keybindsContent;
  }

  function saveKeybinds() {
    var content = rebuildContent();
    // Encode content as base64 to avoid shell escaping issues
    var base64Content = Qt.btoa(content);
    
    writeProcess.contentToWrite = content;
    writeProcess.targetPath = configPath;
    writeProcess.command = ["sh", "-c", "echo '" + base64Content + "' | base64 -d > '" + configPath + "'"];
    writeProcess.running = true;
    return true;
  }

  function updateKeybind(index, newData) {
    if (index >= 0 && index < keybindsList.length) {
      var item = keybindsList[index];
      item.modifier = newData.modifier || item.modifier;
      item.key = newData.key || item.key;
      item.action = newData.action || item.action;
      item.command = newData.command || item.command;
      item.description = newData.description || item.description;
      item.content = newData.content !== undefined ? newData.content : item.content;
      keybindsList[index] = item;
      keybindsListChanged();
    }
  }

  function addKeybind(modifier, key, action, command, description) {
    var newBind = {
      type: "bind",
      modifier: modifier || "SUPER",
      key: key || "",
      action: action || "exec",
      command: command || "",
      description: description || "",
      originalLine: ""
    };
    var newList = keybindsList.slice();
    newList.push(newBind);
    keybindsList = newList;
  }

  function removeKeybind(index) {
    if (index >= 0 && index < keybindsList.length) {
      var newList = [];
      for (var i = 0; i < keybindsList.length; i++) {
        if (i !== index) {
          newList.push(keybindsList[i]);
        }
      }
      keybindsList = newList;
    }
  }

  // Legacy function for backward compatibility
  function writeKeybinds(content) {
    // Encode content as base64 to avoid shell escaping issues
    var base64Content = Qt.btoa(content);
    
    writeProcess.contentToWrite = content;
    writeProcess.targetPath = configPath;
    writeProcess.command = ["sh", "-c", "echo '" + base64Content + "' | base64 -d > '" + configPath + "'"];
    writeProcess.running = true;
    return true;
  }

  IpcHandler {
    target: "plugin:hyprland-keybinds"
    function reload() {
      if (pluginApi) {
        mainRoot.readKeybinds();
        ToastService.showNotice("Keybinds reloaded");
      }
    }
    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function(screen) {
          pluginApi.openPanel(screen);
        });
      }
    }
  }
}