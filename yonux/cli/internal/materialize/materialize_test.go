package materialize

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"joaocunha50/yonux-cli/internal/source"
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
			l := layout(t)
			live := filepath.Join(l.Config, "yonux/matugen/config.toml")
			obsolete := filepath.Join(l.Config, "yonux/matugen/obsolete")
			unrelated := filepath.Join(l.Config, "fish/config.fish")
			write(t, live, "active original")
			write(t, obsolete, "stale original")
			write(t, unrelated, "unrelated original")
			body, err := json.Marshal([]string{key, "yonux/matugen/obsolete"})
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
	for _, body := range []string{"", "{", "null", "{}", `[123]`} {
		t.Run(body, func(t *testing.T) {
			l := layout(t)
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
		l := layout(t)
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

func layout(t *testing.T) Layout {
	dir := t.TempDir()
	l := Layout{
		Base:   filepath.Join(dir, "base"),
		Config: filepath.Join(dir, "config"),
		State:  filepath.Join(dir, "state"),
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
	l := layout(t)
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
	l := layout(t)
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
	l := layout(t)
	live := filepath.Join(l.Config, "yonux/matugen/config.toml")
	mustMaterialize(t, l)

	write(t, live, "hand edit")
	write(t, filepath.Join(l.Base, "shell/matugen/config.toml"), "new base")
	mustMaterialize(t, l)

	if got := read(t, live); got != "new base" {
		t.Fatalf("active edit was not replaced: %q", got)
	}
	if _, err := os.Lstat(l.Preferences()); !os.IsNotExist(err) {
		t.Fatalf("active edit created preferences: %v", err)
	}
}

func TestMaterializePrunesDroppedFiles(t *testing.T) {
	l := layout(t)
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
	l := layout(t)
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
	l := layout(t)
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
}

// A live file that is a symlink into a clone (the old dev install) becomes a
// copy, and the clone is never written through.
func TestMaterializeReplacesSymlinkWithCopy(t *testing.T) {
	l := layout(t)
	shipped := filepath.Join(l.Base, "shell/matugen/config.toml")
	live := filepath.Join(l.Config, "yonux/matugen/config.toml")
	if err := os.MkdirAll(filepath.Dir(live), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(shipped, live); err != nil {
		t.Fatal(err)
	}
	write(t, filepath.Join(l.Preferences(), "matugen/config.toml"), "mine")

	mustMaterialize(t, l)
	if info, err := os.Lstat(live); err != nil || !info.Mode().IsRegular() {
		t.Fatalf("live file is not a regular copy: %v", err)
	}
	if got := read(t, live); got != "mine" {
		t.Fatalf("live = %q", got)
	}
	if got := read(t, shipped); got != "base config" {
		t.Fatalf("materialize wrote through into the clone: %q", got)
	}
}

func TestMaterializeRecordsLaidPaths(t *testing.T) {
	l := layout(t)
	mustMaterialize(t, l)
	var got []string
	if err := json.Unmarshal([]byte(read(t, l.manifestPath())), &got); err != nil {
		t.Fatal(err)
	}
	want := []string{"yonux/matugen/config.toml", "yonux/matugen/templates/fish"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("manifest = %v, want %v", got, want)
	}
}

func userDirs(t *testing.T) (state string) {
	dir := t.TempDir()
	t.Setenv("HOME", dir)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(dir, "config"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(dir, "state"))
	t.Setenv("YONUX_BASE", "")
	return filepath.Join(dir, "state", "yonux")
}

func registerClone(t *testing.T, state string) string {
	clone := filepath.Join(t.TempDir(), "clone")
	if err := os.MkdirAll(filepath.Join(clone, "yonux"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := source.Save(state, source.Source{Checkout: clone}); err != nil {
		t.Fatal(err)
	}
	return clone
}

func TestDefaultLayoutBaseOverrideWinsForOneRun(t *testing.T) {
	state := userDirs(t)
	registerClone(t, state)
	t.Setenv("YONUX_BASE", "/tmp/override/yonux")

	l, err := DefaultLayout()
	if err != nil || l.Base != "/tmp/override/yonux" {
		t.Fatalf("Base = %q, %v", l.Base, err)
	}
	if s, _ := source.Load(state); s.Checkout == "/tmp/override" {
		t.Fatal("YONUX_BASE changed the recorded checkout")
	}
}

func TestDefaultLayoutUsesRegisteredCheckout(t *testing.T) {
	state := userDirs(t)
	clone := registerClone(t, state)

	l, err := DefaultLayout()
	if err != nil || l.Base != filepath.Join(clone, "yonux") {
		t.Fatalf("Base = %q, %v", l.Base, err)
	}
	if l.State != state {
		t.Fatalf("State = %q", l.State)
	}
}

func TestDefaultLayoutFailsWhenRegisteredCheckoutIsGone(t *testing.T) {
	state := userDirs(t)
	clone := registerClone(t, state)
	if err := os.RemoveAll(clone); err != nil {
		t.Fatal(err)
	}
	if _, err := DefaultLayout(); err == nil || !strings.Contains(err.Error(), clone) {
		t.Fatalf("expected an error naming %s, got %v", clone, err)
	}
}

func TestDefaultLayoutFallsBackToInstalledShare(t *testing.T) {
	userDirs(t)
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	exe, _ = filepath.EvalSymlinks(exe)

	l, err := DefaultLayout()
	if err != nil || l.Base != filepath.Join(filepath.Dir(exe), "..", "share", "yonux") {
		t.Fatalf("Base = %q, %v", l.Base, err)
	}
}
