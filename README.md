# ServerPulse

A macOS menu bar app that monitors a Linux VPS — showing CPU/RAM/disk gauges, Python scraper process list, and n8n workflow status — all via SSH and the n8n REST API.

## Features

- **Colored menu bar dot**: green (online) / yellow (degraded) / red (offline)
- **Live server stats**: CPU, RAM, disk usage with progress bars
- **Python processes**: lists running scrapers with PID, CPU%, and MEM%
- **n8n workflows**: active/inactive status and recent execution history
- **Notifications**: alerts when server goes offline or a Python process stops

## Requirements

- macOS 14 (Sonoma) or later
- SSH key-based access to your server (no password prompts)
- Swift 5.9+ (`xcode-select --install`)

## Quick Start

```bash
# Dev run (no .app bundle needed)
swift run

# Build production .app
chmod +x build.sh && ./build.sh
open build/ServerPulse.app
```

## Configuration

Click the gear icon in the popover to open Settings:

| Field | Default |
|-------|---------|
| SSH Host | `your.server.ip` |
| SSH User | `deploy` |
| SSH Key | `~/.ssh/id_ed25519` |
| SSH Port | `22` |
| n8n Base URL | `http://your.server.ip:5678` |
| n8n API Key | *(empty — get from n8n → Settings → API)* |
| Poll Interval | `30s` |

## Architecture

Zero external dependencies — uses only system SSH binary, `URLSession`, and `UserNotifications`.

```
Sources/ServerPulse/
├── App/          — @main entry, @Observable state hub
├── Models/       — value types (stats, processes, n8n models)
├── Services/     — SSH, ping, n8n HTTP, polling orchestration
├── Settings/     — UserDefaults wrapper + settings UI
├── Notifications/— UNUserNotificationCenter integration
└── Views/        — SwiftUI menu bar popover
```

## License

MIT
