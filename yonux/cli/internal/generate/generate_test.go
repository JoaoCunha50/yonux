package generate_test

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"joaocunha50/yonux-cli/internal/generate"
	"joaocunha50/yonux-cli/internal/materialize"
)

func layout(t *testing.T) materialize.Layout {
	t.Helper()
	dir := t.TempDir()
	l := materialize.Layout{Base: filepath.Join(dir, "base"), Config: filepath.Join(dir, "config"), State: filepath.Join(dir, "state")}
	_, file, _, _ := runtime.Caller(0)
	schema, err := os.ReadFile(filepath.Join(filepath.Dir(file), "..", "..", "..", "shell", "quickshell", "config", "HyprSettings.qml"))
	if err != nil {
		t.Fatal(err)
	}
	write(t, filepath.Join(l.Base, "shell", "quickshell", "config", "HyprSettings.qml"), string(schema))
	// There is intentionally no executable or active graphical session to call.
	t.Setenv("PATH", t.TempDir())
	t.Setenv("HOME", dir)
	t.Setenv("DISPLAY", "")
	t.Setenv("WAYLAND_DISPLAY", "")
	t.Setenv("HYPRLAND_INSTANCE_SIGNATURE", "")
	t.Setenv("XDG_DATA_HOME", filepath.Join(dir, "data"))
	t.Setenv("XDG_DATA_DIRS", filepath.Join(dir, "system-data"))
	t.Setenv("LC_MESSAGES", "en_US.UTF-8")
	return l
}

func write(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

func read(t *testing.T, path string) string {
	t.Helper()
	body, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(body)
}

func output(t *testing.T, l materialize.Layout, name string) string {
	t.Helper()
	return read(t, filepath.Join(l.Config, "yonux", name))
}

func contains(t *testing.T, text string, parts ...string) {
	t.Helper()
	for _, part := range parts {
		if !strings.Contains(text, part) {
			t.Errorf("missing %q in generated output:\n%s", part, text)
		}
	}
}

func TestRunUsesShippedDefaultsWithoutCreatingStoresOrStartingSession(t *testing.T) {
	l := layout(t)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	hypr := output(t, l, "hyprland.lua")
	contains(t, hypr,
		`yonux.layout = "dwindle"`, `yonux.animation_speed = 1`,
		`hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")`, `hl.env("XCURSOR_SIZE", "22")`,
		`hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")`, `hl.env("HYPRCURSOR_SIZE", "22")`,
		"animations = {\n        enabled = true,", "layout = \"dwindle\",", "column_width = 0.5,", "follow_focus = true,", "preserve_split = true,",
		"gaps_in = 10,", "gaps_out = 15,", "border_size = 2,", "rounding = 10,", "active_opacity = 1,", "inactive_opacity = 1,",
		"blur = {\n            enabled = true,\n            size = 4,\n            passes = 2,", "shadow = {\n            enabled = true,\n            range = 20,",
		"follow_mouse = 1,", "sensitivity = 0,", "natural_scroll = false,", "if yonux.apply_animations then yonux.apply_animations() end",
	)
	if strings.Contains(hypr, "cursor = {") || strings.Contains(hypr, "speed = 1,") {
		t.Fatalf("non-Hyprland settings leaked into hl.config: %s", hypr)
	}
	wantBindings := "-- Generated from keybindings.json by yonux. Data only.\nreturn { overrides = {\n    \n}, custom = {\n    \n} }\n"
	if got := output(t, l, "keybindings.lua"); got != wantBindings {
		t.Fatalf("default keybindings differ: %q", got)
	}
	for _, store := range []string{"hypr.json", "keybindings.json"} {
		if _, err := os.Stat(filepath.Join(l.Config, "yonux", store)); !os.IsNotExist(err) {
			t.Fatalf("generation created %s: %v", store, err)
		}
	}
}

func TestRunReadsDefaultsFromCurrentShippedSchema(t *testing.T) {
	l := layout(t)
	path := filepath.Join(l.Base, "shell", "quickshell", "config", "HyprSettings.qml")
	schema := read(t, path)
	write(t, path, strings.Replace(schema, "defaultValue: 22", "defaultValue: 31", 1))
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	contains(t, output(t, l, "hyprland.lua"), `hl.env("XCURSOR_SIZE", "31")`)
}

func TestRunRendersHyprOverridesAndScrollingDerivedGaps(t *testing.T) {
	for _, gaps := range []struct{ inner, outer, horizontal string }{{"8", "23", "15"}, {"25", "3", "0"}} {
		t.Run(gaps.inner+"/"+gaps.outer, func(t *testing.T) {
			l := layout(t)
			store := `{"general.layout":"scrolling","general.gaps_in":` + gaps.inner + `,"general.gaps_out":` + gaps.outer + `,"cursor.theme":"My Cursor","cursor.size":35.6,"animations.enabled":false,"animations.speed":1.75,"input.sensitivity":-0.35,"decoration.blur.enabled":false,"unknown.option":42}`
			write(t, filepath.Join(l.Config, "yonux", "hypr.json"), store)
			if err := generate.Run(l); err != nil {
				t.Fatal(err)
			}
			hypr := output(t, l, "hyprland.lua")
			contains(t, hypr, `yonux.layout = "scrolling"`, `yonux.animation_speed = 1.75`, `hl.env("XCURSOR_THEME", "My Cursor")`, `hl.env("XCURSOR_SIZE", "36")`,
				"animations = {\n        enabled = false,", "sensitivity = -0.35,", "blur = {\n            enabled = false,",
				"gaps_out = {\n            top = "+gaps.outer+",\n            right = "+gaps.horizontal+",\n            bottom = "+gaps.outer+",\n            left = "+gaps.horizontal+",")
			if strings.Contains(hypr, "unknown") {
				t.Fatalf("unknown setting was not ignored: %s", hypr)
			}
			if got := output(t, l, "hypr.json"); got != store {
				t.Fatal("generation rewrote the settings store")
			}
		})
	}
}

func TestRunClampsCursorSize(t *testing.T) {
	for _, tc := range []struct{ size, want string }{{"1", "16"}, {"100", "64"}} {
		t.Run(tc.size, func(t *testing.T) {
			l := layout(t)
			write(t, filepath.Join(l.Config, "yonux", "hypr.json"), `{"cursor.size":`+tc.size+`}`)
			if err := generate.Run(l); err != nil {
				t.Fatal(err)
			}
			contains(t, output(t, l, "hyprland.lua"), `hl.env("XCURSOR_SIZE", "`+tc.want+`")`, `hl.env("HYPRCURSOR_SIZE", "`+tc.want+`")`)
		})
	}
}

func TestRunRendersBuiltInOverridesCustomCommandsAndEscaping(t *testing.T) {
	l := layout(t)
	store := `{"overrides":[{"id":"terminal","keys":"SUPER + T","title":"Terminal","kind":"default","command":"","enabled":false}],"custom":[{"id":"script","keys":"SUPER + X","title":"Line\n\"quoted\"","kind":"command","command":"printf 'hi'\nnext","terminal":true,"enabled":true}]}`
	write(t, filepath.Join(l.Config, "yonux", "keybindings.json"), store)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	contains(t, output(t, l, "keybindings.lua"),
		`{ id = "terminal", keys = "SUPER + T", title = "Terminal", kind = "default", enabled = false, command = "" }`,
		`title = "Line\010\"quoted\""`,
		`command = "'xdg-terminal-exec' 'sh' '-c' 'printf '\\''hi'\\''\010next'"`,
	)
	if got := output(t, l, "keybindings.json"); got != store {
		t.Fatal("generation rewrote keybindings.json")
	}
}

func TestRunResolvesApplicationsLikeQuickshell(t *testing.T) {
	l := layout(t)
	user, system := os.Getenv("XDG_DATA_HOME"), os.Getenv("XDG_DATA_DIRS")
	write(t, filepath.Join(system, "applications", "nested", "editor.desktop"), "[Desktop Entry]\nType=Application\nName=System editor\nExec=old-editor\n")
	write(t, filepath.Join(user, "applications", "nested", "editor.desktop"), "[Desktop Entry]\nType=Application\nName=User editor\nExec=\"/opt/My App/bin\" --title \"Words here\" %U %%\nTerminal=true\nPath=/work/project\n[Desktop Action Other]\nExec=not-the-application\n")
	write(t, filepath.Join(system, "applications", "masked.desktop"), "[Desktop Entry]\nType=Application\nName=Masked\nExec=masked\n")
	write(t, filepath.Join(user, "applications", "masked.desktop"), "[Desktop Entry]\nType=Application\nHidden=true\n")
	write(t, filepath.Join(user, "applications", "private.desktop"), "[Desktop Entry]\nType=Application\nName=Private\nNoDisplay=true\nExec=private\n")
	store := `{"custom":[{"id":"app","keys":"SUPER + E","title":"Editor","kind":"app","appId":"nested-editor","command":"","enabled":true},{"id":"missing","keys":"SUPER + M","title":"Missing","kind":"app","appId":"missing","command":"","enabled":true},{"id":"masked","keys":"SUPER + H","title":"Masked","kind":"app","appId":"masked","command":"","enabled":true},{"id":"private","keys":"SUPER + P","title":"Private","kind":"app","appId":"private","command":"","enabled":true}]}`
	write(t, filepath.Join(l.Config, "yonux", "keybindings.json"), store)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	bindings := output(t, l, "keybindings.lua")
	contains(t, bindings, `enabled = true, command = "cd '/work/project' && 'xdg-terminal-exec' '/opt/My App/bin' '--title' 'Words here' '%'"`)
	for _, title := range []string{"Missing", "Masked", "Private"} {
		contains(t, bindings, `title = "`+title+`", kind = "app", enabled = false, command = ""`)
	}
}

func TestRunRejectsMalformedStoresBeforeChangingEitherOutput(t *testing.T) {
	for _, tc := range []struct{ name, body string }{
		{"hypr.json", "{"}, {"hypr.json", ""}, {"hypr.json", "{} trailing"},
		{"keybindings.json", "{"}, {"keybindings.json", ""}, {"keybindings.json", "[null,]"},
	} {
		t.Run(tc.name+tc.body, func(t *testing.T) {
			l := layout(t)
			write(t, filepath.Join(l.Config, "yonux", "hyprland.lua"), "previous settings")
			write(t, filepath.Join(l.Config, "yonux", "keybindings.lua"), "previous bindings")
			write(t, filepath.Join(l.Config, "yonux", tc.name), tc.body)
			if err := generate.Run(l); err == nil || !strings.Contains(err.Error(), tc.name) {
				t.Fatalf("expected error identifying %s, got %v", tc.name, err)
			}
			if output(t, l, "hyprland.lua") != "previous settings" || output(t, l, "keybindings.lua") != "previous bindings" {
				t.Fatal("invalid store changed generated outputs")
			}
			if output(t, l, tc.name) != tc.body {
				t.Fatal("invalid store was overwritten")
			}
		})
	}
}

func TestRunReplacesGeneratedSymlinksWithoutWritingIntoCheckout(t *testing.T) {
	l := layout(t)
	for _, name := range []string{"hyprland.lua", "keybindings.lua"} {
		source := filepath.Join(l.Base, name)
		write(t, source, "checkout file")
		path := filepath.Join(l.Config, "yonux", name)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.Symlink(source, path); err != nil {
			t.Fatal(err)
		}
	}
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"hyprland.lua", "keybindings.lua"} {
		if read(t, filepath.Join(l.Base, name)) != "checkout file" {
			t.Fatalf("generation wrote through %s symlink", name)
		}
		info, err := os.Lstat(filepath.Join(l.Config, "yonux", name))
		if err != nil || !info.Mode().IsRegular() {
			t.Fatalf("output %s is not a regular file: %v", name, err)
		}
	}
}

func TestRunReportsUnreadableStoreAndSchemaErrors(t *testing.T) {
	for _, name := range []string{"hypr.json", "keybindings.json"} {
		t.Run(name, func(t *testing.T) {
			l := layout(t)
			if err := os.MkdirAll(filepath.Join(l.Config, "yonux", name), 0o755); err != nil {
				t.Fatal(err)
			}
			if err := generate.Run(l); err == nil || !strings.Contains(err.Error(), name) {
				t.Fatalf("expected store read error, got %v", err)
			}
		})
	}
	t.Run("unsupported_default_expression", func(t *testing.T) {
		l := layout(t)
		path := filepath.Join(l.Base, "shell", "quickshell", "config", "HyprSettings.qml")
		write(t, path, strings.Replace(read(t, path), "defaultValue: 22", "defaultValue: calculateSize()", 1))
		if err := generate.Run(l); err == nil || !strings.Contains(err.Error(), "settings schema") {
			t.Fatalf("expected explicit unsupported-schema error, got %v", err)
		}
	})
}

func TestRunRegeneratesChangedStoresAndRemovesOldCustomBindings(t *testing.T) {
	l := layout(t)
	hypr := filepath.Join(l.Config, "yonux", "hypr.json")
	bindings := filepath.Join(l.Config, "yonux", "keybindings.json")
	write(t, hypr, `{"general.layout":"scrolling"}`)
	write(t, bindings, `{"custom":[{"id":"old","keys":"SUPER + X","title":"Old","kind":"command","command":"old-command","enabled":true}]}`)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	write(t, hypr, `{"general.layout":"master"}`)
	write(t, bindings, `{}`)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	contains(t, output(t, l, "hyprland.lua"), `yonux.layout = "master"`, "gaps_out = 15,")
	if strings.Contains(output(t, l, "keybindings.lua"), "old-command") {
		t.Fatal("removed custom binding remains generated")
	}
}

func TestRunUsesDefaultsForNonObjectDocumentsLikeJsonConfig(t *testing.T) {
	for _, name := range []string{"hypr.json", "keybindings.json"} {
		for _, body := range []string{"null", "[]", "[1,2]", `"a string"`, "true", "17"} {
			t.Run(name+"/"+body, func(t *testing.T) {
				l := layout(t)
				if err := generate.Run(l); err != nil {
					t.Fatal(err)
				}
				defaultHypr := output(t, l, "hyprland.lua")
				defaultBindings := output(t, l, "keybindings.lua")
				write(t, filepath.Join(l.Config, "yonux", name), body)
				if err := generate.Run(l); err != nil {
					t.Fatal(err)
				}
				if output(t, l, "hyprland.lua") != defaultHypr || output(t, l, "keybindings.lua") != defaultBindings {
					t.Fatal("non-object document did not retain default generation")
				}
				if output(t, l, name) != body {
					t.Fatal("generation rewrote the source store")
				}
			})
		}
	}
}

func TestRunFallsBackPerWrongTypeHyprSettingAndKeepsValidNeighbors(t *testing.T) {
	l := layout(t)
	write(t, filepath.Join(l.Config, "yonux", "hypr.json"), `{"cursor.theme":null,"cursor.size":"large","animations.enabled":1,"animations.speed":false,"general.gaps_in":[],"general.gaps_out":{},"input.sensitivity":null,"general.border_size":6}`)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	contains(t, output(t, l, "hyprland.lua"),
		`hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")`, `hl.env("XCURSOR_SIZE", "22")`,
		"yonux.animation_speed = 1", "animations = {\n        enabled = true,",
		"gaps_in = 10,", "gaps_out = 15,", "sensitivity = 0,", "border_size = 6,")
}

func TestRunDefaultsInvalidBindingArraysAndFiltersInvalidMembers(t *testing.T) {
	for _, body := range []string{`{"custom":null,"overrides":{}}`, `{"custom":"invalid","overrides":false}`} {
		t.Run(body, func(t *testing.T) {
			l := layout(t)
			if err := generate.Run(l); err != nil {
				t.Fatal(err)
			}
			want := output(t, l, "keybindings.lua")
			write(t, filepath.Join(l.Config, "yonux", "keybindings.json"), body)
			if err := generate.Run(l); err != nil {
				t.Fatal(err)
			}
			if got := output(t, l, "keybindings.lua"); got != want {
				t.Fatalf("invalid array did not default empty: %s", got)
			}
		})
	}
	t.Run("mixed_members", func(t *testing.T) {
		l := layout(t)
		write(t, filepath.Join(l.Config, "yonux", "keybindings.json"), `{"overrides":[null,{},{"id":"valid-default","keys":"SUPER + T","title":"Terminal","kind":"default","command":"","enabled":false}],"custom":[false,17,"invalid",[],{"id":"missing-app-id","keys":"SUPER + A","title":"App","kind":"app","command":"","enabled":true},{"id":"wrong-enabled-type","keys":"SUPER + W","title":"Wrong","kind":"command","command":"wrong","enabled":1},{"id":"valid-command","keys":"SUPER + X","title":"Command","kind":"command","command":"works","terminal":"truthy","enabled":true}]}`)
		if err := generate.Run(l); err != nil {
			t.Fatal(err)
		}
		got := output(t, l, "keybindings.lua")
		contains(t, got, `id = "valid-default"`, `enabled = false, command = ""`, `id = "valid-command"`, `command = "'xdg-terminal-exec' 'sh' '-c' 'works'"`)
		if strings.Contains(got, "missing-app-id") || strings.Contains(got, "wrong-enabled-type") {
			t.Fatalf("invalid binding members survived filtering: %s", got)
		}
	})
}

func TestRunEmitsLuaSafeUnicodeAndControlCharacters(t *testing.T) {
	l := layout(t)
	write(t, filepath.Join(l.Config, "yonux", "hypr.json"), `{"cursor.theme":"before\u2028middle\u2029after\u0000tail\b\f","general.layout":"layout\u2028name"}`)
	write(t, filepath.Join(l.Config, "yonux", "keybindings.json"), `{"custom":[{"id":"unicode","keys":"SUPER + U","title":"before\u2028middle\u2029after","kind":"command","command":"echo \u2028\u2029","enabled":true}]}`)
	if err := generate.Run(l); err != nil {
		t.Fatal(err)
	}
	hypr := output(t, l, "hyprland.lua")
	contains(t, hypr, "before\u2028middle\u2029after"+`\000tail\008\012`, "yonux.layout = \"layout\u2028name\"")
	bindings := output(t, l, "keybindings.lua")
	contains(t, bindings, "before\u2028middle\u2029after", "echo \u2028\u2029")
	for _, text := range []string{hypr, bindings} {
		if strings.Contains(text, `\u2028`) || strings.Contains(text, `\u2029`) || strings.Contains(text, `\u0000`) {
			t.Fatalf("JSON-only escape leaked into Lua: %s", text)
		}
	}
}
