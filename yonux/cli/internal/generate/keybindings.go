package generate

import (
	"encoding/json"
	"fmt"
	"strings"
)

type binding struct {
	id       string
	keys     string
	title    string
	kind     string
	command  string
	appID    string
	terminal bool
	enabled  bool
}

func renderKeybindings(path string) (string, error) {
	document, err := readStore(path)
	if err != nil {
		return "", err
	}
	groups := make([][]binding, 2)
	needsApps := false
	for i, key := range []string{"overrides", "custom"} {
		raw, ok := document[key]
		if !ok {
			continue
		}
		var entries []any
		if err := json.Unmarshal(raw, &entries); err != nil {
			continue // JsonConfig defaults a non-array group to [].
		}
		for _, entry := range entries {
			if b, valid := validBinding(entry); valid {
				groups[i] = append(groups[i], b)
				needsApps = needsApps || b.kind == "app"
			}
		}
	}
	var apps map[string]desktopApp
	if needsApps {
		apps = applications()
	}
	// Keep the data-only format and quoting from KeybindingUtils.js. Built-in
	// defaults are deliberately NOT duplicated here: hypr/modules/keybindings.lua
	// applies these overrides on top of its own registered default bindings.
	var output strings.Builder
	output.WriteString("-- Generated from keybindings.json by yonux. Data only.\nreturn { overrides = {\n    ")
	for i, group := range groups {
		if i == 1 {
			output.WriteString("\n}, custom = {\n    ")
		}
		for j, b := range group {
			if j > 0 {
				output.WriteString(",\n    ")
			}
			command, available := bindingCommand(b, apps)
			fmt.Fprintf(&output, "{ id = %s, keys = %s, title = %s, kind = %s, enabled = %t, command = %s }", luaQuote(b.id), luaQuote(b.keys), luaQuote(b.title), luaQuote(b.kind), b.enabled && available, luaQuote(command))
		}
	}
	output.WriteString("\n} }\n")
	return output.String(), nil
}

// Match Keybindings.validEntry: invalid array members are ignored, while valid
// neighboring shortcuts and the other group still render.
func validBinding(value any) (binding, bool) {
	entry, ok := value.(map[string]any)
	if !ok {
		return binding{}, false
	}
	var b binding
	for _, field := range []struct {
		key string
		dst *string
	}{
		{"id", &b.id}, {"keys", &b.keys}, {"title", &b.title},
		{"kind", &b.kind}, {"command", &b.command},
	} {
		*field.dst, ok = entry[field.key].(string)
		if !ok {
			return binding{}, false
		}
	}
	b.enabled, ok = entry["enabled"].(bool)
	if !ok {
		return binding{}, false
	}
	b.terminal = jsTruthy(entry["terminal"])
	switch b.kind {
	case "default", "command":
	case "app":
		b.appID, ok = entry["appId"].(string)
		if !ok {
			return binding{}, false
		}
	default:
		return binding{}, false
	}
	return b, true
}

func bindingCommand(b binding, apps map[string]desktopApp) (string, bool) {
	switch b.kind {
	case "default":
		return "", true
	case "command":
		command := "'sh' '-c' " + shellQuote(b.command)
		if b.terminal {
			command = "'xdg-terminal-exec' " + command
		}
		return command, true
	default:
		app, ok := apps[b.appID]
		if !ok || len(app.command) == 0 {
			return "", false
		}
		command := shellCommand(app.command)
		if app.terminal {
			command = shellQuote("xdg-terminal-exec") + " " + command
		}
		if app.directory != "" {
			command = "cd " + shellQuote(app.directory) + " && " + command
		}
		return command, true
	}
}

func jsTruthy(value any) bool {
	switch value := value.(type) {
	case nil:
		return false
	case bool:
		return value
	case string:
		return value != ""
	case float64:
		return value != 0
	default:
		return true
	}
}

func shellQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'"
}

func shellCommand(argv []string) string {
	var output strings.Builder
	for i, argument := range argv {
		if i > 0 {
			output.WriteByte(' ')
		}
		output.WriteString(shellQuote(argument))
	}
	return output.String()
}

func luaQuote(value string) string {
	var output strings.Builder
	output.WriteByte('"')
	for _, char := range value {
		switch {
		case char == '\\' || char == '"':
			output.WriteByte('\\')
			output.WriteRune(char)
		case char < 32 || char == 127:
			fmt.Fprintf(&output, "\\%03d", char)
		default:
			output.WriteRune(char)
		}
	}
	output.WriteByte('"')
	return output.String()
}
