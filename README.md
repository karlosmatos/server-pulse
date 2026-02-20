# ServerPulse

A macOS menu bar app that monitors **multiple Linux servers** — showing CPU/RAM/disk gauges, process list, Docker containers, systemd services, and n8n workflow status — all via SSH and the n8n REST API.

## Features

- **Multi-server support**: monitor as many servers as you like; switch between them with a pill picker
- **Colored menu bar dot**: reflects the worst status across all servers — green (all online) / yellow (degraded) / red (offline)
- **Live server stats**: CPU, RAM, disk usage with animated gauges
- **Process monitoring**: top processes by CPU, or filter by name, with PID, CPU%, MEM%
- **Docker containers**: status and resource usage for all running containers
- **Systemd services**: active/inactive/failed state for named services
- **n8n workflows**: active/inactive status and recent execution history
- **One-click SSH**: open a terminal session to the selected server straight from the menu bar
- **Notifications**: per-server alerts when a server goes offline or a monitored process stops

## Requirements

- macOS 14 (Sonoma) or later
- SSH key-based access to each server (no password prompts)
- Swift 5.9+ (`xcode-select --install`)

## Setup

```bash
cp .env.example .env   # fill in your values, then:
swift run
```

### `.env` file

Configuration is loaded from a `.env` file on first launch and imported as the first server. Copy the example and fill in your values:

```
SSH_HOST=your.server.ip
SSH_USER=root
SSH_KEY_PATH=~/.ssh/id_ed25519
SSH_PORT=22
N8N_BASE_URL=https://your-n8n-instance.com
N8N_API_KEY=your_api_key_here
POLL_INTERVAL=30
PROCESS_COUNT=10
DOCKER_ENABLED=true
SYSTEMD_SERVICES=nginx,postgresql
```

The app looks for `.env` in:
1. `~/.config/serverpulse/.env`
2. Current working directory

After first launch, all configuration is managed via the gear icon → Settings. Additional servers can be added there too.

> **Migrating from a previous version?** Existing single-server settings are auto-imported on first launch — no manual steps needed.

## Build

```bash
# Dev run
swift run

# Production .app bundle (installs codesigned app to build/)
chmod +x build.sh && ./build.sh
open build/ServerPulse.app
```

## Architecture

Zero external dependencies — uses only the system SSH binary, `URLSession`, and `UserNotifications`.

```
Sources/ServerPulse/
├── App/          — @main entry, @Observable multi-server state hub
├── Models/       — ServerConfig, ServerState, stats, processes, n8n models
├── Services/     — SSH, ping, n8n HTTP, .env loader, per-server polling
├── Settings/     — AppSettings (servers list), SettingsView, ServerEditView
├── Notifications/— per-server UNUserNotificationCenter integration
└── Views/        — SwiftUI menu bar popover with server picker
```

### Multi-server design (projection pattern)

Views read the same flat `AppEnvironment` properties (`serverStatus`, `stats`, `processes`, …). Internally, `AppEnvironment` maintains a dictionary of per-server state and **projects** the selected server's data into those flat properties whenever the selection changes or a poll completes. Only the state-management layer needed to change — 16 of 27 view/model files are untouched.

## License

MIT
