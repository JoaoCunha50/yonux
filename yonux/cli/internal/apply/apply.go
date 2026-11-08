package apply

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"

	"joaocunha50/yonux-cli/internal/generate"
	"joaocunha50/yonux-cli/internal/materialize"
)

func Run(l materialize.Layout) (err error) {
	if os.Getenv("HYPRLAND_INSTANCE_SIGNATURE") != "" {
		out, e := exec.Command("hyprctl", "getoption", "misc:disable_autoreload", "-j").CombinedOutput()
		if e != nil {
			return fmt.Errorf("read Hyprland autoreload: %w: %s", e, out)
		}
		var option struct {
			Disabled *bool `json:"bool"`
		}
		if e := json.Unmarshal(out, &option); e != nil {
			return fmt.Errorf("read Hyprland autoreload: %w", e)
		}
		if option.Disabled == nil {
			return fmt.Errorf("Hyprland did not return misc:disable_autoreload")
		}
		if !*option.Disabled {
			if e := autoreload(true); e != nil {
				return e
			}
			defer func() {
				err = errors.Join(err, autoreload(false))
				// Disabling autoreload removes watches; events during the copy
				// cannot be replayed when it is enabled again.
				if err == nil {
					out, e := exec.Command("hyprctl", "reload").CombinedOutput()
					if e != nil {
						err = fmt.Errorf("reload applied Hyprland configuration: %w: %s", e, out)
					}
				}
			}()
		}
	}
	if err := materialize.Materialize(l); err != nil {
		return err
	}
	return generate.Run(l)
}

func autoreload(disabled bool) error {
	out, err := exec.Command("hyprctl", "eval", fmt.Sprintf("hl.config({misc = {disable_autoreload = %t}})", disabled)).CombinedOutput()
	if err != nil {
		return fmt.Errorf("set Hyprland autoreload: %w: %s", err, out)
	}
	return nil
}
