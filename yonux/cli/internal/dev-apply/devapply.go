// Package devapply installs a yonux clone for normal use: it builds the
// binaries into ~/.local/bin, copies the clone's config into ~/.config,
// materializes Matugen from it, and records the clone as the source.
package devapply

import (
	"fmt"
	"io/fs"
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

type tree struct {
	Src  string   // relative to <clone>/yonux
	Dst  string   // relative to Config
	Keep []string // live files carried over, never taken from Src
}

var trees = []tree{
	{Src: "hypr", Dst: "hypr", Keep: []string{"user.lua"}},
	{Src: "shell/quickshell", Dst: "quickshell/yonux"},
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

	for _, tr := range trees {
		if err := replaceTree(filepath.Join(y, tr.Src), filepath.Join(t.Layout.Config, tr.Dst), tr.Keep); err != nil {
			return fmt.Errorf("apply %s: %w", tr.Dst, err)
		}
	}

	t.Layout.Base = y
	if err := materialize.Materialize(t.Layout); err != nil {
		return fmt.Errorf("materialize: %w", err)
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
	for _, t := range trees {
		need = append(need, filepath.Join(y, t.Src))
	}
	for _, p := range need {
		if _, err := os.Stat(p); err != nil {
			return fmt.Errorf("%s is not a yonux clone root: missing %s", root, p)
		}
	}
	return nil
}

// replaceTree swaps dst for a copy of src's regular files (symlinks are
// skipped), carrying each keep file over from the live dst. A dst that is a
// symlink is unlinked, never written through.
func replaceTree(src, dst string, keep []string) error {
	parent := filepath.Dir(dst)
	if err := os.MkdirAll(parent, 0o755); err != nil {
		return err
	}
	tmp, err := os.MkdirTemp(parent, ".yonux-new-*")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmp)
	if err := os.Chmod(tmp, 0o755); err != nil {
		return err
	}

	kept := map[string]bool{}
	for _, name := range keep {
		kept[name] = true
	}
	err = filepath.WalkDir(src, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(src, p)
		switch {
		case d.IsDir():
			return os.MkdirAll(filepath.Join(tmp, rel), 0o755)
		case !d.Type().IsRegular() || kept[rel]:
			return nil
		}
		return copyFile(p, filepath.Join(tmp, rel))
	})
	if err != nil {
		return err
	}
	for _, name := range keep {
		live := filepath.Join(dst, name)
		if info, err := os.Stat(live); err == nil && info.Mode().IsRegular() {
			if err := copyFile(live, filepath.Join(tmp, name)); err != nil {
				return fmt.Errorf("keep %s: %w", name, err)
			}
		}
	}

	// Move the live tree aside first, so a failed swap can put it back. A
	// symlinked dst is moved and removed as a link, never followed.
	old := ""
	if _, err := os.Lstat(dst); err == nil {
		old = tmp + ".old"
		if err := os.Rename(dst, old); err != nil {
			return err
		}
	}
	if err := os.Rename(tmp, dst); err != nil {
		if old != "" {
			_ = os.Rename(old, dst)
		}
		return err
	}
	if old != "" {
		return os.RemoveAll(old)
	}
	return nil
}

func copyFile(src, dst string) error {
	info, err := os.Stat(src)
	if err != nil {
		return err
	}
	b, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(dst, b, info.Mode().Perm()); err != nil {
		return err
	}
	return os.Chmod(dst, info.Mode().Perm())
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
