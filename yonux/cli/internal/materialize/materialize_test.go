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
		"hypr/user.lua", "hypr/user.lua/child", "xdg-desktop-portal/other.conf",
		"xdg-desktop-portal/hyprland-portals.conf/child",
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
	write(t, filepath.Join(l.Base, "hypr/hyprland.lua"), "base hypr")
	write(t, filepath.Join(l.Base, "hypr/user.lua"), "clone user config")
	write(t, filepath.Join(l.Base, "shell/quickshell/shell.qml"), "base shell")
	write(t, filepath.Join(l.Base, "portals/hyprland-portals.conf"), "base portals")
	write(t, filepath.Join(l.Base, "portals/unrelated.conf"), "not managed")
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
	var got struct {
		Files []string `json:"files"`
	}
	if err := json.Unmarshal([]byte(read(t, l.manifestPath())), &got); err != nil {
		t.Fatal(err)
	}
	want := []string{
		"hypr/hyprland.lua", "quickshell/yonux/shell.qml",
		"xdg-desktop-portal/hyprland-portals.conf",
		"yonux/matugen/config.toml", "yonux/matugen/templates/fish",
	}
	if strings.Join(got.Files, ",") != strings.Join(want, ",") {
		t.Fatalf("manifest files = %v, want %v", got.Files, want)
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

func backupPaths(t *testing.T, l Layout) map[string]string {
	t.Helper()
	var m struct {
		Backups []struct {
			Path   string `json:"path"`
			Backup string `json:"backup"`
		} `json:"backups"`
	}
	if err := json.Unmarshal([]byte(read(t, filepath.Join(l.State, "materialize.json"))), &m); err != nil {
		t.Fatal(err)
	}
	paths := map[string]string{}
	for _, backup := range m.Backups {
		if _, duplicate := paths[backup.Path]; duplicate {
			t.Fatalf("duplicate backup for %s", backup.Path)
		}
		if !strings.HasPrefix(backup.Backup, "backups/") ||
			!strings.HasSuffix(backup.Backup, "/"+backup.Path) {
			t.Fatalf("backup does not retain config-relative path: %+v", backup)
		}
		paths[backup.Path] = filepath.Join(l.State, filepath.FromSlash(backup.Backup))
	}
	return paths
}

func TestMaterializeBacksUpUnmanagedCollisionsOnlyOnce(t *testing.T) {
	l := layout(t)
	originals := map[string]string{
		"hypr/hyprland.lua":                        "my hypr",
		"quickshell/yonux/shell.qml":               "my shell",
		"yonux/matugen/config.toml":                "my matugen",
		"xdg-desktop-portal/hyprland-portals.conf": "my portals",
	}
	for key, body := range originals {
		write(t, filepath.Join(l.Config, key), body)
	}
	mustMaterialize(t, l)
	first := backupPaths(t, l)
	if len(first) != len(originals) {
		t.Fatalf("backups = %v", first)
	}
	for key, body := range originals {
		if got := read(t, first[key]); got != body {
			t.Fatalf("backup %s = %q, want %q", key, got, body)
		}
		write(t, filepath.Join(l.Config, key), "edit owned file")
	}
	mustMaterialize(t, l)
	second := backupPaths(t, l)
	if len(second) != len(first) {
		t.Fatalf("repeat apply added backups: %v", second)
	}
	for key, backup := range first {
		if second[key] != backup || read(t, backup) != originals[key] {
			t.Fatalf("repeat apply changed original backup for %s", key)
		}
	}
}

func TestMaterializePreservesLocalAndUnrelatedFiles(t *testing.T) {
	l := layout(t)
	untouched := map[string]string{
		"hypr/user.lua":                   "local user",
		"hypr/third-party.lua":            "third-party hypr",
		"quickshell/other/shell.qml":      "another shell",
		"quickshell/yonux/local.qml":      "third-party shell",
		"yonux/matugen/templates/local":   "third-party template",
		"xdg-desktop-portal/portals.conf": "other portal preferences",
	}
	for key, body := range untouched {
		write(t, filepath.Join(l.Config, key), body)
	}
	write(t, filepath.Join(l.Preferences(), "hypr/user.lua"), "must not replace local")
	write(t, filepath.Join(l.Preferences(), "portals/portals.conf"), "must not replace other portals")
	mustMaterialize(t, l)
	mustMaterialize(t, l)
	for key, body := range untouched {
		if got := read(t, filepath.Join(l.Config, key)); got != body {
			t.Fatalf("%s changed: %q", key, got)
		}
	}
	if _, err := os.Lstat(filepath.Join(l.Config, "xdg-desktop-portal/unrelated.conf")); !os.IsNotExist(err) {
		t.Fatalf("unrelated shipped portal was installed: %v", err)
	}
	if got := backupPaths(t, l); len(got) != 0 {
		t.Fatalf("unmodified third-party files were backed up: %v", got)
	}
}

func TestMaterializeAllOverlaysAndPruning(t *testing.T) {
	l := layout(t)
	for _, tc := range []struct{ preference, live, original string }{
		{"hypr/hyprland.lua", "hypr/hyprland.lua", "base hypr"},
		{"quickshell/shell.qml", "quickshell/yonux/shell.qml", "base shell"},
		{"matugen/config.toml", "yonux/matugen/config.toml", "base config"},
		{"portals/hyprland-portals.conf", "xdg-desktop-portal/hyprland-portals.conf", "base portals"},
	} {
		write(t, filepath.Join(l.Preferences(), tc.preference), "preferred "+tc.preference)
	}
	for _, tc := range []struct{ preference, live string }{
		{"hypr/modules/extra.lua", "hypr/modules/extra.lua"},
		{"quickshell/modules/extra.qml", "quickshell/yonux/modules/extra.qml"},
		{"matugen/templates/extra", "yonux/matugen/templates/extra"},
	} {
		write(t, filepath.Join(l.Preferences(), tc.preference), "added")
	}
	mustMaterialize(t, l)
	for _, tc := range []struct{ preference, live, original string }{
		{"hypr/hyprland.lua", "hypr/hyprland.lua", "base hypr"},
		{"quickshell/shell.qml", "quickshell/yonux/shell.qml", "base shell"},
		{"matugen/config.toml", "yonux/matugen/config.toml", "base config"},
		{"portals/hyprland-portals.conf", "xdg-desktop-portal/hyprland-portals.conf", "base portals"},
	} {
		if got := read(t, filepath.Join(l.Config, tc.live)); got != "preferred "+tc.preference {
			t.Fatalf("overlay %s = %q", tc.preference, got)
		}
		if err := os.Remove(filepath.Join(l.Preferences(), tc.preference)); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.RemoveAll(l.Preferences()); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	for key, want := range map[string]string{
		"hypr/hyprland.lua":                        "base hypr",
		"quickshell/yonux/shell.qml":               "base shell",
		"yonux/matugen/config.toml":                "base config",
		"xdg-desktop-portal/hyprland-portals.conf": "base portals",
	} {
		if got := read(t, filepath.Join(l.Config, key)); got != want {
			t.Fatalf("default %s not restored: %q", key, got)
		}
	}
	for _, key := range []string{
		"hypr/modules/extra.lua", "quickshell/yonux/modules/extra.qml", "yonux/matugen/templates/extra",
	} {
		if _, err := os.Lstat(filepath.Join(l.Config, key)); !os.IsNotExist(err) {
			t.Fatalf("removed overlay %s was not pruned: %v", key, err)
		}
	}
}

func TestMaterializeMigratesSymlinkedRootsAndAncestors(t *testing.T) {
	for _, tc := range []struct{ link, target, live, preference, shipped string }{
		{"hypr", "hypr", "hypr/hyprland.lua", "hypr/hyprland.lua", "hypr/hyprland.lua"},
		{"quickshell/yonux", "shell/quickshell", "quickshell/yonux/shell.qml", "quickshell/shell.qml", "shell/quickshell/shell.qml"},
		{"yonux/matugen", "shell/matugen", "yonux/matugen/config.toml", "matugen/config.toml", "shell/matugen/config.toml"},
		{"quickshell", "shell", "quickshell/yonux/shell.qml", "quickshell/shell.qml", "shell/quickshell/shell.qml"},
		{"yonux", "shell", "yonux/matugen/config.toml", "matugen/config.toml", "shell/matugen/config.toml"},
		{"xdg-desktop-portal", "portals", "xdg-desktop-portal/hyprland-portals.conf", "portals/hyprland-portals.conf", "portals/hyprland-portals.conf"},
	} {
		t.Run(tc.link, func(t *testing.T) {
			l := layout(t)
			target := filepath.Join(l.Base, tc.target)
			write(t, filepath.Join(target, "unknown.txt"), "keep unknown")
			before := read(t, filepath.Join(l.Base, tc.shipped))
			link := filepath.Join(l.Config, tc.link)
			if err := os.MkdirAll(filepath.Dir(link), 0o755); err != nil {
				t.Fatal(err)
			}
			if err := os.Symlink(target, link); err != nil {
				t.Fatal(err)
			}
			// Keep preferences outside a linked yonux ancestor until it is
			// migrated, avoiding test setup itself writing into the clone.
			if tc.link != "yonux" {
				write(t, filepath.Join(l.Preferences(), tc.preference), "preferred")
			}
			mustMaterialize(t, l)
			if info, err := os.Lstat(link); err != nil || !info.IsDir() {
				t.Fatalf("root was not migrated: %v", err)
			}
			if got := read(t, filepath.Join(link, "unknown.txt")); got != "keep unknown" {
				t.Fatalf("unknown file lost: %q", got)
			}
			want := "preferred"
			if tc.link == "yonux" {
				want = before
			}
			if got := read(t, filepath.Join(l.Config, tc.live)); got != want {
				t.Fatalf("composed file = %q, want %q", got, want)
			}
			if got := read(t, filepath.Join(l.Base, tc.shipped)); got != before {
				t.Fatalf("clone was modified: %q", got)
			}
			backups := backupPaths(t, l)
			if saved, err := os.Readlink(backups[tc.link]); err != nil || saved != target {
				t.Fatalf("original link not backed up: %q, %v", saved, err)
			}
			mustMaterialize(t, l)
			if len(backupPaths(t, l)) != len(backups) {
				t.Fatal("repeat apply backed up owned paths again")
			}
			if tc.link == "hypr" {
				if got := read(t, filepath.Join(link, "user.lua")); got != "clone user config" {
					t.Fatalf("live user.lua lost in migration: %q", got)
				}
			}
		})
	}
}

func TestMaterializeDoesNotInstallCloneUserFileOrBaseSymlinks(t *testing.T) {
	l := layout(t)
	if err := os.Symlink("hyprland.lua", filepath.Join(l.Base, "hypr/linked.lua")); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink("../shell", filepath.Join(l.Base, "hypr/linked-dir")); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	for _, key := range []string{"hypr/user.lua", "hypr/linked.lua", "hypr/linked-dir"} {
		if _, err := os.Lstat(filepath.Join(l.Config, key)); !os.IsNotExist(err) {
			t.Fatalf("base-only excluded path %s installed: %v", key, err)
		}
	}
}

func TestMaterializeRejectsUnsafeBackupDirectoryWithoutOverwriting(t *testing.T) {
	l := layout(t)
	live := filepath.Join(l.Config, "hypr/hyprland.lua")
	write(t, live, "original")
	other := t.TempDir()
	if err := os.MkdirAll(l.State, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(other, filepath.Join(l.State, "backups")); err != nil {
		t.Fatal(err)
	}
	if err := Materialize(l); err == nil {
		t.Fatal("expected unsafe backup directory error")
	}
	if got := read(t, live); got != "original" {
		t.Fatalf("failed backup overwrote original: %q", got)
	}
	entries, err := os.ReadDir(other)
	if err != nil || len(entries) != 0 {
		t.Fatalf("backup wrote through symlink: %v, %v", entries, err)
	}
}

func TestMaterializeManifestReplacementDoesNotFollowSymlinks(t *testing.T) {
	l := layout(t)
	other := filepath.Join(t.TempDir(), "manifest.json")
	write(t, other, `[]`)
	if err := os.MkdirAll(l.State, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(other, filepath.Join(l.State, "materialize.json")); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	if got := read(t, other); got != `[]` {
		t.Fatalf("manifest write followed symlink: %q", got)
	}
	if info, err := os.Lstat(filepath.Join(l.State, "materialize.json")); err != nil || !info.Mode().IsRegular() {
		t.Fatalf("manifest symlink was not replaced: %v", err)
	}
}

func TestMaterializePropagatesStaleDeletionFailure(t *testing.T) {
	l := layout(t)
	mustMaterialize(t, l)
	stale := filepath.Join(l.Config, "hypr/hyprland.lua")
	if err := os.Remove(stale); err != nil {
		t.Fatal(err)
	}
	write(t, filepath.Join(stale, "unknown"), "do not delete")
	if err := os.Remove(filepath.Join(l.Base, "hypr/hyprland.lua")); err != nil {
		t.Fatal(err)
	}
	if err := Materialize(l); err == nil || !strings.Contains(err.Error(), "remove stale hypr/hyprland.lua") {
		t.Fatalf("expected stale deletion error, got %v", err)
	}
	if got := read(t, filepath.Join(stale, "unknown")); got != "do not delete" {
		t.Fatalf("unknown contents removed: %q", got)
	}
}

func TestMaterializeMigratesNestedSymlinkBeforePruning(t *testing.T) {
	l := layout(t)
	mustMaterialize(t, l)
	liveDir := filepath.Join(l.Config, "yonux/matugen/templates")
	if err := os.RemoveAll(liveDir); err != nil {
		t.Fatal(err)
	}
	cloneDir := filepath.Join(l.Base, "shell/matugen/templates")
	write(t, filepath.Join(cloneDir, "unknown"), "keep unknown")
	if err := os.Symlink(cloneDir, liveDir); err != nil {
		t.Fatal(err)
	}
	// The source no longer ships fish, but the linked live directory still has
	// it. Pruning must detach that directory before removing the owned file.
	otherSource := filepath.Join(t.TempDir(), "base")
	write(t, filepath.Join(otherSource, "shell/matugen/config.toml"), "new source")
	l.Base = otherSource
	mustMaterialize(t, l)
	if _, err := os.Lstat(filepath.Join(liveDir, "fish")); !os.IsNotExist(err) {
		t.Fatalf("stale file not pruned: %v", err)
	}
	if got := read(t, filepath.Join(cloneDir, "fish")); got != "base fish" {
		t.Fatalf("pruning wrote into clone: %q", got)
	}
	if got := read(t, filepath.Join(liveDir, "unknown")); got != "keep unknown" {
		t.Fatalf("pruning removed third-party sibling: %q", got)
	}
	if info, err := os.Lstat(liveDir); err != nil || !info.IsDir() {
		t.Fatalf("nested ancestor was not detached: %v", err)
	}
}

func TestMaterializeMigratesDanglingRootSymlink(t *testing.T) {
	l := layout(t)
	if err := os.MkdirAll(l.Config, 0o755); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(l.Config, "hypr")
	target := filepath.Join(t.TempDir(), "missing")
	if err := os.Symlink(target, link); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	if got := read(t, filepath.Join(link, "hyprland.lua")); got != "base hypr" {
		t.Fatalf("dangling root was not replaced: %q", got)
	}
	if saved, err := os.Readlink(backupPaths(t, l)["hypr"]); err != nil || saved != target {
		t.Fatalf("dangling root provenance lost: %q, %v", saved, err)
	}
	if _, err := os.Lstat(target); !os.IsNotExist(err) {
		t.Fatalf("dangling target was created: %v", err)
	}
}

func TestMaterializeFailureRetryDoesNotBackUpItsOwnOutput(t *testing.T) {
	l := layout(t)
	conflict := filepath.Join(l.Config, "quickshell/yonux/shell.qml")
	write(t, filepath.Join(conflict, "unknown"), "preserve")
	if err := Materialize(l); err == nil {
		t.Fatal("expected later directory collision to fail")
	}
	if got := read(t, filepath.Join(l.Config, "hypr/hyprland.lua")); got != "base hypr" {
		t.Fatalf("earlier file was not successfully laid: %q", got)
	}
	var recorded struct {
		Files []string `json:"files"`
	}
	if err := json.Unmarshal([]byte(read(t, filepath.Join(l.State, "materialize.json"))), &recorded); err != nil {
		t.Fatal(err)
	}
	found := false
	for _, file := range recorded.Files {
		found = found || file == "hypr/hyprland.lua"
	}
	if !found {
		t.Fatalf("failed apply did not persist successful ownership: %v", recorded.Files)
	}
	if err := os.RemoveAll(conflict); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	backups := backupPaths(t, l)
	if _, backedUp := backups["hypr/hyprland.lua"]; backedUp {
		t.Fatal("retry backed up our own output as an unmanaged original")
	}
	if got := read(t, filepath.Join(backups["quickshell/yonux/shell.qml"], "unknown")); got != "preserve" {
		t.Fatalf("original collision backup was lost: %q", got)
	}
}

func TestMaterializeBacksUpNewOriginalAfterOwnershipEnds(t *testing.T) {
	l := layout(t)
	live := filepath.Join(l.Config, "hypr/hyprland.lua")
	shipped := filepath.Join(l.Base, "hypr/hyprland.lua")
	write(t, live, "first original")
	mustMaterialize(t, l)
	if err := os.Remove(shipped); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	write(t, live, "second original")
	write(t, shipped, "returning base")
	mustMaterialize(t, l)
	mustMaterialize(t, l)
	var recorded struct {
		Backups []struct {
			Path   string `json:"path"`
			Backup string `json:"backup"`
		} `json:"backups"`
	}
	if err := json.Unmarshal([]byte(read(t, filepath.Join(l.State, "materialize.json"))), &recorded); err != nil {
		t.Fatal(err)
	}
	var originals []string
	for _, backup := range recorded.Backups {
		if backup.Path == "hypr/hyprland.lua" {
			originals = append(originals, read(t, filepath.Join(l.State, backup.Backup)))
		}
	}
	if strings.Join(originals, ",") != "first original,second original" {
		t.Fatalf("backup history = %v", originals)
	}
}

func TestMaterializeMigrationPreservesPermissionsAndRelativeLinkReferents(t *testing.T) {
	l := layout(t)
	source := filepath.Join(l.Base, "hypr")
	if err := os.Remove(filepath.Join(source, "user.lua")); err != nil {
		t.Fatal(err)
	}
	referent := filepath.Join(l.Base, "local-user.lua")
	write(t, referent, "local user")
	if err := os.Symlink("../local-user.lua", filepath.Join(source, "user.lua")); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(source, "unknown"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink("../../local-user.lua", filepath.Join(source, "unknown/relative.lua")); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(source, 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(l.Config, 0o755); err != nil {
		t.Fatal(err)
	}
	live := filepath.Join(l.Config, "hypr")
	originalLink := "../base/hypr"
	if err := os.Symlink(originalLink, live); err != nil {
		t.Fatal(err)
	}
	mustMaterialize(t, l)
	info, err := os.Stat(live)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o750 {
		t.Fatalf("migration changed root permissions to %o", info.Mode().Perm())
	}
	for _, rel := range []string{"user.lua", "unknown/relative.lua"} {
		if got := read(t, filepath.Join(live, rel)); got != "local user" {
			t.Fatalf("relative link %s lost referent: %q", rel, got)
		}
		target, err := os.Readlink(filepath.Join(live, rel))
		if err != nil || !filepath.IsAbs(target) {
			t.Fatalf("migrated relative link not anchored: %q, %v", target, err)
		}
	}
	if target, err := os.Readlink(backupPaths(t, l)["hypr"]); err != nil || target != originalLink {
		t.Fatalf("original root link backup changed: %q, %v", target, err)
	}
	write(t, referent, "changed referent")
	if got := read(t, filepath.Join(live, "user.lua")); got != "changed referent" {
		t.Fatalf("migrated link no longer follows original referent: %q", got)
	}
}

func TestMaterializeAcceptsRootsUnderSymlinkedHome(t *testing.T) {
	l := layout(t)
	home := t.TempDir()
	link := filepath.Join(t.TempDir(), "home")
	if err := os.Symlink(home, link); err != nil {
		t.Fatal(err)
	}
	l.Config = filepath.Join(link, ".config")
	l.State = filepath.Join(link, ".local/state/yonux")
	mustMaterialize(t, l)
	if got := read(t, filepath.Join(home, ".config/hypr/hyprland.lua")); got != "base hypr" {
		t.Fatalf("config beneath linked home was not composed: %q", got)
	}
	if info, err := os.Stat(filepath.Join(home, ".local/state/yonux/materialize.json")); err != nil || !info.Mode().IsRegular() {
		t.Fatalf("state beneath linked home was not recorded: %v", err)
	}
	if target, err := os.Readlink(link); err != nil || target != home {
		t.Fatalf("user-selected home link changed: %q, %v", target, err)
	}
}
