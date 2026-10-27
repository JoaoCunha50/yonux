import QtQuick
import yonux.theme
import yonux.services
import yonux.modules.bar.tray
import yonux.modules.bar.popups

TrayItem {
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    icon.name: Audio.muted ? Icons.volumeOff : Audio.volume < 0.5 ? Icons.volumeDown : Icons.volumeUp
    hoverText: Audio.defaultOutput ? `${Audio.defaultOutput.description || Audio.defaultOutput.name} · ${Math.round(Audio.volume * 100)}%` : "No output"
    popup: Component {
        AudioPopup {}
    }

    WheelHandler {
        onWheel: event => Audio.changeVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            Audio.toggleMute(Audio.defaultOutput);
    }
}
