# macOS AI CLI Dashboard

Native macOS menu-bar dashboard for safely observing installed AI CLI tools and
configured MCP servers.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Project status

The source tree is undergoing a resource-safety stabilization. The checked-in
v2.1.0 archive and Homebrew cask were built before these changes and are **not a
release of the current source**. Do not install or redistribute those legacy
artifacts until the macOS release gates in
[`spec/stabilization.md`](spec/stabilization.md) have passed and a new signed,
notarized artifact is published.

The current implementation deliberately prefers an accurate `Unsupported` or
`Unavailable` state over scraping an interactive terminal and displaying a
false success result.

## Current behavior

- **Safe refresh lifecycle**: automatic polling is disabled on a new install,
  refreshes are single-flight, and hidden/closed windows cancel background work.
- **Bounded processes**: probes use direct executable URLs and argument arrays,
  have a five-second timeout, and retain no more than 64 KiB of output.
- **Low-cost rendering**: the dashboard is opaque, non-floating, single-Space,
  and animation-free by default.
- **Stable SwiftUI identity**: tool, limit, and MCP rows use domain keys rather
  than new UUIDs on every refresh.
- **Conservative MCP inventory**: configuration files are read with Foundation;
  `Configured` never means that a protocol health check succeeded.
- **Bounded logging**: local logs rotate at 1 MiB.

## Data-source capabilities

The dashboard no longer launches `gemini /status`, `codex /status`, or
`claude /usage`. Those are interactive/session commands and are not safe polling
interfaces.

| Tool | Current bounded probe | Usage/quota status |
|---|---|---|
| Gemini CLI | `gemini --version` | Unsupported until a machine-readable adapter exists |
| Codex CLI | `codex login status` | Availability/auth only; App Server adapter planned |
| Claude Code | `claude auth status --text` | Availability/auth only; opt-in status-line adapter planned |

Data-source limitations are part of the product contract. They must not be
hidden by retrying, parsing terminal escape output, or treating any non-empty
stdout as `OK`.

## Settings

- Automatic refresh: off by default.
- Refresh interval: 60–600 seconds; changes apply without restarting the app.
- Tool selection: Gemini, Codex, and Claude probes can be disabled independently.
- Launch at login: opt-in.

The window must be visible for a refresh to start. Hiding, minimizing, or closing
the dashboard pauses scheduling and requests cancellation of the current probe.

## Build and test

Requirements:

- macOS 13 Ventura or newer.
- Swift 5.9 or newer.
- No third-party package dependency.

```bash
git clone https://github.com/trionnemesis/macOS_aicli_check.git
cd macOS_aicli_check/src/AICLIDashboard
swift test
swift build -c release
```

Unit tests use injected process and executable-locator fakes; they do not launch
installed AI CLIs. macOS-only integration tests exercise timeout and output-cap
behavior using system executables.

## Release gates

A release is not complete until all of the following are verified on macOS:

- Hidden for 60 seconds with zero refreshes and zero new child processes.
- Safe mode visible for 30 minutes with no full-display flicker or orphan child.
- Eight-hour visible plus sixteen-hour hidden soak without crash, UI freeze, or
  monotonic memory growth.
- Instruments Time Profiler, Energy Log, and Core Animation comparison against
  the app-quit baseline.
- Strict code-signing and Gatekeeper assessment of the packaged app.

The full executable specification is in
[`spec/features/resource_safe_monitoring.feature`](spec/features/resource_safe_monitoring.feature)
and [`spec/stabilization.md`](spec/stabilization.md).

## Logs

Diagnostic logs are stored at:

```text
~/Library/Application Support/AICLIDashboard/error.log
```

One rotated backup (`error.log.1`) is retained.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright © 2026 warden.

## Related projects

- [MacDesktopWidget](https://github.com/trionnemesis/MacDesktopWidget) — macOS
  desktop system-resource monitor by the same author.
