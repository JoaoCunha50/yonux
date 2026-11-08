package internal

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type MatugenScheme int

const (
	Smart MatugenScheme = iota
	FruitSalad
	TonalSpot
	Content
	Expressive
	Fidelity
	MonoChrome
	Neutral
	Rainbow
	Vibrant
)

var schemeNames = map[MatugenScheme]string{
	Smart:      "scheme-smart",
	FruitSalad: "scheme-fruit-salad",
	TonalSpot:  "scheme-tonal-spot",
	Content:    "scheme-content",
	Expressive: "scheme-expressive",
	Fidelity:   "scheme-fidelity",
	MonoChrome: "scheme-monochrome",
	Neutral:    "scheme-neutral",
	Rainbow:    "scheme-rainbow",
	Vibrant:    "scheme-vibrant",
}

func (s MatugenScheme) String() string { return schemeNames[s] }

func ParseScheme(name string) (MatugenScheme, error) {
	name = "scheme-" + strings.TrimPrefix(name, "scheme-")
	for s, n := range schemeNames {
		if n == name {
			return MatugenScheme(s), nil
		}
	}
	return 0, fmt.Errorf("unknown scheme %q", name)
}

func MatugenConfig() (string, error) {
	// Environment variable for dev.sh mode.
	if p := os.Getenv("YONUX_MATUGEN_CONFIG"); p != "" {
		return p, nil
	}
	dir := os.Getenv("XDG_CONFIG_HOME")
	if dir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		dir = filepath.Join(home, ".config")
	}
	return filepath.Join(dir, "yonux", "matugen", "config.toml"), nil
}

func ChangeShellTheme(wallpaper string, scheme MatugenScheme) ([]byte, error) {
	if _, err := os.Stat(wallpaper); err != nil {
		return nil, fmt.Errorf("wallpaper: %w", err)
	}
	config, err := MatugenConfig()
	if err != nil {
		return nil, err
	}
	if _, err := os.Stat(config); err != nil {
		return nil, fmt.Errorf("matugen config missing, run `yonux materialize`: %w", err)
	}

	var stdout, stderr bytes.Buffer
	cmd := exec.Command("matugen", "image", wallpaper,
		"-c", config, "-j", "hex", "--prefer", "darkness", "-m", "dark", "-t", scheme.String())

	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("matugen: %w: %s", err, strings.TrimSpace(stderr.String()))
	}

	return stdout.Bytes(), nil
}
