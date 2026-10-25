pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var outputs: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)
    readonly property var inputs: Pipewire.nodes.values.filter(node => node.audio && !node.isSink && !node.isStream)

    readonly property PwNode defaultOutput: Pipewire.defaultAudioSink
    readonly property PwNode defaultInput: Pipewire.defaultAudioSource

    readonly property real volume: defaultOutput?.audio?.volume ?? 0
    readonly property bool muted: defaultOutput?.audio?.muted ?? true

    function isDefault(node: PwNode): bool {
        let current = node?.isSink ? defaultOutput : defaultInput;
        return !!current && !!node && current.id === node.id;
    }

    function select(node: PwNode): void {
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    function setVolume(node: PwNode, value: real): void {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function changeVolume(delta: real): void {
        setVolume(defaultOutput, volume + delta);
    }

    function toggleMute(node: PwNode): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    PwObjectTracker {
        objects: [root.defaultOutput, root.defaultInput].filter(node => node)
    }
}
