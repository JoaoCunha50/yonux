// Package source records which clone `yonux dev-apply` last applied.
package source

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type Source struct {
	Checkout string `json:"checkout"` // absolute path to the clone root
}

func file(state string) string { return filepath.Join(state, "source.json") }

// Load reads the record in state ($XDG_STATE_HOME/yonux); no record is an empty Source.
func Load(state string) (Source, error) {
	var s Source
	b, err := os.ReadFile(file(state))
	if os.IsNotExist(err) {
		return s, nil
	}
	if err != nil {
		return s, fmt.Errorf("read source: %w", err)
	}
	if err := json.Unmarshal(b, &s); err != nil {
		return Source{}, fmt.Errorf("decode source: %w", err)
	}
	if !filepath.IsAbs(s.Checkout) {
		return Source{}, fmt.Errorf("decode source: checkout %q is not an absolute path", s.Checkout)
	}
	return s, nil
}

// Save replaces the record through a temp file and a rename, so a failure never leaves it truncated.
func Save(state string, s Source) error {
	b, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}
	if err := os.MkdirAll(state, 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(state, ".source-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(b); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), file(state))
}
