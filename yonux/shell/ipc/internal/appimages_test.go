package internal

import (
	"bytes"
	"debug/elf"
	"encoding/binary"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

const testDesktop = `[Desktop Entry]
Name=Sample
Name[pt]=Exemplo
Exec=AppRun --flag %U
TryExec=AppRun
Icon=sample
Actions=new;
Type=Application

[Desktop Action new]
Name=New
Exec=AppRun --new
`

func TestRewriteDesktopEntry(t *testing.T) {
	got := string(rewriteDesktopEntry([]byte(testDesktop), `/apps/My $App 100%.AppImage`, "/icons/x.png", []string{"appimage-run"}))
	want := `[Desktop Entry]
Name=Sample
Name[pt]=Exemplo
Type=Application
Exec="appimage-run" "/apps/My \\$App 100%%.AppImage" --flag %U
Icon=/icons/x.png
X-Yonux-AppImage=/apps/My $App 100%.AppImage
`
	if got != want {
		t.Fatalf("rewriteDesktopEntry =\n%s\nwant\n%s", got, want)
	}
}

func TestExecArguments(t *testing.T) {
	for in, want := range map[string]string{
		"AppRun":                      "",
		"AppRun %U":                   "%U",
		`"/opt/my \"app\"" --x %F`:    "--x %F",
		`"/opt/unterminated --x %F`:   "",
		"wispr-flow --no-sandbox  %U": "--no-sandbox  %U",
	} {
		if got := execArguments(in); got != want {
			t.Errorf("execArguments(%q) = %q; want %q", in, got, want)
		}
	}
}

// writeTestAppImage builds a minimal type 2 AppImage: an ELF header carrying the
// AppImage magic, followed by a SquashFS image of root.
func writeTestAppImage(t *testing.T, path string, root map[string]string) {
	t.Helper()
	tree := t.TempDir()
	for name, body := range root {
		if err := os.WriteFile(filepath.Join(tree, name), []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	squashfs := filepath.Join(t.TempDir(), "fs")
	if out, err := exec.Command("mksquashfs", tree, squashfs, "-quiet", "-no-progress").CombinedOutput(); err != nil {
		t.Fatalf("mksquashfs: %v: %s", err, out)
	}
	image, err := os.ReadFile(squashfs)
	if err != nil {
		t.Fatal(err)
	}
	header := elf.Header64{Shoff: 64, Shentsize: 64, Shnum: 2, Ehsize: 64}
	copy(header.Ident[:], elf.ELFMAG)
	header.Ident[elf.EI_CLASS] = byte(elf.ELFCLASS64)
	header.Ident[elf.EI_DATA] = byte(elf.ELFDATA2LSB)
	header.Ident[8], header.Ident[9], header.Ident[10] = 'A', 'I', 2
	var buf bytes.Buffer
	if err := binary.Write(&buf, binary.LittleEndian, header); err != nil {
		t.Fatal(err)
	}
	buf.Write(make([]byte, 64+2*64-buf.Len()))
	buf.Write(image)
	if err := os.WriteFile(path, buf.Bytes(), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestSyncAppImages(t *testing.T) {
	for _, tool := range []string{"mksquashfs", "unsquashfs"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skip(tool, "not installed")
		}
	}
	dir := t.TempDir()
	dirs := AppImageDirs{
		Source:       filepath.Join(dir, "Applications"),
		Applications: filepath.Join(dir, "share", "applications"),
		Icons:        filepath.Join(dir, "share", "yonux", "appimages"),
	}
	if err := os.MkdirAll(dirs.Source, 0o755); err != nil {
		t.Fatal(err)
	}
	png := "\x89PNG\r\n\x1a\nfake"
	sample := filepath.Join(dirs.Source, "Sample.AppImage")
	writeTestAppImage(t, sample, map[string]string{
		"sample.desktop": testDesktop,
		"sample.png":     png,
	})
	if err := os.WriteFile(filepath.Join(dirs.Source, "broken.AppImage"), []byte("not elf"), 0o644); err != nil {
		t.Fatal(err)
	}

	err := SyncAppImages(dirs, nil)
	if err == nil || !strings.Contains(err.Error(), "broken.AppImage") {
		t.Fatalf("SyncAppImages error = %v; want the broken AppImage reported", err)
	}
	id := appImageID(sample)
	desktopPath := filepath.Join(dirs.Applications, appImagePrefix+id+".desktop")
	desktop, err := os.ReadFile(desktopPath)
	if err != nil {
		t.Fatal(err)
	}
	icon := filepath.Join(dirs.Icons, id+".png")
	if got := desktopEntryValue(desktop, "Icon"); got != icon {
		t.Errorf("Icon = %q; want %q", got, icon)
	}
	if got := desktopEntryValue(desktop, "Exec"); got != `"`+sample+`" --flag %U` {
		t.Errorf("Exec = %q", got)
	}
	if data, _ := os.ReadFile(icon); string(data) != png {
		t.Errorf("icon = %q; want the AppImage's sample.png", data)
	}

	if err := os.Remove(sample); err != nil {
		t.Fatal(err)
	}
	SyncAppImages(dirs, nil)
	for _, path := range []string{desktopPath, icon} {
		if _, err := os.Stat(path); !os.IsNotExist(err) {
			t.Errorf("%s survived the removal of its AppImage", path)
		}
	}
}
