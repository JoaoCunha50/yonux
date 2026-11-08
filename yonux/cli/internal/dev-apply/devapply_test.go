package devapply

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"joaocunha50/yonux-cli/internal/materialize"
	"joaocunha50/yonux-cli/internal/source"
)

func write(t *testing.T, p, body string, mode os.FileMode) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(body), mode); err != nil {
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

func absent(t *testing.T, p string) {
	t.Helper()
	if _, err := os.Lstat(p); !os.IsNotExist(err) {
		t.Fatalf("%s should not exist: %v", p, err)
	}
}

// clone lays out a minimal clone root, with the files a real one carries but
// that are not config: the user's ignored user.lua and qs's .qmlls.ini link.
func clone(t *testing.T) string {
	root := filepath.Join(t.TempDir(), "clone")
	y := filepath.Join(root, "yonux")
	write(t, filepath.Join(y, "cli/go.mod"), "module cli", 0o644)
	write(t, filepath.Join(y, "shell/ipc/go.mod"), "module ipc", 0o644)
	write(t, filepath.Join(y, "hypr/hyprland.lua"), "hypr from clone", 0o644)
	write(t, filepath.Join(y, "hypr/scripts/tool"), "#!/bin/sh", 0o755)
	write(t, filepath.Join(y, "hypr/user.lua"), "clone user.lua", 0o644)
	write(t, filepath.Join(y, "shell/quickshell/shell.qml"), "shell from clone", 0o644)
	write(t, filepath.Join(y, "shell/matugen/config.toml"), "matugen from clone", 0o644)
	if err := os.Symlink("/run/user/1000/quickshell/vfs/x/.qmlls.ini", filepath.Join(y, "shell/quickshell/.qmlls.ini")); err != nil {
		t.Fatal(err)
	}
	return root
}

func target(t *testing.T) Target {
	dir := t.TempDir()
	return Target{
		Layout: materialize.Layout{Config: filepath.Join(dir, "config"), State: filepath.Join(dir, "state")},
		Bin:    filepath.Join(dir, "bin"),
	}
}

func fakeBuild(dir, out string) error {
	return os.WriteFile(out, []byte("built "+dir), 0o755)
}

func TestRunAppliesClone(t *testing.T) {
	from, tg := clone(t), target(t)

	if err := Run(from, tg, fakeBuild); err != nil {
		t.Fatal(err)
	}

	for p, want := range map[string]string{
		filepath.Join(tg.Bin, "yonux"):                                "built " + filepath.Join(from, "yonux/cli"),
		filepath.Join(tg.Bin, "yonux-ipc"):                            "built " + filepath.Join(from, "yonux/shell/ipc"),
		filepath.Join(tg.Layout.Config, "hypr/hyprland.lua"):          "hypr from clone",
		filepath.Join(tg.Layout.Config, "quickshell/yonux/shell.qml"): "shell from clone",
		filepath.Join(tg.Layout.Config, "yonux/matugen/config.toml"):  "matugen from clone",
	} {
		if got := read(t, p); got != want {
			t.Errorf("%s = %q, want %q", p, got, want)
		}
	}
	if info, err := os.Stat(filepath.Join(tg.Layout.Config, "hypr/scripts/tool")); err != nil || info.Mode().Perm() != 0o755 {
		t.Errorf("script lost its mode: %v %v", info, err)
	}
	absent(t, filepath.Join(tg.Layout.Config, "hypr/user.lua"))
	absent(t, filepath.Join(tg.Layout.Config, "quickshell/yonux/.qmlls.ini"))
	if s, err := source.Load(tg.Layout.State); err != nil || s.Checkout != from {
		t.Errorf("recorded source = %+v, %v", s, err)
	}

	for _, dir := range []string{tg.Bin, tg.Layout.Config, filepath.Join(tg.Layout.Config, "quickshell")} {
		entries, _ := os.ReadDir(dir)
		for _, e := range entries {
			if strings.HasPrefix(e.Name(), ".yonux-") {
				t.Errorf("temp left behind: %s", filepath.Join(dir, e.Name()))
			}
		}
	}
}

// The old install linked ~/.config/hypr into the clone, where user.lua lives.
func TestRunReplacesLinkIntoCloneAndKeepsUserLua(t *testing.T) {
	from, tg := clone(t), target(t)
	write(t, filepath.Join(from, "yonux/hypr/user.lua"), "my overrides", 0o644)
	live := filepath.Join(tg.Layout.Config, "hypr")
	if err := os.MkdirAll(tg.Layout.Config, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(filepath.Join(from, "yonux/hypr"), live); err != nil {
		t.Fatal(err)
	}

	if err := Run(from, tg, fakeBuild); err != nil {
		t.Fatal(err)
	}

	if info, err := os.Lstat(live); err != nil || !info.IsDir() {
		t.Fatalf("live hypr is not a directory: %v", err)
	}
	if got := read(t, filepath.Join(live, "user.lua")); got != "my overrides" {
		t.Fatalf("user.lua = %q", got)
	}
	if got := read(t, filepath.Join(from, "yonux/hypr/hyprland.lua")); got != "hypr from clone" {
		t.Fatalf("clone was changed: %q", got)
	}
	if got := read(t, filepath.Join(from, "yonux/hypr/user.lua")); got != "my overrides" {
		t.Fatalf("clone user.lua was changed: %q", got)
	}
}

func TestRunReplacesLiveTreeKeepingOnlyUserLua(t *testing.T) {
	from, tg := clone(t), target(t)
	live := filepath.Join(tg.Layout.Config, "hypr")
	write(t, filepath.Join(live, "user.lua"), "live user.lua", 0o644)
	write(t, filepath.Join(live, "stray.conf"), "old", 0o644)
	write(t, filepath.Join(live, "hyprland.lua"), "old hypr", 0o644)
	other := filepath.Join(tg.Layout.Config, "quickshell/other/shell.qml")
	write(t, other, "another config", 0o644)

	if err := Run(from, tg, fakeBuild); err != nil {
		t.Fatal(err)
	}

	if got := read(t, filepath.Join(live, "user.lua")); got != "live user.lua" {
		t.Fatalf("user.lua = %q", got)
	}
	if got := read(t, filepath.Join(live, "hyprland.lua")); got != "hypr from clone" {
		t.Fatalf("hyprland.lua = %q", got)
	}
	absent(t, filepath.Join(live, "stray.conf"))
	if got := read(t, other); got != "another config" {
		t.Fatalf("other quickshell config changed: %q", got)
	}
}

func TestRunRecordsAbsoluteCloneRoot(t *testing.T) {
	from, tg := clone(t), target(t)
	t.Chdir(filepath.Dir(from))

	if err := Run("clone", tg, fakeBuild); err != nil {
		t.Fatal(err)
	}
	if s, _ := source.Load(tg.Layout.State); s.Checkout != from {
		t.Fatalf("recorded %q, want %q", s.Checkout, from)
	}
}

func TestRunRejectsWhatIsNotACloneRoot(t *testing.T) {
	for name, from := range map[string]func(string) string{
		"yonux_subfolder": func(root string) string { return filepath.Join(root, "yonux") },
		"missing_module": func(root string) string {
			os.Remove(filepath.Join(root, "yonux/shell/ipc/go.mod"))
			return root
		},
		"missing_tree": func(root string) string {
			os.RemoveAll(filepath.Join(root, "yonux/shell/quickshell"))
			return root
		},
	} {
		t.Run(name, func(t *testing.T) {
			tg := target(t)
			built := false
			build := func(dir, out string) error { built = true; return fakeBuild(dir, out) }

			if err := Run(from(clone(t)), tg, build); err == nil || !strings.Contains(err.Error(), "not a yonux clone root") {
				t.Fatalf("expected a clone root error, got %v", err)
			}
			if built {
				t.Fatal("built before validating")
			}
			absent(t, tg.Bin)
			absent(t, tg.Layout.Config)
			absent(t, tg.Layout.State)
		})
	}
}

func TestRunFailedBuildChangesNothing(t *testing.T) {
	from, tg := clone(t), target(t)
	write(t, filepath.Join(tg.Bin, "yonux"), "old yonux", 0o755)
	if err := source.Save(tg.Layout.State, source.Source{Checkout: "/previous/clone"}); err != nil {
		t.Fatal(err)
	}
	build := func(dir, out string) error {
		if strings.HasSuffix(dir, "ipc") {
			return errors.New("compile error")
		}
		return fakeBuild(dir, out)
	}

	if err := Run(from, tg, build); err == nil || !strings.Contains(err.Error(), "compile error") {
		t.Fatalf("expected the build error, got %v", err)
	}
	if got := read(t, filepath.Join(tg.Bin, "yonux")); got != "old yonux" {
		t.Fatalf("binary replaced after a failed build: %q", got)
	}
	entries, _ := os.ReadDir(tg.Bin)
	if len(entries) != 1 {
		t.Fatalf("bin dir = %v", entries)
	}
	absent(t, tg.Layout.Config)
	if s, _ := source.Load(tg.Layout.State); s.Checkout != "/previous/clone" {
		t.Fatalf("source changed: %+v", s)
	}
}

func TestRunKeepsPreviousSourceWhenMaterializeFails(t *testing.T) {
	from, tg := clone(t), target(t)
	if err := source.Save(tg.Layout.State, source.Source{Checkout: "/previous/clone"}); err != nil {
		t.Fatal(err)
	}
	write(t, filepath.Join(tg.Layout.State, "materialize.json"), "{", 0o644)

	if err := Run(from, tg, fakeBuild); err == nil || !strings.Contains(err.Error(), "manifest") {
		t.Fatalf("expected the materialize error, got %v", err)
	}
	if s, _ := source.Load(tg.Layout.State); s.Checkout != "/previous/clone" {
		t.Fatalf("source changed: %+v", s)
	}
}
