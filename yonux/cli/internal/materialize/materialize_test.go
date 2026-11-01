package materialize

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestMaterializeRejectsPathsOutsideManagedTreesBeforeChangingFiles(t *testing.T) {
	for _, key := range []string{
		"", ".", "..", "../outside", filepath.Join(t.TempDir(), "absolute"),
		"fish/config.fish", "yonux/user_preferences/matugen/config.toml",
		"yonux/matugen", "yonux/matugen/", "yonux/matugen-sibling/file",
		"yonux/matugen/../outside", "yonux/matugen/templates/../../outside",
		"yonux/matugen//file", "yonux/matugen/./file",
	} {
		t.Run(key, func(t *testing.T) {
			l := layout(t, false)
			live := filepath.Join(l.Config, "yonux/matugen/config.toml")
			obsolete := filepath.Join(l.Config, "yonux/matugen/obsolete")
			unrelated := filepath.Join(l.Config, "fish/config.fish")
			write(t, live, "active original")
			write(t, obsolete, "stale original")
			write(t, unrelated, "unrelated original")
			body, err := json.Marshal(map[string]string{key: "", "yonux/matugen/obsolete": ""})
			if err != nil {
				t.Fatal(err)
			}
			write(t, l.manifestPath(), string(body))

			if err := Materialize(l); err == nil || !strings.Contains(err.Error(), "manifest") || !strings.Contains(err.Error(), key) {
				t.Fatalf("expected manifest error identifying %q, got %v", key, err)
			}
			for file, want := range map[string]string{
				live: "active original", obsolete: "stale original", unrelated: "unrelated original", l.manifestPath(): string(body),
			} {
				if got := read(t, file); got != want {
					t.Fatalf("invalid manifest changed %s: %q", file, got)
				}
			}
			if _, err := os.Lstat(filepath.Join(l.Config, "yonux/matugen/templates/fish")); !os.IsNotExist(err) {
				t.Fatalf("invalid manifest created a destination: %v", err)
			}
		})
	}
}

func TestMaterializeRejectsUnreadableOrInvalidManifest(t *testing.T) {
	for _, body := range []string{"", "{", "null", "[]", `{"yonux/matugen/config.toml":123}`} {
		t.Run(body, func(t *testing.T) {
			l := layout(t, false)
			live := filepath.Join(l.Config, "yonux/matugen/config.toml")
			write(t, live, "unchanged")
			write(t, l.manifestPath(), body)

			if err := Materialize(l); err == nil || !strings.Contains(err.Error(), "manifest") {
				t.Fatalf("expected manifest error, got %v", err)
			}
			if got := read(t, live); got != "unchanged" {
				t.Fatalf("invalid manifest changed live config: %q", got)
			}
			if got := read(t, l.manifestPath()); got != body {
				t.Fatalf("invalid manifest was overwritten: %q", got)
			}
		})
	}
	t.Run("read_error", func(t *testing.T) {
		l := layout(t, false)
		live := filepath.Join(l.Config, "yonux/matugen/config.toml")
		write(t, live, "unchanged")
		if err := os.MkdirAll(l.manifestPath(), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := Materialize(l); err == nil || !strings.Contains(err.Error(), "manifest") {
			t.Fatalf("expected manifest read error, got %v", err)
		}
		if got := read(t, live); got != "unchanged" {
			t.Fatalf("manifest read error changed live config: %q", got)
		}
	})
}

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

func TestMaterializePruningKeepsManagedRootAndAncestors(t *testing.T) {
	l := layout(t, false)
	mustMaterialize(t, l)
	if err := os.RemoveAll(filepath.Join(l.Base, "shell/matugen")); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	for _, dir := range []string{l.Config, filepath.Join(l.Config, "yonux"), filepath.Join(l.Config, "yonux/matugen")} {
		if info, err := os.Stat(dir); err != nil || !info.IsDir() {
			t.Fatalf("pruning removed root or ancestor %s: %v", dir, err)
		}
	}
	entries, err := os.ReadDir(filepath.Join(l.Config, "yonux/matugen"))
	if err != nil || len(entries) != 0 {
		t.Fatalf("expected an empty managed root, got %v: %v", entries, err)
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
