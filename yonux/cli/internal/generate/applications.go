package generate

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
)

type desktopApp struct {
	command   []string
	directory string
	terminal  bool
}

// Match Quickshell DesktopEntries rather than invoking a launcher/session. IDs
// omit .desktop, nested directory components join with '-', and user entries
// override system entries. Hidden entries mask lower-priority installations;
// NoDisplay entries are excluded by Keybindings.qml's applications property.
// Exec parsing follows DesktopEntry::parseExecString, including stripping field
// codes (rather than expanding %c/%i, which Quickshell does not expand):
// https://github.com/quickshell-mirror/quickshell/blob/master/src/core/desktopentry.cpp
func applications() map[string]desktopApp {
	home := os.Getenv("XDG_DATA_HOME")
	if home == "" && os.Getenv("HOME") != "" {
		home = filepath.Join(os.Getenv("HOME"), ".local", "share")
	}
	dirs := os.Getenv("XDG_DATA_DIRS")
	if dirs == "" {
		dirs = "/usr/local/share:/usr/share"
	}
	roots := []string{}
	if home != "" {
		roots = append(roots, home)
	}
	for dir := range strings.SplitSeq(dirs, ":") {
		if dir != "" {
			roots = append(roots, dir)
		}
	}

	apps := make(map[string]desktopApp)
	for _, v := range slices.Backward(roots) {
		scanApplications(filepath.Join(v, "applications"), "", apps, make(map[string]bool))
	}

	return apps
}

func scanApplications(dir, prefix string, apps map[string]desktopApp, ancestors map[string]bool) {
	// Qt follows application-directory symlinks. Resolve them here too, without
	// recursing forever if a user's directory contains a symlink back to itself.
	real, err := filepath.EvalSymlinks(dir)
	if err != nil || ancestors[real] {
		return
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		return // Quickshell skips unreadable desktop directories and files.
	}
	ancestors[real] = true
	defer delete(ancestors, real)
	for _, entry := range entries {
		path := filepath.Join(dir, entry.Name())
		info, err := os.Stat(path)
		if err != nil {
			continue
		}
		id := prefix + entry.Name()
		if info.IsDir() {
			scanApplications(path, id+"-", apps, ancestors)
			continue
		}
		if !info.Mode().IsRegular() || !strings.HasSuffix(id, ".desktop") {
			continue
		}
		body, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		id = strings.TrimSuffix(id, ".desktop")
		fields := desktopFields(string(body))
		if fields["Type"] != "Application" {
			continue
		}
		if fields["Hidden"] == "true" {
			delete(apps, id)
			continue
		}
		if fields["Name"] == "" {
			continue
		}
		if fields["NoDisplay"] == "true" {
			delete(apps, id)
			continue
		}
		apps[id] = desktopApp{
			command:   parseExec(fields["Exec"]),
			directory: fields["Path"],
			terminal:  fields["Terminal"] == "true",
		}
	}
}

func desktopFields(body string) map[string]string {
	fields := make(map[string]string)
	scores := make(map[string]int)
	locale := os.Getenv("LC_MESSAGES")
	if locale == "" {
		locale = os.Getenv("LANG")
	}
	section := ""
	for line := range strings.SplitSeq(body, "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			section = line[1 : len(line)-1]
			continue
		}
		if section != "Desktop Entry" {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		score := 0
		localized := false
		if start := strings.IndexByte(key, '['); start != -1 && strings.HasSuffix(key, "]") {
			localized = true
			score = localeScore(locale, key[start+1:len(key)-1])
			key = key[:start]
		}
		oldScore, exists := scores[key]
		if !exists || score > oldScore || oldScore == 0 && !localized {
			fields[key] = value
			scores[key] = score
		}
	}
	return fields
}

func localeParts(locale string) (language, territory, modifier string) {
	locale, modifier, _ = strings.Cut(locale, "@")
	locale, _, _ = strings.Cut(locale, ".")
	language, territory, _ = strings.Cut(locale, "_")
	return
}

func localeScore(system, candidate string) int {
	language, territory, modifier := localeParts(system)
	otherLanguage, otherTerritory, otherModifier := localeParts(candidate)
	if language != otherLanguage || otherModifier != "" && modifier != otherModifier || otherTerritory != "" && territory != otherTerritory {
		return 0
	}
	score := 1
	if otherTerritory != "" {
		score += 2
	}
	if otherModifier != "" {
		score++
	}
	return score
}

func parseExec(exec string) []string {
	var arguments []string
	var current strings.Builder
	quoted, percent := false, false
	escape := 0
	for _, char := range exec {
		switch {
		case escape == 0 && char == '\\':
			escape = 1
		case quoted:
			switch {
			case char == '\\':
				escape++
				if escape == 4 {
					current.WriteByte('\\')
					escape = 0
				}
			case escape == 2:
				current.WriteRune(char)
				escape = 0
			case escape != 0:
				switch char {
				case 's':
					current.WriteByte(' ')
				case 'n':
					current.WriteByte('\n')
				case 't':
					current.WriteByte('\t')
				case 'r':
					current.WriteByte('\r')
				default:
					current.WriteRune(char)
				}
				escape = 0
			case char == '"' || char == '\'':
				quoted = false
			default:
				current.WriteRune(char)
			}
		case escape != 0:
			current.WriteRune(char)
			escape = 0
		case percent:
			if char == '%' {
				current.WriteByte('%')
			}
			percent = false
		case char == '%':
			percent = true
		case char == '"' || char == '\'':
			quoted = true
		case char == ' ':
			if current.Len() > 0 {
				arguments = append(arguments, current.String())
				current.Reset()
			}
		default:
			current.WriteRune(char)
		}
	}
	if current.Len() > 0 {
		arguments = append(arguments, current.String())
	}
	return arguments
}
