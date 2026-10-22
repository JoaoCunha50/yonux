.pragma library

function canonical(keys) {
    const parts = String(keys).replace(/\s+/g, "").toUpperCase().replace(/CONTROL/g, "CTRL").replace(/META/g, "SUPER").split("+");
    const key = parts.pop();
    return ["SUPER", "CTRL", "ALT", "SHIFT"].filter(mod => parts.includes(mod)).concat(key).join("+");
}

function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
}

function luaQuote(value) {
    return '"' + String(value).replace(/[\\"\x00-\x1f\x7f]/g, char => {
        if (char === "\\") return "\\\\";
        if (char === '"') return '\\"';
        return "\\" + char.charCodeAt(0).toString().padStart(3, "0");
    }) + '"';
}

function command(entry, applications) {
    if (entry.kind === "default") return "";
    if (entry.kind === "command") {
        const argv = ["sh", "-c", entry.command];
        if (entry.terminal) argv.unshift("xdg-terminal-exec");
        return argv.map(shellQuote).join(" ");
    }
    const app = applications.find(app => app.id === entry.appId);
    if (!app || !app.command.length) return null;
    let argv = app.command.slice();
    if (app.runInTerminal) argv.unshift("xdg-terminal-exec");
    const launch = argv.map(shellQuote).join(" ");
    return app.workingDirectory ? "cd " + shellQuote(app.workingDirectory) + " && " + launch : launch;
}

function render(overrides, custom, applications) {
    const literal = entry => {
        const executable = command(entry, applications);
        return "{ id = " + luaQuote(entry.id) + ", keys = " + luaQuote(entry.keys)
            + ", title = " + luaQuote(entry.title) + ", kind = " + luaQuote(entry.kind)
            + ", enabled = " + (entry.enabled !== false && executable !== null ? "true" : "false")
            + ", command = " + luaQuote(executable ?? "") + " }";
    };
    return "-- Generated from keybindings.json by yonux. Data only.\n"
        + "return { overrides = {\n    " + overrides.map(literal).join(",\n    ")
        + "\n}, custom = {\n    " + custom.map(literal).join(",\n    ") + "\n} }\n";
}

function keysFromBind(bind) {
    const mods = [];
    if (bind.modmask & 64) mods.push("SUPER");
    if (bind.modmask & 4) mods.push("CTRL");
    if (bind.modmask & 8) mods.push("ALT");
    if (bind.modmask & 1) mods.push("SHIFT");
    return mods.concat(bind.keycode ? "code:" + bind.keycode : bind.key).join(" + ");
}
