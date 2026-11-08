// Package devapply installs a yonux clone for normal use: it builds the
// binaries into ~/.local/bin, applies the shared configuration and records the source.
package devapply

import (
	"fmt"
	"joaocunha50/yonux-cli/internal/apply"
	"os"
	"os/exec"
	"path/filepath"

	"joaocunha50/yonux-cli/internal/materialize"
	"joaocunha50/yonux-cli/internal/source"
)

// Build compiles the Go module at dir (main in ./cmd) to out.
type Build func(dir, out string) error

type Target struct {
	Layout materialize.Layout // Config and State; Base is set by Run from the clone
	Bin    string             // ~/.local/bin
}

type binary struct {
	Module string // relative to <clone>/yonux, main in ./cmd
	Name   string // installed as <Bin>/<Name>
}

var binaries = []binary{
	{Module: "cli", Name: "yonux"},
	{Module: "shell/ipc", Name: "yonux-ipc"},
}

// Run applies the clone rooted at from. Nothing changes until every binary
// has built; the source is recorded only after everything else succeeded, so a
// failure keeps the previous record (earlier steps are not rolled back).
func Run(from string, t Target, build Build) error {
	from, err := filepath.Abs(from)
	if err != nil {
		return err
	}
	if err := validateClone(from); err != nil {
		return err
	}
	y := filepath.Join(from, "yonux")

	if err := os.MkdirAll(t.Bin, 0o755); err != nil {
		return err
	}
	tmp, err := os.MkdirTemp(t.Bin, ".yonux-build-*")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmp)
	for _, b := range binaries {
		if err := build(filepath.Join(y, b.Module), filepath.Join(tmp, b.Name)); err != nil {
			return fmt.Errorf("build %s: %w", b.Name, err)
		}
	}
	for _, b := range binaries {
		if err := os.Rename(filepath.Join(tmp, b.Name), filepath.Join(t.Bin, b.Name)); err != nil {
			return fmt.Errorf("install %s: %w", b.Name, err)
		}
	}

	t.Layout.Base = y
	if err := apply.Run(t.Layout); err != nil {
		return fmt.Errorf("apply: %w", err)
	}
	if err := source.Save(t.Layout.State, source.Source{Checkout: from}); err != nil {
		return fmt.Errorf("record source: %w", err)
	}
	return nil
}

func validateClone(root string) error {
	y := filepath.Join(root, "yonux")
	var need []string
	for _, b := range binaries {
		need = append(need, filepath.Join(y, b.Module, "go.mod"))
	}
	for _, dir := range []string{"hypr", "shell/quickshell"} {
		need = append(need, filepath.Join(y, dir))
	}
	for _, p := range need {
		if _, err := os.Stat(p); err != nil {
			return fmt.Errorf("%s is not a yonux clone root: missing %s", root, p)
		}
	}
	return nil
}

// GoBuild runs `go build -o out ./cmd` in dir.
func GoBuild(dir, out string) error {
	cmd := exec.Command("go", "build", "-o", out, "./cmd")
	cmd.Dir = dir
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("go build in %s: %w", dir, err)
	}
	return nil
}
