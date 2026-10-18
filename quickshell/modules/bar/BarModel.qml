pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.modules.bar
import qs.modules.bar.widgets

Singleton {
    id: root

    readonly property list<Component> left: resolve(BarLayout.left)
    readonly property list<Component> center: resolve(BarLayout.center)
    readonly property list<Component> right: resolve(BarLayout.right)

    function find(key: string): BarWidget {
        return widgets.find(widget => widget.key === key) ?? null;
    }

    function resolve(keys: var): var {
        return keys.map(key => {
            let widget = find(key);
            if (!widget)
                Alerts.error("bar.json has an unknown item", key);
            return widget?.component;
        }).filter(component => component);
    }

    component BarWidget: QtObject {
        required property string key
        required property string label
        required property string icon
        required property Component component
    }

    property list<BarWidget> widgets: [
        BarWidget {
            key: "workspaces"
            label: "Workspaces"
            icon: Icons.workspaces
            component: Component {
                WorkspacesWidget {}
            }
        },
        BarWidget {
            key: "title"
            label: "Window title"
            icon: Icons.windows
            component: Component {
                TitleWidget {}
            }
        },
        BarWidget {
            key: "clock"
            label: "Clock"
            icon: Icons.clock
            component: Component {
                ClockWidget {}
            }
        },
        BarWidget {
            key: "tray"
            label: "System tray"
            icon: Icons.tray
            component: Component {
                TrayWidget {}
            }
        },
        BarWidget {
            key: "separator"
            label: "Separator"
            icon: Icons.separator
            component: Component {
                SeparatorWidget {}
            }
        },
        BarWidget {
            key: "cpu"
            label: "CPU"
            icon: Icons.cpu
            component: Component {
                CpuWidget {}
            }
        },
        BarWidget {
            key: "memory"
            label: "Memory"
            icon: Icons.memory
            component: Component {
                MemoryWidget {}
            }
        },
        BarWidget {
            key: "disk"
            label: "Disk"
            icon: Icons.disk
            component: Component {
                DiskWidget {}
            }
        },
        BarWidget {
            key: "temperature"
            label: "Temperature"
            icon: Icons.temperature
            component: Component {
                TemperatureWidget {}
            }
        },
        BarWidget {
            key: "battery"
            label: "Battery"
            icon: Icons.batteryFull
            component: Component {
                BatteryWidget {}
            }
        },
        BarWidget {
            key: "network"
            label: "Network"
            icon: Icons.wifi
            component: Component {
                NetworkWidget {}
            }
        },
        BarWidget {
            key: "audio"
            label: "Volume"
            icon: Icons.volumeUp
            component: Component {
                AudioWidget {}
            }
        },
        BarWidget {
            key: "notifications"
            label: "Notifications"
            icon: Icons.notifications
            component: Component {
                NotificationsWidget {}
            }
        },
        BarWidget {
            key: "power"
            label: "Power"
            icon: Icons.power
            component: Component {
                PowerWidget {}
            }
        }
    ]
}
