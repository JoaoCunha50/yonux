package materialize

import (
	"encoding/json"
	"fmt"
	"io"
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
	{Name: "hypr", Src: "hypr", Dst: "hypr"},
	{Name: "quickshell", Src: "shell/quickshell", Dst: "quickshell/yonux"},
	{Name: "matugen", Src: "shell/matugen", Dst: "yonux/matugen"},
	{Name: "portals", Src: "portals", Dst: "xdg-desktop-portal"},
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

// manifest records ownership separately from originals saved for a future uninstall.
// The old list-only format is accepted when upgrading an existing installation.
type manifest struct {
	Files   []string       `json:"files"`
	Backups []backupRecord `json:"backups,omitempty"`
}

type backupRecord struct {
	Path   string `json:"path"`
	Backup string `json:"backup"`
}

func (l Layout) manifestPath() string { return filepath.Join(l.State, "materialize.json") }

func (l Layout) readManifest() (manifest, error) {
	m := manifest{Files: []string{}}
	b, err := os.ReadFile(l.manifestPath())
	if os.IsNotExist(err) {
		return m, nil
	}
	if err != nil {
		return m, fmt.Errorf("read manifest: %w", err)
	}
	if strings.HasPrefix(strings.TrimSpace(string(b)), "[") {
		err = json.Unmarshal(b, &m.Files)
	} else {
		m = manifest{}
		err = json.Unmarshal(b, &m)
	}
	if err != nil {
		return m, fmt.Errorf("decode manifest: %w", err)
	}
	if m.Files == nil {
		return m, fmt.Errorf("decode manifest: expected a files list")
	}
	for _, key := range m.Files {
		if !managedPath(key) {
			return m, fmt.Errorf("invalid manifest path %q", key)
		}
	}
	for _, record := range m.Backups {
		allowed := managedPath(record.Path)
		for _, t := range trees {
			if record.Path == t.Dst || strings.HasPrefix(t.Dst, record.Path+"/") {
				allowed = normalized(record.Path)
			}
		}
		parts := strings.Split(record.Backup, "/")
		if !allowed || !normalized(record.Backup) || len(parts) < 3 || parts[0] != "backups" ||
			strings.Join(parts[2:], "/") != record.Path {
			return m, fmt.Errorf("invalid manifest backup %q", record.Backup)
		}
	}
	return m, nil
}

func normalized(key string) bool {
	return key != "." && key != ".." && !path.IsAbs(key) &&
		path.Clean(key) == key && !strings.HasPrefix(key, "../") && !strings.Contains(key, "\\")
}

func managedPath(key string) bool {
	if !normalized(key) {
		return false
	}
	for _, t := range trees {
		if rel, ok := strings.CutPrefix(key, t.Dst+"/"); ok && allowedFile(t, rel) {
			return true
		}
	}
	return false
}

func allowedFile(t tree, rel string) bool {
	if t.Name == "hypr" && (rel == "user.lua" || strings.HasPrefix(rel, "user.lua/")) {
		return false
	}
	return t.Name != "portals" || rel == "hyprland-portals.conf"
}

func (l Layout) writeManifest(m manifest) error {
	b, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	if err := plainDirs(l.State); err != nil {
		return err
	}
	return atomicWrite(l.manifestPath(), 0o644, func(w io.Writer) error {
		_, err := w.Write(b)
		return err
	})
}

// Materialize copies shipped config plus user_preferences into the live trees.
// Only previously owned files are pruned. Unmanaged collisions are saved before
// replacement, and symlinked destination directories become independent copies.
func Materialize(l Layout) error {
	if info, err := os.Stat(l.Base); err != nil || !info.IsDir() {
		return fmt.Errorf("base dir not found: %s", l.Base)
	}
	var err error
	l.Config, err = canonicalRoot(l.Config)
	if err != nil {
		return fmt.Errorf("config directory: %w", err)
	}
	l.State, err = canonicalRoot(l.State)
	if err != nil {
		return fmt.Errorf("state directory: %w", err)
	}
	m, err := l.readManifest()
	if err != nil {
		return err
	}
	if err := plainDirs(l.State); err != nil {
		return fmt.Errorf("state directory: %w", err)
	}
	if err := plainDirs(l.Config); err != nil {
		return fmt.Errorf("config directory: %w", err)
	}
	previous := append([]string(nil), m.Files...)
	owned := map[string]bool{}
	for _, key := range m.Files {
		owned[key] = true
	}
	c := composer{layout: l, manifest: &m}
	next := []string{}
	laid := map[string]bool{}
	for _, t := range trees {
		src := filepath.Join(l.Base, t.Src)
		prefs := filepath.Join(l.Preferences(), t.Name)
		rels, err := walkAll(src, prefs)
		if err != nil {
			return err
		}
		for _, rel := range rels {
			if !allowedFile(t, filepath.ToSlash(rel)) {
				continue
			}
			key := filepath.ToSlash(filepath.Join(t.Dst, rel))
			if err := c.prepareParents(key); err != nil {
				return err
			}
			from := filepath.Join(src, rel)
			if pref := filepath.Join(prefs, rel); regular(pref) {
				from = pref
			}
			dst := filepath.Join(l.Config, filepath.FromSlash(key))
			info, err := os.Lstat(dst)
			if err != nil && !os.IsNotExist(err) {
				return err
			}
			if err == nil {
				if !owned[key] {
					if err := c.backup(key); err != nil {
						return err
					}
				}
				if info.IsDir() {
					// Never remove unknown contents of a conflicting directory.
					return fmt.Errorf("copy %s: destination is a directory; refusing to remove its contents", key)
				}
			}
			if !owned[key] {
				// Persist ownership intent before replacing the destination. If
				// this or a later copy fails, retry must not save our own output
				// as a user's original.
				m.Files = append(m.Files, key)
				if err := l.writeManifest(m); err != nil {
					return fmt.Errorf("record ownership of %s: %w", key, err)
				}
				owned[key] = true
			}
			if err := copyFile(from, dst); err != nil {
				return fmt.Errorf("copy %s: %w", key, err)
			}
			next = append(next, key)
			laid[key] = true
		}
	}
	for _, key := range previous {
		if laid[key] {
			continue
		}
		if err := c.prepareParents(key); err != nil {
			return err
		}
		dst := filepath.Join(l.Config, filepath.FromSlash(key))
		if err := os.Remove(dst); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("remove stale %s: %w", key, err)
		}
		for i, file := range m.Files {
			if file == key {
				m.Files = append(m.Files[:i], m.Files[i+1:]...)
				break
			}
		}
		if err := l.writeManifest(m); err != nil {
			return fmt.Errorf("release ownership of %s: %w", key, err)
		}
		for _, t := range trees {
			if rel, ok := strings.CutPrefix(key, t.Dst+"/"); ok {
				pruneEmptyParents(filepath.Join(l.Config, t.Dst), filepath.Dir(filepath.FromSlash(rel)))
			}
		}
	}
	sort.Strings(next)
	m.Files = next
	if err := l.writeManifest(m); err != nil {
		return fmt.Errorf("record manifest: %w", err)
	}
	return nil
}

type composer struct {
	layout   Layout
	manifest *manifest
}

// backup snapshots the directory entry, not a symlink's target. Commit its
// provenance before changing the original, so failed applies retain the record.
func (c *composer) backup(key string) error {
	root := filepath.Join(c.layout.State, "backups")
	if err := plainDirs(root); err != nil {
		return fmt.Errorf("backup directory: %w", err)
	}
	dir, err := os.MkdirTemp(root, "apply-")
	if err != nil {
		return err
	}
	rel := filepath.ToSlash(filepath.Join("backups", filepath.Base(dir), filepath.FromSlash(key)))
	dst := filepath.Join(c.layout.State, filepath.FromSlash(rel))
	if err := plainDirs(filepath.Dir(dst)); err != nil {
		return err
	}
	if err := snapshot(filepath.Join(c.layout.Config, filepath.FromSlash(key)), dst, false); err != nil {
		return fmt.Errorf("backup %s: %w", key, err)
	}
	c.manifest.Backups = append(c.manifest.Backups, backupRecord{Path: key, Backup: rel})
	return c.layout.writeManifest(*c.manifest)
}

func (c *composer) prepareParents(key string) error {
	parts := strings.Split(key, "/")
	for i := 1; i < len(parts); i++ {
		rel := strings.Join(parts[:i], "/")
		dst := filepath.Join(c.layout.Config, filepath.FromSlash(rel))
		info, err := os.Lstat(dst)
		if os.IsNotExist(err) {
			if err := os.Mkdir(dst, 0o755); err != nil {
				return err
			}
			continue
		}
		if err != nil {
			return err
		}
		if info.IsDir() {
			continue
		}
		if err := c.backup(rel); err != nil {
			return err
		}
		tmp, err := os.MkdirTemp(filepath.Dir(dst), ".yonux-migrate-")
		if err != nil {
			return err
		}
		mode := fs.FileMode(0o755)
		if info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Stat(dst)
			if err != nil && !os.IsNotExist(err) {
				os.RemoveAll(tmp)
				return err
			}
			if err == nil && target.IsDir() {
				mode = target.Mode().Perm()
				entries, err := os.ReadDir(dst)
				if err != nil {
					os.RemoveAll(tmp)
					return err
				}
				for _, entry := range entries {
					if err := snapshot(filepath.Join(dst, entry.Name()), filepath.Join(tmp, entry.Name()), true); err != nil {
						os.RemoveAll(tmp)
						return err
					}
				}
			}
		}
		if err := os.Chmod(tmp, mode); err != nil {
			os.RemoveAll(tmp)
			return err
		}
		if err := os.Remove(dst); err != nil {
			os.RemoveAll(tmp)
			return err
		}
		if err := os.Rename(tmp, dst); err != nil {
			os.RemoveAll(tmp)
			return err
		}
	}
	return nil
}

// canonicalRoot resolves only the caller-selected root and its existing
// ancestors. Symlinks below that boundary remain subject to migration or refusal.
func canonicalRoot(dir string) (string, error) {
	abs, err := filepath.Abs(dir)
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err == nil {
		return resolved, nil
	}
	if !os.IsNotExist(err) || filepath.Dir(abs) == abs {
		return "", err
	}
	parent, err := canonicalRoot(filepath.Dir(abs))
	if err != nil {
		return "", err
	}
	return filepath.Join(parent, filepath.Base(abs)), nil
}

// plainDirs refuses symlink ancestors, including the final directory. State and
// backup paths must never redirect writes into a checkout or an unrelated file.
func plainDirs(dir string) error {
	abs, err := filepath.Abs(dir)
	if err != nil {
		return err
	}
	current := string(filepath.Separator)
	for part := range strings.SplitSeq(strings.TrimPrefix(abs, current), string(filepath.Separator)) {
		current = filepath.Join(current, part)
		info, err := os.Lstat(current)
		if os.IsNotExist(err) {
			if err := os.Mkdir(current, 0o755); err != nil {
				return err
			}
			continue
		}
		if err != nil {
			return err
		}
		if !info.IsDir() {
			return fmt.Errorf("directory %s is not a plain directory", current)
		}
	}
	return nil
}

func walkAll(roots ...string) ([]string, error) {
	seen := map[string]bool{}
	for _, root := range roots {
		if _, err := os.Lstat(root); os.IsNotExist(err) {
			continue
		}
		err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.Type().IsRegular() {
				rel, err := filepath.Rel(root, p)
				if err != nil {
					return err
				}
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

func regular(p string) bool {
	info, err := os.Lstat(p)
	return err == nil && info.Mode().IsRegular()
}

// snapshot preserves unknown files and links without traversing linked children.
func snapshot(src, dst string, relocateLinks bool) error {
	info, err := os.Lstat(src)
	if err != nil {
		return err
	}
	switch {
	case info.Mode()&os.ModeSymlink != 0:
		target, err := os.Readlink(src)
		if err != nil {
			return err
		}
		if relocateLinks && !filepath.IsAbs(target) {
			parent, err := filepath.EvalSymlinks(filepath.Dir(src))
			if err != nil {
				return err
			}
			// Keep target's ".." components literal: cleaning them could
			// change the referent when an earlier component is itself a link.
			target = parent + string(filepath.Separator) + target
		}
		return os.Symlink(target, dst)
	case info.IsDir():
		if err := os.Mkdir(dst, 0o755); err != nil {
			return err
		}
		entries, err := os.ReadDir(src)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := snapshot(filepath.Join(src, entry.Name()), filepath.Join(dst, entry.Name()), relocateLinks); err != nil {
				return err
			}
		}
		return os.Chmod(dst, info.Mode().Perm())
	case info.Mode().IsRegular():
		return copyFile(src, dst)
	default:
		return fmt.Errorf("cannot preserve special file %s", src)
	}
}

// copyFile replaces destination symlinks rather than writing through them.
func copyFile(src, dst string) error {
	f, err := os.Open(src)
	if err != nil {
		return err
	}
	defer f.Close()
	info, err := f.Stat()
	if err != nil {
		return err
	}
	return atomicWrite(dst, info.Mode().Perm(), func(w io.Writer) error {
		_, err := io.Copy(w, f)
		return err
	})
}

func atomicWrite(dst string, mode fs.FileMode, write func(io.Writer) error) error {
	tmp, err := os.CreateTemp(filepath.Dir(dst), ".yonux-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if err := write(tmp); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Chmod(mode); err != nil {
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
