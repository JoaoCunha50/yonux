package internal

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"debug/elf"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Desktop files written by SyncAppImages are named appImagePrefix + id + ".desktop"
// so a sync can find and prune the ones whose AppImage is gone.
const appImagePrefix = "yonux-appimage-"

// AppImageDirs are the directories SyncAppImages integrates. dataHome is
// XDG_DATA_HOME: generated desktop files go to dataHome/applications, where
// Quickshell's DesktopEntries (and so the launcher) picks them up, and their icons
// to dataHome/yonux/appimages.
type AppImageDirs struct {
	Source       string
	Applications string
	Icons        string
}

func DefaultAppImageDirs() (AppImageDirs, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return AppImageDirs{}, err
	}
	data := os.Getenv("XDG_DATA_HOME")
	if data == "" {
		data = filepath.Join(home, ".local", "share")
	}
	return AppImageDirs{
		Source:       filepath.Join(home, "Applications"),
		Applications: filepath.Join(data, "applications"),
		Icons:        filepath.Join(data, "yonux", "appimages"),
	}, nil
}

// SyncAppImages writes a desktop entry, with the icon and metadata embedded in the
// AppImage, for every *.AppImage in dirs.Source, and removes the entries of AppImages
// that are no longer there. Entries newer than their AppImage are left alone. launcher
// is the argv prefix that runs an AppImage (["appimage-run"] on NixOS); empty runs the
// file directly. A broken AppImage is reported in the returned error after the others
// are synced.
func SyncAppImages(dirs AppImageDirs, launcher []string) error {
	entries, err := os.ReadDir(dirs.Source)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	keep := map[string]bool{}
	var errs []error
	for _, entry := range entries {
		if entry.IsDir() || !strings.EqualFold(filepath.Ext(entry.Name()), ".appimage") {
			continue
		}
		path := filepath.Join(dirs.Source, entry.Name())
		id := appImageID(path)
		keep[id] = true
		if err := syncAppImage(dirs, path, id, launcher); err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", entry.Name(), err))
		}
	}
	if err := pruneAppImages(dirs, keep); err != nil {
		errs = append(errs, err)
	}
	return errors.Join(errs...)
}

func appImageID(path string) string {
	sum := sha256.Sum256([]byte(path))
	return hex.EncodeToString(sum[:6])
}

func syncAppImage(dirs AppImageDirs, path, id string, launcher []string) error {
	desktopPath := filepath.Join(dirs.Applications, appImagePrefix+id+".desktop")
	source, err := os.Stat(path)
	if err != nil {
		return err
	}
	if current, err := os.Stat(desktopPath); err == nil && !current.ModTime().Before(source.ModTime()) {
		return nil
	}

	image, err := openAppImage(path)
	if err != nil {
		return err
	}
	desktopName, err := image.rootDesktopFile()
	if err != nil {
		return err
	}
	desktop, err := image.cat(desktopName)
	if err != nil {
		return err
	}
	iconPath, err := image.extractIcon(dirs.Icons, id, desktopEntryValue(desktop, "Icon"))
	if err != nil {
		return err
	}
	if err := os.MkdirAll(dirs.Applications, 0o755); err != nil {
		return err
	}
	return writeAtomic(desktopPath, rewriteDesktopEntry(desktop, path, iconPath, launcher))
}

// appImage is a type 2 AppImage: an ELF runtime followed by a SquashFS image, read
// with unsquashfs so the AppImage needs neither the executable bit nor FUSE.
type appImage struct {
	path   string
	offset int64
}

func openAppImage(path string) (appImage, error) {
	f, err := os.Open(path)
	if err != nil {
		return appImage{}, err
	}
	defer f.Close()

	var ident [elf.EI_NIDENT]byte
	if _, err := io.ReadFull(f, ident[:]); err != nil {
		return appImage{}, fmt.Errorf("not an AppImage: %w", err)
	}
	if string(ident[:4]) != elf.ELFMAG || ident[8] != 'A' || ident[9] != 'I' {
		return appImage{}, errors.New("not an AppImage")
	}
	if ident[10] != 2 {
		return appImage{}, fmt.Errorf("unsupported AppImage type %d", ident[10])
	}
	var order binary.ByteOrder = binary.LittleEndian
	if elf.Data(ident[elf.EI_DATA]) == elf.ELFDATA2MSB {
		order = binary.BigEndian
	}
	if _, err := f.Seek(0, io.SeekStart); err != nil {
		return appImage{}, err
	}
	// The SquashFS image starts right after the section header table, which is
	// the last part of the runtime.
	var offset int64
	switch elf.Class(ident[elf.EI_CLASS]) {
	case elf.ELFCLASS64:
		var h elf.Header64
		if err := binary.Read(f, order, &h); err != nil {
			return appImage{}, err
		}
		offset = int64(h.Shoff) + int64(h.Shentsize)*int64(h.Shnum)
	case elf.ELFCLASS32:
		var h elf.Header32
		if err := binary.Read(f, order, &h); err != nil {
			return appImage{}, err
		}
		offset = int64(h.Shoff) + int64(h.Shentsize)*int64(h.Shnum)
	default:
		return appImage{}, errors.New("not an AppImage: unknown ELF class")
	}
	return appImage{path: path, offset: offset}, nil
}

func (a appImage) unsquashfs(args ...string) ([]byte, error) {
	args = append([]string{"-o", fmt.Sprint(a.offset)}, args...)
	cmd := exec.Command("unsquashfs", args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("unsquashfs: %w: %s", err, strings.TrimSpace(stderr.String()))
	}
	return out, nil
}

func (a appImage) cat(name string) ([]byte, error) {
	return a.unsquashfs("-cat", a.path, name)
}

// rootDesktopFile returns the name of the desktop file the AppImage spec requires
// at the top level of the image.
func (a appImage) rootDesktopFile() (string, error) {
	listing, err := a.unsquashfs("-lc", a.path)
	if err != nil {
		return "", err
	}
	for line := range strings.Lines(string(listing)) {
		name, ok := strings.CutPrefix(strings.TrimSpace(line), "squashfs-root/")
		if ok && !strings.Contains(name, "/") && strings.HasSuffix(name, ".desktop") {
			return name, nil
		}
	}
	return "", errors.New("no desktop file at the top of the AppImage")
}

// extractIcon copies the AppImage's icon (.DirIcon, else the top-level file named by
// the desktop entry's Icon key) to dir/id.png or dir/id.svg and returns its path.
// It returns "" when the AppImage has no usable icon.
func (a appImage) extractIcon(dir, id, iconName string) (string, error) {
	candidates := []string{".DirIcon"}
	if iconName != "" && !strings.Contains(iconName, "/") {
		candidates = append(candidates, iconName+".png", iconName+".svg")
	}
	for _, name := range candidates {
		data, err := a.cat(name)
		if err != nil || len(data) == 0 {
			continue
		}
		ext := iconExtension(data)
		if ext == "" {
			continue
		}
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return "", err
		}
		for _, stale := range []string{".png", ".svg"} {
			if stale != ext {
				os.Remove(filepath.Join(dir, id+stale))
			}
		}
		path := filepath.Join(dir, id+ext)
		return path, writeAtomic(path, data)
	}
	return "", nil
}

func iconExtension(data []byte) string {
	if bytes.HasPrefix(data, []byte("\x89PNG\r\n\x1a\n")) {
		return ".png"
	}
	head := data[:min(len(data), 512)]
	if bytes.Contains(head, []byte("<svg")) || bytes.HasPrefix(bytes.TrimSpace(head), []byte("<?xml")) {
		return ".svg"
	}
	return ""
}

// desktopEntryValue returns the unlocalized value of key in the [Desktop Entry] group.
func desktopEntryValue(desktop []byte, key string) string {
	group := ""
	scanner := bufio.NewScanner(bytes.NewReader(desktop))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "[") {
			group = line
			continue
		}
		if k, v, ok := strings.Cut(line, "="); ok && group == "[Desktop Entry]" && strings.TrimSpace(k) == key {
			return strings.TrimSpace(v)
		}
	}
	return ""
}

// rewriteDesktopEntry keeps the [Desktop Entry] group of the AppImage's desktop file
// and points it at the AppImage: Exec runs it through launcher with the original
// arguments and field codes, Icon is the extracted icon. Desktop actions are dropped
// because their Exec lines refer to binaries inside the image.
func rewriteDesktopEntry(desktop []byte, appImagePath, iconPath string, launcher []string) []byte {
	var out bytes.Buffer
	group := ""
	args := ""
	scanner := bufio.NewScanner(bytes.NewReader(desktop))
	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "[") {
			group = trimmed
			if group == "[Desktop Entry]" {
				text := line + "\n"
				out.WriteString(text)
			}
			continue
		}
		if group != "[Desktop Entry]" || trimmed == "" {
			continue
		}
		key, value, _ := strings.Cut(trimmed, "=")
		switch strings.TrimSpace(key) {
		case "Exec":
			args = execArguments(strings.TrimSpace(value))
		case "TryExec", "Icon", "Actions", "DBusActivatable":
		default:
			text := line + "\n"
			out.WriteString(text)
		}
	}

	argv := append(append([]string{}, launcher...), appImagePath)
	quoted := make([]string, len(argv))
	for i, arg := range argv {
		quoted[i] = quoteExecArgument(arg)
	}
	exec := strings.Join(quoted, " ")
	if args != "" {
		exec += " " + args
	}
	fmt.Fprintf(&out, "Exec=%s\n", exec)
	if iconPath != "" {
		fmt.Fprintf(&out, "Icon=%s\n", iconPath)
	}
	fmt.Fprintf(&out, "X-Yonux-AppImage=%s\n", appImagePath)
	return out.Bytes()
}

func execArguments(exec string) string {
	if rest, ok := strings.CutPrefix(exec, `"`); ok {
		for i := 0; i < len(rest); i++ {
			switch rest[i] {
			case '\\':
				i++
			case '"':
				return strings.TrimSpace(rest[i+1:])
			}
		}
		return ""
	}
	_, args, _ := strings.Cut(exec, " ")
	return strings.TrimSpace(args)
}

func quoteExecArgument(arg string) string {
	var b strings.Builder
	b.WriteByte('"')
	for _, r := range arg {
		switch r {
		case '"', '`', '$', '\\':
			b.WriteByte('\\')
		}
		b.WriteRune(r)
	}
	b.WriteByte('"')
	quoted := strings.ReplaceAll(b.String(), `\`, `\\`)
	return strings.ReplaceAll(quoted, "%", "%%")
}

func pruneAppImages(dirs AppImageDirs, keep map[string]bool) error {
	entries, err := os.ReadDir(dirs.Applications)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	var errs []error
	for _, entry := range entries {
		id, ok := strings.CutPrefix(entry.Name(), appImagePrefix)
		id, isDesktop := strings.CutSuffix(id, ".desktop")
		if !ok || !isDesktop || keep[id] {
			continue
		}
		for _, path := range []string{
			filepath.Join(dirs.Applications, entry.Name()),
			filepath.Join(dirs.Icons, id+".png"),
			filepath.Join(dirs.Icons, id+".svg"),
		} {
			if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
				errs = append(errs, err)
			}
		}
	}
	return errors.Join(errs...)
}

func writeAtomic(path string, data []byte) error {
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Chmod(0o644); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), path)
}
