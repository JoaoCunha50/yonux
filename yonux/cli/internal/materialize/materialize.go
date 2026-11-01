package materialize

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"
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
	Link   bool   // dev mode - symlink into Base instead of copying
}

func DefaultLayout() (Layout, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return Layout{}, err
	}

	l := Layout{
		Config: envOr("XDG_CONFIG_HOME", filepath.Join(home, ".config")),
		State:  filepath.Join(envOr("XDG_STATE_HOME", filepath.Join(home, ".local", "state")), "yonux"),
	}
	if base := os.Getenv("YONUX_BASE"); base != "" {
		l.Base, l.Link = base, true
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

// manifest maps each laid path (relative to Config) to the hash of what was laid there, or "" for a symlink.
type manifest map[string]string

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
		return nil, fmt.Errorf("decode manifest: expected an object, got null")
	}
	if err := validateManifest(m); err != nil {
		return nil, err
	}
	return m, nil
}

func validateManifest(m manifest) error {
	for key := range m {
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
//  1. each shipped file is copied (or linked, in dev) over the live one;
//  2. a file in user_preferences wins over the shipped one, and can add files
//     the base does not ship;
//  3. edits to live files are overwritten, never saved into user_preferences;
//  4. files laid last time but no longer shipped or preferred are removed,
//     even if their live contents were edited.
func Materialize(l Layout) error {
	if info, err := os.Stat(l.Base); err != nil || !info.IsDir() {
		return fmt.Errorf("base dir not found: %s (set YONUX_BASE to the repo's yonux/ folder in dev)", l.Base)
	}
	prev, err := l.readManifest()
	if err != nil {
		return err
	}
	next := manifest{}

	for _, t := range trees {
		src := filepath.Join(l.Base, t.Src)
		prefs := filepath.Join(l.Preferences(), t.Name)
		rels, err := walkAll(src, prefs)
		if err != nil {
			return err
		}
		for _, rel := range rels {
			key := filepath.ToSlash(filepath.Join(t.Dst, rel))
			dst := filepath.Join(l.Config, t.Dst, rel)
			pref := filepath.Join(prefs, rel)
			shipped := filepath.Join(src, rel)

			from, link := shipped, l.Link
			if exists(pref) {
				from, link = pref, false
			}

			if link {
				if err := linkFile(from, dst); err != nil {
					return fmt.Errorf("link %s: %w", key, err)
				}
				next[key] = ""
				continue
			}
			h, err := copyFile(from, dst)
			if err != nil {
				return fmt.Errorf("copy %s: %w", key, err)
			}
			next[key] = h
		}
	}

	for _, t := range trees {
		root := filepath.Join(l.Config, t.Dst)
		prefix := filepath.ToSlash(t.Dst) + "/"
		for key := range prev {
			if _, ok := next[key]; ok || !strings.HasPrefix(key, prefix) {
				continue
			}
			rel := filepath.FromSlash(strings.TrimPrefix(key, prefix))
			_ = os.Remove(filepath.Join(root, rel))
			pruneEmptyParents(root, filepath.Dir(rel))
		}
	}

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

func hashBytes(b []byte) string {
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

// copyFile writes through a temp file and a rename, so a symlink at dst is
// replaced instead of written through (in dev it would point into the repo).
func copyFile(src, dst string) (string, error) {
	b, err := os.ReadFile(src)
	if err != nil {
		return "", err
	}

	info, err := os.Stat(src)
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return "", err
	}

	tmp, err := os.CreateTemp(filepath.Dir(dst), ".yonux-*")
	if err != nil {
		return "", err
	}

	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(b); err != nil {
		tmp.Close()
		return "", err
	}
	if err := tmp.Chmod(info.Mode().Perm()); err != nil {
		tmp.Close()
		return "", err
	}
	if err := tmp.Close(); err != nil {
		return "", err
	}

	return hashBytes(b), os.Rename(tmp.Name(), dst)
}

func linkFile(src, dst string) error {
	if cur, err := os.Readlink(dst); err == nil && cur == src {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	tmp := dst + ".yonux-link"
	_ = os.Remove(tmp)
	if err := os.Symlink(src, tmp); err != nil {
		return err
	}

	return os.Rename(tmp, dst)
}

func pruneEmptyParents(root, dir string) {
	for dir != "." && dir != string(filepath.Separator) {
		if os.Remove(filepath.Join(root, dir)) != nil {
			return
		}
		dir = filepath.Dir(dir)
	}
}
