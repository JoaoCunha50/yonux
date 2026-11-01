package materialize

import (
	"os"
	"path/filepath"
	"testing"
)

func write(t *testing.T, p, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

func read(t *testing.T, p string) string {
	t.Helper()
	b, err := os.ReadFile(p)
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}

func layout(t *testing.T, link bool) Layout {
	dir := t.TempDir()
	l := Layout{
		Base:   filepath.Join(dir, "base"),
		Config: filepath.Join(dir, "config"),
		State:  filepath.Join(dir, "state"),
		Link:   link,
	}
	write(t, filepath.Join(l.Base, "shell/matugen/config.toml"), "base config")
	write(t, filepath.Join(l.Base, "shell/matugen/templates/fish"), "base fish")
	return l
}

func mustMaterialize(t *testing.T, l Layout) {
	t.Helper()
	if err := Materialize(l); err != nil {
		t.Fatal(err)
	}
}

func TestMaterializeCopiesAndUpdates(t *testing.T) {
	l := layout(t, false)
	live := filepath.Join(l.Config, "yonux/matugen/config.toml")

	mustMaterialize(t, l)
	if got := read(t, live); got != "base config" {
		t.Fatalf("live = %q", got)
	}

	write(t, filepath.Join(l.Base, "shell/matugen/config.toml"), "new base")
	mustMaterialize(t, l)
	if got := read(t, live); got != "new base" {
		t.Fatalf("update not laid: %q", got)
	}
}

func TestMaterializePreferenceWins(t *testing.T) {
	l := layout(t, false)
	write(t, filepath.Join(l.Preferences(), "matugen/config.toml"), "mine")
	write(t, filepath.Join(l.Preferences(), "matugen/templates/extra"), "extra")

	mustMaterialize(t, l)
	if got := read(t, filepath.Join(l.Config, "yonux/matugen/config.toml")); got != "mine" {
		t.Fatalf("preference lost: %q", got)
	}
	if got := read(t, filepath.Join(l.Config, "yonux/matugen/templates/extra")); got != "extra" {
		t.Fatalf("added file missing: %q", got)
	}

	os.Remove(filepath.Join(l.Preferences(), "matugen/config.toml"))
	os.Remove(filepath.Join(l.Preferences(), "matugen/templates/extra"))
	mustMaterialize(t, l)
	if got := read(t, filepath.Join(l.Config, "yonux/matugen/config.toml")); got != "base config" {
		t.Fatalf("default not restored: %q", got)
	}
	if exists(filepath.Join(l.Config, "yonux/matugen/templates/extra")) {
		t.Fatal("removed preference was not pruned")
	}
}

func TestMaterializeOverwritesHandEdits(t *testing.T) {
	for _, link := range []bool{false, true} {
		t.Run(map[bool]string{false: "copy", true: "dev_link"}[link], func(t *testing.T) {
			l := layout(t, link)
			live := filepath.Join(l.Config, "yonux/matugen/config.toml")
			mustMaterialize(t, l)

			// Replace the active entry so a dev symlink does not edit the base.
			if err := os.Remove(live); err != nil {
				t.Fatal(err)
			}
			write(t, live, "hand edit")
			write(t, filepath.Join(l.Base, "shell/matugen/config.toml"), "new base")
			mustMaterialize(t, l)

			if got := read(t, live); got != "new base" {
				t.Fatalf("active edit was not replaced: %q", got)
			}
			if _, err := os.Lstat(l.Preferences()); !os.IsNotExist(err) {
				t.Fatalf("active edit created preferences: %v", err)
			}
		})
	}
}

func TestMaterializePrunesDroppedFiles(t *testing.T) {
	l := layout(t, false)
	mustMaterialize(t, l)

	write(t, filepath.Join(l.Config, "yonux/matugen/templates/fish"), "hand edit")
	if err := os.RemoveAll(filepath.Join(l.Base, "shell/matugen/templates")); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	if exists(filepath.Join(l.Config, "yonux/matugen/templates")) {
		t.Fatal("dropped file or its empty dir was not pruned")
	}
	if _, err := os.Lstat(l.Preferences()); !os.IsNotExist(err) {
		t.Fatalf("dropped active edit created preferences: %v", err)
	}
}

func TestMaterializeRestoresPreferencesOverActiveEdits(t *testing.T) {
	for _, link := range []bool{false, true} {
		t.Run(map[bool]string{false: "copy", true: "dev_link"}[link], func(t *testing.T) {
			l := layout(t, link)
			pref := filepath.Join(l.Preferences(), "matugen/config.toml")
			live := filepath.Join(l.Config, "yonux/matugen/config.toml")
			write(t, pref, "my preferences")
			mustMaterialize(t, l)

			write(t, live, "active edit")
			mustMaterialize(t, l)
			if got := read(t, live); got != "my preferences" {
				t.Fatalf("preferences did not replace active edit: %q", got)
			}
			if got := read(t, pref); got != "my preferences" {
				t.Fatalf("preferences were modified: %q", got)
			}
			if got := read(t, filepath.Join(l.Base, "shell/matugen/config.toml")); got != "base config" {
				t.Fatalf("base was modified: %q", got)
			}
		})
	}
}

func TestMaterializeLinkMode(t *testing.T) {
	l := layout(t, true)
	live := filepath.Join(l.Config, "yonux/matugen/config.toml")
	write(t, filepath.Join(l.Preferences(), "matugen/templates/fish"), "my fish")

	mustMaterialize(t, l)
	target, err := os.Readlink(live)
	if err != nil || target != filepath.Join(l.Base, "shell/matugen/config.toml") {
		t.Fatalf("not linked into base: %q %v", target, err)
	}

	write(t, filepath.Join(l.Base, "shell/matugen/config.toml"), "edited in repo")
	if got := read(t, live); got != "edited in repo" {
		t.Fatalf("repo edit not live: %q", got)
	}

	fish := filepath.Join(l.Config, "yonux/matugen/templates/fish")
	if info, _ := os.Lstat(fish); info.Mode()&os.ModeSymlink != 0 {
		t.Fatal("preference should be a copy, not a link")
	}
	if got := read(t, filepath.Join(l.Base, "shell/matugen/templates/fish")); got != "base fish" {
		t.Fatalf("preference wrote through into the repo: %q", got)
	}
}
