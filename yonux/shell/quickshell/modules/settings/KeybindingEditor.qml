pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import yonux.components
import yonux.config
import yonux.theme

Controls.Popup {
    id: root

    property var draft: ({})
    property string error: ""
    readonly property bool builtin: Keybindings.defaults.some(entry => entry.id === draft.id)
    readonly property var actionKinds: builtin ? ["default", "app", "command"] : ["app", "command"]

    anchors.centerIn: Controls.Overlay.overlay
    width: Math.min(640, (Controls.Overlay.overlay?.width ?? 720) - Theme.spacing.lg * 2)
    padding: Theme.overlay.padding
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    function edit(entry): void {
        draft = Object.assign({ id: "", title: "", keys: "", kind: "app", appId: "", command: "", terminal: false, enabled: true }, entry ?? {});
        error = "";
        appPicker.resetSearch();
        open();
    }

    function setDraft(key: string, value: var): void {
        draft = Object.assign({}, draft, { [key]: value });
        error = "";
    }

    function record(event): void {
        event.accepted = true;
        if (event.isAutoRepeat || [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_AltGr].includes(event.key)) return;
        if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
            capture.close();
            return;
        }
        let key = "";
        if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z || event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
            key = String.fromCharCode(event.key);
        else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35)
            key = "F" + (event.key - Qt.Key_F1 + 1);
        else {
            const names = {
                [Qt.Key_Space]: "space", [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "KP_Enter",
                [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab", [Qt.Key_Escape]: "Escape",
                [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete", [Qt.Key_Insert]: "Insert",
                [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
                [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
                [Qt.Key_Minus]: "minus", [Qt.Key_Equal]: "equal", [Qt.Key_Comma]: "comma", [Qt.Key_Period]: "period",
                [Qt.Key_Slash]: "slash", [Qt.Key_Backslash]: "backslash", [Qt.Key_Semicolon]: "semicolon",
                [Qt.Key_Apostrophe]: "apostrophe", [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright",
                [Qt.Key_QuoteLeft]: "grave", [Qt.Key_Print]: "Print", [Qt.Key_Pause]: "Pause",
                [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume", [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
                [Qt.Key_VolumeMute]: "XF86AudioMute", [Qt.Key_MediaPlay]: "XF86AudioPlay",
                [Qt.Key_MediaNext]: "XF86AudioNext", [Qt.Key_MediaPrevious]: "XF86AudioPrev"
            };
            key = names[event.key] ?? (event.nativeScanCode > 0 ? "code:" + event.nativeScanCode : "");
        }
        if (!key) return;
        const mods = [];
        if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");
        if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
        if (event.modifiers & Qt.AltModifier) mods.push("ALT");
        if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
        setDraft("keys", mods.concat(key).join(" + "));
        capture.close();
    }

    background: Rectangle {
        color: Theme.colors.surface
        radius: Theme.radius.xl
        border.width: 1
        border.color: Theme.colors.border
    }
    Controls.Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.35) }

    ShortcutInhibitor {
        id: inhibitor
        window: root.parent?.QsWindow.window ?? null
        enabled: capture.visible
        onCancelled: capture.close()
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing.md

        RowLayout {
            Layout.fillWidth: true
            UIText {
                Layout.fillWidth: true
                text: root.draft.id ? "Edit shortcut" : "Add shortcut"
                font.pixelSize: Theme.font.title.medium
                font.weight: Font.DemiBold
            }
            ShellButton { type: ShellButton.Ghost; icon.name: Icons.close; onClicked: root.close() }
        }

        UIText { text: "Name"; muted: true }
        StyledTextField {
            Layout.fillWidth: true
            text: root.draft.title ?? ""
            placeholderText: "For example, Open browser"
            onTextEdited: root.setDraft("title", text)
        }

        UIText { text: "Shortcut"; muted: true }
        RowLayout {
            Layout.fillWidth: true
            StyledTextField {
                Layout.fillWidth: true
                text: root.draft.keys ?? ""
                placeholderText: "SUPER + B"
                onTextEdited: root.setDraft("keys", text)
            }
            ShellButton {
                text: "Record…"
                icon.name: Icons.keyboard
                onClicked: capture.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            UIText { Layout.fillWidth: true; text: "Action"; muted: true }
            StyledSelect {
                model: root.builtin ? ["Default action", "Application", "Command"] : ["Application", "Command"]
                currentIndex: root.actionKinds.indexOf(root.draft.kind)
                onActivated: index => root.setDraft("kind", root.actionKinds[index])
            }
        }

        SearchInput {
            id: appPicker
            Layout.fillWidth: true
            visible: root.draft.kind === "app"
            placeholderText: "Search applications…"
            model: Keybindings.applications
            textRole: "name"
            valueRole: "id"
            currentValue: root.draft.appId ?? ""
            onActivated: (value, app) => {
                root.setDraft("appId", value);
                if (!root.draft.title) root.setDraft("title", "Open " + app.name);
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.draft.kind === "command"
            spacing: Theme.spacing.sm

            Controls.TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: root.draft.command ?? ""
                placeholderText: "For example, playerctl play-pause"
                placeholderTextColor: Theme.colors.placeholder
                color: Theme.colors.fg
                selectionColor: Theme.colors.active
                selectedTextColor: Theme.colors.onActive
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.body.medium
                padding: Theme.spacing.md
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                onTextChanged: if (activeFocus) root.setDraft("command", text)
                background: Rectangle {
                    radius: Theme.radius.sm
                    color: Theme.colors.field
                    border.width: 1
                    border.color: parent.activeFocus ? Theme.colors.active : Theme.colors.border
                }
            }
            RowLayout {
                Layout.fillWidth: true
                UIText { Layout.fillWidth: true; text: "Open in a terminal" }
                StyledSwitch {
                    checked: root.draft.terminal === true
                    onToggled: root.setDraft("terminal", checked)
                }
            }
        }

        UIText {
            Layout.fillWidth: true
            visible: root.error !== ""
            text: root.error
            color: Theme.colors.alert
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.sm
            Item { Layout.fillWidth: true }
            ShellButton { type: ShellButton.Ghost; text: "Cancel"; onClicked: root.close() }
            ShellButton {
                active: true
                text: "Save"
                onClicked: {
                    root.error = Keybindings.save(root.draft);
                    if (!root.error) root.close();
                }
            }
        }
    }

    Controls.Popup {
        id: capture
        anchors.centerIn: Controls.Overlay.overlay
        width: 360
        padding: Theme.spacing.lg
        modal: true
        focus: true
        closePolicy: Controls.Popup.NoAutoClose
        onOpened: captureContent.forceActiveFocus()
        background: Rectangle {
            color: Theme.colors.surface
            radius: Theme.radius.lg
            border.width: 1
            border.color: Theme.colors.active
        }
        contentItem: ColumnLayout {
            id: captureContent
            spacing: Theme.spacing.md
            Keys.onPressed: event => root.record(event)
            ShellIcon { Layout.alignment: Qt.AlignHCenter; icon.name: Icons.keyboard; icon.size: 32 }
            UIText { Layout.alignment: Qt.AlignHCenter; text: "Press your shortcut"; font.weight: Font.DemiBold }
            UIText { Layout.alignment: Qt.AlignHCenter; text: "Escape cancels"; muted: true }
            ShellButton { Layout.alignment: Qt.AlignHCenter; type: ShellButton.Ghost; text: "Cancel"; onClicked: capture.close() }
        }
    }
}
