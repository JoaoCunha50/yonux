import QtQuick
import Quickshell
import Quickshell.Io
import yonux.services

Scope {
    id: root

    required property string path
    property bool watch: false
    property int saveDelay: 0

    property var document: null
    property bool loaded: false
    property bool invalid: false
    readonly property string name: path.split("/").pop()

    signal documentLoaded

    function save(document: var): void {
        root.document = document;
        if (invalid)
            return;
        if (saveDelay > 0)
            saveTimer.restart();
        else
            write();
    }

    function write(): void {
        if (folder.running) {
            folder.writeWhenReady = true;
            return;
        }
        view.setText(JSON.stringify(document, null, 2) + "\n");
    }

    function receive(document: var, invalid: bool): void {
        root.invalid = invalid;
        if (!invalid)
            root.document = document;
        documentLoaded();
        loaded = true;
    }

    Process {
        id: folder

        property bool writeWhenReady: false

        running: true
        command: ["mkdir", "-p", root.path.slice(0, root.path.lastIndexOf("/"))]
        onExited: if (writeWhenReady) {
            writeWhenReady = false;
            root.write();
        }
    }

    Timer {
        id: saveTimer
        interval: root.saveDelay
        onTriggered: root.write()
    }

    FileView {
        id: view
        path: root.path
        watchChanges: root.watch
        blockLoading: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            let parsed;
            try {
                parsed = JSON.parse(text());
            } catch (e) {
                Alerts.error(`${root.name} is invalid, so it won't be saved until it's fixed`, `${e}`);
                root.receive(null, true);
                return;
            }
            root.receive(parsed, false);
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.receive(null, false);
        }
    }
}
