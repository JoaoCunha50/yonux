pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string current: ""

    function open(name: string): void {
        current = name;
    }

    function close(): void {
        current = "";
    }

    function toggle(name: string): void {
        current = current === name ? "" : name;
    }
}
