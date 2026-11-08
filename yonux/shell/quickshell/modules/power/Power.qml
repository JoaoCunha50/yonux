pragma Singleton
import QtQuick
import Quickshell
import qs.theme

Singleton {
    id: root

    readonly property var actions: [
        {
            label: "Lock",
            icon: Icons.lock,
            command: ["loginctl", "lock-session"],
            confirm: false
        },
        {
            label: "Sleep",
            icon: Icons.sleep,
            command: ["systemctl", "suspend"],
            confirm: false
        },
        {
            label: "Logout",
            icon: Icons.logout,
            command: ["sh", "-c", "if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then exec uwsm stop; else exec hyprctl dispatch exit; fi"],
            confirm: true
        },
        {
            label: "Reboot",
            icon: Icons.reboot,
            command: ["systemctl", "reboot"],
            confirm: true
        },
        {
            label: "Shutdown",
            icon: Icons.power,
            command: ["systemctl", "poweroff"],
            confirm: true
        }
    ]

    function run(action: var): void {
        Quickshell.execDetached(action.command);
    }
}
