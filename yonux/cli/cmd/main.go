package main

import (
	"fmt"
	"os"

	"joaocunha50/yonux-cli/internal/materialize"
)

const usage = `usage: yonux <command>

commands:
  materialize - lay the shipped config into ~/.config (links into the repo when YONUX_BASE is set)`

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}
	var err error

	switch os.Args[1] {
	case "materialize":
		err = runMaterialize()
	default:
		fmt.Fprintln(os.Stderr, usage)
		os.Exit(2)
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "yonux:", err)
		os.Exit(1)
	}
}

func runMaterialize() error {
	l, err := materialize.DefaultLayout()
	if err != nil {
		return err
	}

	return materialize.Materialize(l)
}
