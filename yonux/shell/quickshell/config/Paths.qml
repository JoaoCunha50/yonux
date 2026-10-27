pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`

    readonly property string config: `${configHome}/yonux`
    readonly property string state: `${stateHome}/yonux`
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string hypr: `${configHome}/hypr`
}
