package internal

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseScheme(t *testing.T) {
	for in, want := range map[string]MatugenScheme{
		"scheme-tonal-spot":  TonalSpot,
		"tonal-spot":         TonalSpot,
		"scheme-fruit-salad": FruitSalad,
		"smart":              Smart,
	} {
		got, err := ParseScheme(in)
		if err != nil || got != want {
			t.Errorf("ParseScheme(%q) = %v, %v; want %v", in, got, err, want)
		}
	}
	if _, err := ParseScheme("nope"); err == nil {
		t.Error("ParseScheme accepted an unknown scheme")
	}
}

func TestChangeShellTheme(t *testing.T) {
	dir := t.TempDir()
	bin := filepath.Join(dir, "bin")
	args := filepath.Join(dir, "args")
	wallpaper := filepath.Join(dir, "wall.png")
	config := filepath.Join(dir, "config", "yonux", "matugen", "config.toml")
	for p, body := range map[string]string{
		filepath.Join(bin, "matugen"): "#!/bin/sh\necho \"$@\" > " + args + "\necho '{\"colors\":{}}'\n",
		wallpaper:                     "",
		config:                        "",
	} {
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(body), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	t.Setenv("PATH", bin)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(dir, "config"))

	out, err := ChangeShellTheme(wallpaper, Vibrant)
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(out)) != `{"colors":{}}` {
		t.Fatalf("palette = %q", out)
	}
	got, _ := os.ReadFile(args)
	if !strings.Contains(string(got), "-c "+config) || !strings.Contains(string(got), "-t scheme-vibrant") {
		t.Fatalf("matugen args = %q", got)
	}
}

func TestMatugenConfig(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/home/me/.config")
	t.Setenv("YONUX_MATUGEN_CONFIG", "")
	if got, err := MatugenConfig(); err != nil || got != "/home/me/.config/yonux/matugen/config.toml" {
		t.Fatalf("MatugenConfig() = %q, %v", got, err)
	}

	t.Setenv("YONUX_MATUGEN_CONFIG", "/run/user/1000/yonux-dev.x/config/yonux/matugen/config.toml")
	if got, err := MatugenConfig(); err != nil || got != "/run/user/1000/yonux-dev.x/config/yonux/matugen/config.toml" {
		t.Fatalf("dev MatugenConfig() = %q, %v", got, err)
	}
}
