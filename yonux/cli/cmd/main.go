package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"joaocunha50/yonux-cli/internal/apply"
	devapply "joaocunha50/yonux-cli/internal/dev-apply"
	"joaocunha50/yonux-cli/internal/materialize"
)

const usage = `usage: yonux <command>

commands:
  install                        - prepare user configuration from the selected base
  apply                          - reapply the selected base and personal overrides
  materialize                    - lay the shipped config into ~/.config
  dev-apply --from <clone root>  - build and install a clone for normal use, and record it as the source`

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}
	var err error

	switch os.Args[1] {
	case "materialize":
		err = runMaterialize()
	case "install", "apply":
		if len(os.Args) != 2 {
			err = errUsage
			break
		}

		l, e := materialize.DefaultLayout()
		if e != nil {
			err = e
		} else {
			err = apply.Run(l)
		}
	case "dev-apply":
		err = runDevApply(os.Args[2:])
	default:
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}

	if errors.Is(err, errUsage) {
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "yonux:", err)
		os.Exit(1)
	}
}

var errUsage = errors.New("usage")

func runMaterialize() error {
	l, err := materialize.DefaultLayout()
	if err != nil {
		return err
	}

	return materialize.Materialize(l)
}

func runDevApply(args []string) error {
	fs := flag.NewFlagSet("dev-apply", flag.ContinueOnError)
	from := fs.String("from", "", "root of the yonux clone")
	fs.SetOutput(io.Discard)
	if err := fs.Parse(args); err != nil || *from == "" || fs.NArg() > 0 {
		return errUsage
	}

	l, err := materialize.UserLayout()
	if err != nil {
		return err
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	t := devapply.Target{Layout: l, Bin: filepath.Join(home, ".local", "bin")}
	if err := devapply.Run(*from, t, devapply.GoBuild); err != nil {
		return err
	}
	abs, _ := filepath.Abs(*from)
	fmt.Println("applied", abs)
	return nil
}
