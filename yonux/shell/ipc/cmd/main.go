package main

import (
	"fmt"
	"os"

	"yonux/shell/ipc/internal"
)

const usage = `usage: yonux-ipc <command>

commands:
  theme <wallpaper> [scheme] - render the matugen templates and print the palette as JSON`

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}
	var err error

	switch os.Args[1] {
	case "theme":
		err = theme(os.Args[2:])
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
