package main

import (
	"fmt"
	"os"
	"os/exec"

	"yonux/shell/ipc/internal"
)

const usage = `usage: yonux-ipc <command>

commands:
  theme <wallpaper> [scheme] - render the matugen templates and print the palette as JSON
  appimages                  - write desktop entries for the AppImages in ~/Applications`

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}
	var err error

	switch os.Args[1] {
	case "theme":
		err = theme(os.Args[2:])
	case "appimages":
		err = appImages(os.Args[2:])
	default:
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "yonux-ipc:", err)
		os.Exit(1)
	}
}

func theme(args []string) error {
	if len(args) < 1 || len(args) > 2 {
		return fmt.Errorf("usage: yonux-ipc theme <wallpaper> [scheme]")
	}
	scheme := internal.TonalSpot
	if len(args) == 2 {
		var err error
		if scheme, err = internal.ParseScheme(args[1]); err != nil {
			return err
		}
	}

	palette, err := internal.ChangeShellTheme(args[0], scheme)
	if err != nil {
		return err
	}
	_, err = os.Stdout.Write(palette)
	return err
}

func appImages(args []string) error {
	if len(args) != 0 {
		return fmt.Errorf("usage: yonux-ipc appimages")
	}
	dirs, err := internal.DefaultAppImageDirs()
	if err != nil {
		return err
	}
	// NixOS cannot run AppImages without its FHS wrapper, and appimage-run also
	// runs files that lack the executable bit.
	var launcher []string
	if _, err := exec.LookPath("appimage-run"); err == nil {
		launcher = []string{"appimage-run"}
	}
	return internal.SyncAppImages(dirs, launcher)
}
