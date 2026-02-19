# ServerPulse

A macOS menu bar app that monitors a Linux VPS — showing CPU/RAM/disk gauges, Python scraper process list, and n8n workflow status — all via SSH and the n8n REST API.

## Features

- **Colored menu bar dot**: green (online) / yellow (degraded) / red (offline)
- **Live server stats**: CPU, RAM, disk usage with animated gauges
- **Python processes**: lists running scrapers with PID, CPU%, and MEM%
- **n8n workflows**: active/inactive status and recent execution history
- **One-click SSH**: open a Terminal session to your server straight from the menu bar
- **Notifications**: alerts when server goes offline or a Python process stops

## Requirements

- macOS 14 (Sonoma) or later
- SSH key-based access to your server (no password prompts)
- Swift 5.9+ (`xcode-select --install`)

## Setup

```bash
cp .env.example .env   # then fill in your values
swift run
```

### `.env` file

All configuration is loaded from a `.env` file (never committed to git). Copy the example and fill in your values:

```
SSH_HOST=your.server.ip
SSH_USER=root
SSH_KEY_PATH=~/.ssh/id_ed25519
SSH_PORT=22
N8N_BASE_URL=https://your-n8n-instance.com
N8N_API_KEY=your_api_key_here
POLL_INTERVAL=30
```

The app looks for `.env` in:
1. `~/.config/serverpulse/.env`
2. Current working directory

You can also change settings at runtime via the gear icon in the popover.

## Build

```bash
# Dev run
swift run

# Production .app bundle
chmod +x build.sh && ./build.sh
open build/ServerPulse.app
```

## Architecture

Zero external dependencies — uses only system SSH binary, `URLSession`, and `UserNotifications`.

```
Sources/ServerPulse/
├── App/          — @main entry, @Observable state hub
├── Models/       — value types (stats, processes, n8n models)
├── Services/     — SSH, ping, n8n HTTP, .env loader, polling
├── Settings/     — UserDefaults wrapper + settings UI
├── Notifications/— UNUserNotificationCenter integration
└── Views/        — SwiftUI menu bar popover
```

## License

MIT
