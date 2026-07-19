# AICLIDashboard Stabilization Specification

Status: Accepted for implementation

Date: 2026-07-19

## Goal

Preserve the useful menu-bar dashboard while removing unbounded polling,
interactive CLI screen scraping, avoidable WindowServer composition, and false
MCP connection claims.

## Non-goals

- Emulating a TTY to scrape slash-command output.
- Promising account-wide quota data when a vendor provides only interactive or
  session-scoped statistics.
- Adding a production dependency, remote telemetry, or credential storage.
- Rewriting the application in AppKit.

## Data-source contract

Every adapter declares its capability and freshness. A value may be presented
as usage data only when it came from a bounded, machine-readable source.

| Tool | Accepted source | Safe fallback |
|---|---|---|
| Codex | Codex App Server rate-limit API | Authentication/availability only |
| Claude Code | Opt-in status-line rate-limit event | Availability only |
| Gemini CLI | A future bounded machine-readable quota adapter | Availability only |

`Unsupported`, `Unavailable`, `Timed Out`, and stale data are first-class UI
states. They must never be converted to `OK` merely because stdout is non-empty.

## Runtime invariants

1. There is at most one scheduler for the dashboard.
2. CLI and MCP refresh domains each have at most one in-flight operation.
3. Hiding or closing the dashboard stops scheduling and requests cancellation.
4. Every child process has a five-second deadline and a 64 KiB output cap.
5. A timeout or cancellation terminates the launched process.
6. Automatic polling is disabled for a new installation.
7. Changing an interval restarts the scheduler without restarting the app.
8. MCP config reads use Foundation APIs and never run `cat`, `lsof`, or `grep`.
9. Stable domain keys identify all rows; unchanged data is not republished.
10. Safe rendering is opaque, non-floating, single-Space, and animation-free by
    default. Optional visual effects must remain user-controlled.

## Verification gates

### Deterministic checks

- Process-runner tests cover success, non-zero exit, timeout, cancellation, and
  output truncation with injected fakes.
- Scheduler tests prove maximum concurrency of one, coalescing, cancellation,
  visibility pause, and live interval changes.
- Parser/adapter tests use recorded fixtures and never invoke an installed AI
  CLI during the unit-test suite.
- MCP tests use temporary fixture files and distinguish `Configured` from a
  protocol-level `Connected` result.

### macOS release checks

- Hidden for 60 seconds: zero refresh signposts and zero new child processes.
- Safe mode visible for 30 minutes: zero full-display flicker and no orphaned
  child process.
- Eight-hour visible plus sixteen-hour hidden soak: no crash, UI freeze, or
  monotonic RSS growth.
- Instruments Time Profiler, Energy Log, and Core Animation results are compared
  with the app-quit baseline on the target Mac.
- Release artifact passes strict code-signing and Gatekeeper assessment and does
  not require clearing quarantine attributes.

macOS-only checks are release gates. A commit produced on a non-macOS host must
report them as unverified rather than treating static inspection as a pass.
