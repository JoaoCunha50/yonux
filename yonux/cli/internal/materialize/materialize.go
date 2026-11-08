package materialize

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"joaocunha50/yonux-cli/internal/source"
)

type tree struct {
	Name string
	Src  string
	Dst  string
}

var trees = []tree{
	{Name: "matugen", Src: "shell/matugen", Dst: "yonux/matugen"},
}

type Layout struct {
	Base   string // path to the yonux folder
	Config string // $XDG_CONFIG_HOME
	State  string // $XDG_STATE_HOME/yonux, where the manifest lives
}

// UserLayout is the user's config and state dirs, without a Base.
func UserLayout() (Layout, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return Layout{}, err
	}
	return Layout{
		Config: envOr("XDG_CONFIG_HOME", filepath.Join(home, ".config")),
		State:  filepath.Join(envOr("XDG_STATE_HOME", filepath.Join(home, ".local", "state")), "yonux"),
	}, nil
}

// DefaultLayout picks the base: $YONUX_BASE for this run, else the checkout
// recorded by `yonux dev-apply`, else the installed ../share/yonux beside the
// real executable. A recorded checkout that is gone is an error, never a fallback.
func DefaultLayout() (Layout, error) {
	l, err := UserLayout()
	if err != nil {
		return Layout{}, err
	}
	if base := os.Getenv("YONUX_BASE"); base != "" {
		l.Base = base
		return l, nil
	}

	s, err := source.Load(l.State)
	if err != nil {
		return Layout{}, err
	}
	if s.Checkout != "" {
		l.Base = filepath.Join(s.Checkout, "yonux")
		if info, err := os.Stat(l.Base); err != nil || !info.IsDir() {
			return Layout{}, fmt.Errorf("registered checkout %s not found (recorded by yonux dev-apply)", l.Base)
		}
		return l, nil
	}

	exe, err := os.Executable()
	if err != nil {
		return Layout{}, err
	}
	exe, _ = filepath.EvalSymlinks(exe)
	l.Base = filepath.Join(filepath.Dir(exe), "..", "share", "yonux")
	return l, nil
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func (l Layout) Preferences() string {
	return filepath.Join(l.Config, "yonux", "user_preferences")
}

// manifest lists each laid path, relative to Config.
type manifest []string

func (l Layout) manifestPath() string { return filepath.Join(l.State, "materialize.json") }

func (l Layout) readManifest() (manifest, error) {
	m := manifest{}
	b, err := os.ReadFile(l.manifestPath())
	if os.IsNotExist(err) {
		return m, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read manifest: %w", err)
	}
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, fmt.Errorf("decode manifest: %w", err)
	}
	if m == nil {
		return nil, fmt.Errorf("decode manifest: expected a list, got null")
	}
	if err := validateManifest(m); err != nil {
		return nil, err
	}
	return m, nil
}

func validateManifest(m manifest) error {
	for _, key := range m {
		managed := false
		if !path.IsAbs(key) && path.Clean(key) == key {
			for _, t := range trees {
				if strings.HasPrefix(key, filepath.ToSlash(t.Dst)+"/") {
					managed = true
					break
				}
			}
		}
		if !managed {
			return fmt.Errorf("invalid manifest path %q: expected a normalized relative file path inside a managed tree", key)
		}
	}
	return nil
}

func (l Layout) writeManifest(m manifest) error {
	b, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	if err := os.MkdirAll(l.State, 0o755); err != nil {
		return err
	}
	return os.WriteFile(l.manifestPath(), b, 0o644)
}

// Materialize lays everything on to ~/.config
//  1. each shipped file is copied over the live one;
//  2. a file in user_preferences wins over the shipped one, and can add files
//     the base does not ship;
//  3. edits to live files are overwritten, never saved into user_preferences;
//  4. files laid last time but no longer shipped or preferred are removed,
//     even if their live contents were edited.
func Materialize(l Layout) error {
	if info, err := os.Stat(l.Base); err != nil || !info.IsDir() {
		return fmt.Errorf("base dir not found: %s", l.Base)
	}
	prev, err := l.readManifest()
	if err != nil {
		return err
	}
	next := manifest{}
	laid := map[string]bool{}

	for _, t := range trees {
		src := filepath.Join(l.Base, t.Src)
		prefs := filepath.Join(l.Preferences(), t.Name)
		rels, err := walkAll(src, prefs)
		if err != nil {
			return err
		}
		for _, rel := range rels {
			key := filepath.ToSlash(filepath.Join(t.Dst, rel))
			from := filepath.Join(src, rel)
			if pref := filepath.Join(prefs, rel); exists(pref) {
				from = pref
			}
			if err := copyFile(from, filepath.Join(l.Config, t.Dst, rel)); err != nil {
				return fmt.Errorf("copy %s: %w", key, err)
			}
			next = append(next, key)
			laid[key] = true
		}
	}

	for _, t := range trees {
		root := filepath.Join(l.Config, t.Dst)
		prefix := filepath.ToSlash(t.Dst) + "/"
		for _, key := range prev {
			if laid[key] || !strings.HasPrefix(key, prefix) {
				continue
			}
			rel := filepath.FromSlash(strings.TrimPrefix(key, prefix))
			_ = os.Remove(filepath.Join(root, rel))
			pruneEmptyParents(root, filepath.Dir(rel))
		}
	}

	sort.Strings(next)
	if err := l.writeManifest(next); err != nil {
		return fmt.Errorf("record manifest: %w", err)
	}
	return nil
}

func walkAll(roots ...string) ([]string, error) {
	seen := map[string]bool{}
	for _, root := range roots {
		if !exists(root) {
			continue
		}
		err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.Type().IsRegular() {
				rel, _ := filepath.Rel(root, p)
				seen[rel] = true
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	}

	rels := make([]string, 0, len(seen))
	for rel := range seen {
		rels = append(rels, rel)
	}

	sort.Strings(rels)
	return rels, nil
}

func exists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

// copyFile writes through a temp file and a rename, so a symlink at dst is
// replaced instead of written through (it may point into a clone).
func copyFile(src, dst string) error {
	b, err := os.ReadFile(src)
	if err != nil {
		return err
	}

	info, err := os.Stat(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	tmp, err := os.CreateTemp(filepath.Dir(dst), ".yonux-*")
	if err != nil {
		return err
	}

	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(b); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Chmod(info.Mode().Perm()); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}

	return os.Rename(tmp.Name(), dst)
}

func pruneEmptyParents(root, dir string) {
	for dir != "." && dir != string(filepath.Separator) {
		if os.Remove(filepath.Join(root, dir)) != nil {
			return
		}
		dir = filepath.Dir(dir)
	}
}
