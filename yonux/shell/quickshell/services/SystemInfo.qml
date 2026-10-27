pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import yonux.services

Singleton {
    id: root

    property var os: ({})
    readonly property string distro: os.PRETTY_NAME ?? os.NAME ?? "Linux"
    readonly property string logo: os.LOGO ?? `distributor-logo-${os.ID ?? "linux"}`
    readonly property bool nixos: os.ID === "nixos"

    property var facts: ({})
    property real uptimeSeconds: 0

    readonly property string uptime: {
        let minutes = Math.floor(uptimeSeconds / 60);
        let days = Math.floor(minutes / 1440);
        let hours = Math.floor(minutes % 1440 / 60);
        let parts = [];
        if (days)
            parts.push(`${days}d`);
        if (hours)
            parts.push(`${hours}h`);
        parts.push(`${minutes % 60}m`);
        return parts.join(" ");
    }

    readonly property string installed: {
        let birth = parseInt(facts.installed);
        if (!birth)
            return "";
        let days = Math.floor((Date.now() / 1000 - birth) / 86400);
        let date = Qt.formatDate(new Date(birth * 1000), "d MMM yyyy");
        return `${date} · ${days} days ago`;
    }

    readonly property string displays: {
        let result = [];
        for (let screen of Quickshell.screens) {
            let refresh = Hyprland.monitorFor(screen)?.lastIpcObject?.refreshRate;
            result.push(`${screen.name} ${screen.width}×${screen.height}${refresh ? ` @ ${Math.round(refresh)} Hz` : ""}`);
        }
        return result.join(", ");
    }

    readonly property string repoUrl: {
        let remote = facts.repo ?? "";
        let ssh = remote.match(/^git@([^:]+):(.+?)(\.git)?$/);
        if (ssh)
            return `https://${ssh[1]}/${ssh[2]}`;
        return remote.replace(/\.git$/, "");
    }

    readonly property var rows: [["OS", distro], ["Kernel", facts.kernel], ["Host", facts.host], ["Uptime", uptime], ["Installed", installed], ["CPU", facts.cpu], ["GPU", facts.gpu], ["Memory", SystemStats.memoryTotalGiB ? `${SystemStats.memoryTotalGiB.toFixed(1)} GiB` : ""], ["Displays", displays], ["Packages", facts.packages], ["Hyprland", facts.hyprland], ["Quickshell", facts.quickshell], ["yonux", facts.yonux], ["Generation", nixos ? facts.generation : ""], ["Nixpkgs", nixos ? facts.nixpkgs : ""]].filter(row => row[1])

    function refresh(): void {
        Hyprland.refreshMonitors();
        uptimeFile.reload();
        probe.running = true;
    }

    function asText(): string {
        return rows.map(row => `${row[0]}: ${row[1]}`).join("\n");
    }

    Component.onCompleted: refresh()

    FileView {
        path: "/etc/os-release"

        onLoaded: {
            let fields = {};
            for (let line of text().split("\n")) {
                let match = line.match(/^(\w+)=(.*)$/);
                if (match)
                    fields[match[1]] = match[2].replace(/^"|"$/g, "");
            }
            root.os = fields;
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = parseFloat(text())
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    // POSIX sh so it runs the same on different distros
    Process {
        id: probe
        command: ["sh", "-c", `
            has() { command -v "$1" >/dev/null 2>&1; }
            echo "kernel=$(uname -r)"
            echo "host=$(cat /proc/sys/kernel/hostname 2>/dev/null)"
            echo "cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')"
            has lspci && lspci -mm | grep -E '"(VGA compatible controller|3D controller|Display controller)"' | awk -F'"' '{ print "gpu=" $6 }'
            echo "installed=$(stat -c %W / 2>/dev/null)"
            has hyprctl && echo "hyprland=$(hyprctl version -j 2>/dev/null | sed -n 's/.*"version": *"\\([^"]*\\)".*/\\1/p' | head -1)"
            has qs && echo "quickshell=$(qs --version 2>/dev/null | sed -n 's/^Quickshell \\([^ ]*\\).*/\\1/p')"
            repo="$(dirname "$(readlink -f "$1/shell.qml")")"
            has git && echo "yonux=$(git -C "$repo" describe --tags --always --dirty 2>/dev/null)"
            has git && echo "repo=$(git -C "$repo" remote get-url origin 2>/dev/null)"
            if [ -e /run/current-system ]; then
                echo "generation=$(readlink /nix/var/nix/profiles/system 2>/dev/null | sed -n 's/.*system-\\([0-9]*\\)-link/\\1/p')"
                has nixos-version && echo "nixpkgs=$(nixos-version --json 2>/dev/null | sed -n 's/.*"nixpkgsRevision":"\\([0-9a-f]\\{7\\}\\).*/\\1/p')"
            fi
            packages=""
            count() { [ "$2" -gt 0 ] 2>/dev/null && packages="$packages, $2 ($1)"; }
            [ -e /run/current-system ] && has nix-store && count nix "$(nix-store -qR /run/current-system 2>/dev/null | wc -l)"
            has pacman && count pacman "$(pacman -Qq 2>/dev/null | wc -l)"
            has rpm && count rpm "$(rpm -qa 2>/dev/null | wc -l)"
            has dpkg-query && count dpkg "$(dpkg-query -f '.\\n' -W 2>/dev/null | wc -l)"
            has flatpak && count flatpak "$(flatpak list --app 2>/dev/null | wc -l)"
            echo "packages=\${packages#, }"
        `, "sh", Quickshell.shellDir]

        stdout: StdioCollector {
            onStreamFinished: {
                let facts = {};
                let gpus = [];
                for (let line of this.text.split("\n")) {
                    let index = line.indexOf("=");
                    if (index <= 0)
                        continue;
                    let key = line.slice(0, index);
                    let value = line.slice(index + 1).trim();

                    // lspci names read best as the marketing name in brackets
                    if (key === "gpu")
                        gpus.push(value.match(/\[([^\]]+)\]/)?.[1] ?? value);
                    else
                        facts[key] = value;
                }
                facts.gpu = gpus.join(", ");
                root.facts = facts;
            }
        }
    }
}
