pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "CpuTemperature.js" as CpuTemperature

Singleton {
    id: root

    property int cpuPercent: 0
    property string loadAverage: ""
    property int memoryPercent: 0
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property int diskPercent: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    property int temperature: -1

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : -1
    readonly property int batteryState: battery?.state ?? UPowerDeviceState.Unknown

    property var _lastCpuTimes: null

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload();
            loadFile.reload();
            memoryFile.reload();
            diskProcess.running = true;
            temperatureProcess.running = true;
        }
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"

        onLoaded: {
            let firstLine = text().split("\n")[0];
            if (!firstLine.startsWith("cpu "))
                return;

            let parts = firstLine.trim().split(/\s+/).slice(1).map(Number);
            if (parts.length < 5)
                return;

            let idleTime = parts[3] + (parts[4] || 0); // idle + iowait
            let totalTime = parts.reduce((acc, val) => acc + val, 0);

            if (root._lastCpuTimes) {
                let idleDelta = idleTime - root._lastCpuTimes.idle;
                let totalDelta = totalTime - root._lastCpuTimes.total;
                if (totalDelta > 0)
                    root.cpuPercent = Math.max(0, Math.min(100, Math.round(100 * (1 - idleDelta / totalDelta))));
            }

            root._lastCpuTimes = {
                idle: idleTime,
                total: totalTime
            };
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"

        onLoaded: root.loadAverage = text().trim().split(/\s+/).slice(0, 3).join(" ")
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"

        onLoaded: {
            let content = text();
            let totalMatch = content.match(/^MemTotal:\s+(\d+)\s+kB/m);
            let availMatch = content.match(/^MemAvailable:\s+(\d+)\s+kB/m);
            if (!totalMatch || !availMatch)
                return;

            let total = parseInt(totalMatch[1], 10);
            let used = total - parseInt(availMatch[1], 10);
            if (total <= 0)
                return;

            root.memoryPercent = Math.max(0, Math.min(100, Math.round(used / total * 100)));
            root.memoryUsedGiB = used / 1048576;
            root.memoryTotalGiB = total / 1048576;
        }
    }

    Process {
        id: diskProcess
        command: ["df", "-B1", "--output=size,used,pcent", "/"]

        stdout: StdioCollector {
            onStreamFinished: {
                let fields = (text.split("\n")[1] ?? "").trim().split(/\s+/);
                let pct = parseInt(fields[2]);
                if (isNaN(pct))
                    return;

                root.diskPercent = pct;
                root.diskTotalGiB = Number(fields[0]) / 1073741824;
                root.diskUsedGiB = Number(fields[1]) / 1073741824;
            }
        }
    }

    Process {
        id: temperatureProcess
        command: ["sensors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.temperature = CpuTemperature.parse(text)
        }

        onExited: code => {
            if (code !== 0)
                root.temperature = -1;
        }
    }
}
