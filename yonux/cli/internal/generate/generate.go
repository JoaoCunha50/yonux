// Package generate renders the settings stores without starting the shell or
// contacting Hyprland. Its inputs are the same stores used by the settings window.
package generate

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"joaocunha50/yonux-cli/internal/materialize"
)

// Run regenerates hyprland.lua and keybindings.lua in Config/yonux. Missing
// stores use the shipped defaults; stores are never created or rewritten here.
// Both inputs are rendered before either output is changed, so malformed stores
// leave the previous generated configuration intact.
func Run(l materialize.Layout) error {
	dir := filepath.Join(l.Config, "yonux")
	hypr, err := renderHypr(filepath.Join(l.Base, "shell", "quickshell", "config", "HyprSettings.qml"), filepath.Join(dir, "hypr.json"))
	if err != nil {
		return err
	}
	bindings, err := renderKeybindings(filepath.Join(dir, "keybindings.json"))
	if err != nil {
		return err
	}
	for _, output := range []struct{ name, text string }{
		{"hyprland.lua", hypr}, {"keybindings.lua", bindings},
	} {
		if err := writeOutput(filepath.Join(dir, output.name), output.text); err != nil {
			return fmt.Errorf("write %s: %w", output.name, err)
		}
	}
	return nil
}

func readStore(path string) (map[string]json.RawMessage, error) {
	body, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return map[string]json.RawMessage{}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	if !json.Valid(body) {
		return nil, fmt.Errorf("decode %s: invalid JSON", path)
	}
	// JsonConfig applies defaults to null and to documents whose indexed
	// properties do not contain setting keys (arrays and JSON primitives).
	body = bytes.TrimSpace(body)
	if body[0] != '{' {
		return map[string]json.RawMessage{}, nil
	}
	var document map[string]json.RawMessage
	if err := json.Unmarshal(body, &document); err != nil {
		return nil, fmt.Errorf("decode %s: %w", path, err)
	}
	return document, nil
}

// Rename replaces a stale symlink rather than writing through it into a checkout.
func writeOutput(path, text string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	file, err := os.CreateTemp(filepath.Dir(path), ".yonux-generate-*")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	if _, err := file.WriteString(text); err != nil {
		file.Close()
		return err
	}
	if err := file.Chmod(0o644); err != nil {
		file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	return os.Rename(file.Name(), path)
}
