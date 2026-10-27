pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function error(summary: string, body: string): void {
        console.warn(`${summary}: ${body}`);
        Quickshell.execDetached(["notify-send", "-a", "yonux", "-u", "critical", summary, body]);
    }
}
