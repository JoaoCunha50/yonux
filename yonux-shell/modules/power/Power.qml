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
            command: ["uwsm", "stop"],
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
