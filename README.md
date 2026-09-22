# Flutter Portfolio & State Management

Master compilation app for laboratory activities. Built with Flutter + Provider.

## Getting started

```bash
flutter create . --project-name flutter_portfolio   # only if you need platform folders (android/ios/web)
flutter pub get
flutter run
```

Requires Flutter 3.x (Dart >=3.0). If you generated this folder without
`flutter create`, run that command first inside this directory to add the
platform-specific `android/`, `ios/`, `web/`, etc. folders — this repo only
ships the Dart source (`lib/`) and `pubspec.yaml`.

## Project structure (clean architecture, feature-light layering)

```
lib/
├── main.dart                    # App entry point, Provider + routes + theme
├── models/
│   └── activity_item.dart       # Plain data model (no logic)
├── providers/
│   └── app_state_provider.dart  # GLOBAL state: theme, profile name, progress
├── screens/
│   ├── home_screen.dart         # Dashboard / menu (StatelessWidget, responsive grid)
│   ├── activity_one_screen.dart # StatefulWidget: local counter + favorite toggle
│   ├── activity_two_screen.dart # StatefulWidget: form input example
│   └── settings_screen.dart     # Edits global theme + profile name
└── widgets/
    ├── activity_card.dart       # StatelessWidget: reusable card
    ├── custom_button.dart       # StatelessWidget: reusable button
    └── counter_widget.dart      # StatefulWidget: reusable local counter
```

### Why this split

- **`models/`** — dumb data holders, no Flutter widget code.
- **`providers/`** — the single source of truth for state that more than
  one screen cares about (dark/light theme, profile display name, activity
  completion count). Screens call `context.watch<AppStateProvider>()` to
  rebuild automatically when it changes, and `context.read<...>()` to fire
  one-off actions like `toggleTheme()`.
- **`screens/`** — one file per route/page. Each screen is only
  `StatefulWidget` when it has to be (local text fields, counters, toggles
  that nobody else needs to know about).
- **`widgets/`** — small, reusable, presentation-only pieces shared across
  screens (`StatelessWidget`), separated from screen-local interactive
  pieces (`StatefulWidget`, e.g. `CounterWidget`).

## Requirements checklist

- **Multi-screen navigation** — `MaterialApp.routes` in `main.dart` wires
  up `/home`, `/activity-one`, `/activity-two`, `/settings`; the Home
  Dashboard's grid cards navigate via `Navigator.pushNamed`.
- **Widget architecture** — `ActivityCard` / `CustomButton` are
  `StatelessWidget`; `ActivityOneScreen`, `ActivityTwoScreen`,
  `SettingsScreen`, and `CounterWidget` are `StatefulWidget` for their
  screen-local interactions.
- **Responsive layout** — `HomeScreen` uses `LayoutBuilder` to change the
  `GridView` column count by available width (2 / 3 / 4 columns); other
  screens use `Row` + `Expanded`/`Flexible` so nothing overflows on small
  screens.
- **Global state management** — `AppStateProvider` (via `provider` package)
  holds `themeMode` and `profileName`. Toggling dark mode or saving a new
  name on the Settings screen calls `notifyListeners()`, which instantly
  rebuilds the Home Dashboard's greeting and the app's `MaterialApp` theme
  everywhere, with no manual plumbing.

## Activity: Network Monitor (Wi-Fi ↔ Cellular handover)

Adds a **Network Monitor** screen demonstrating real-time connectivity
tracking and graceful handling of a dropped/handed-over connection.

```
lib/
├── models/
│   └── queued_request.dart        # RequestStatus enum + QueuedRequest model
├── services/
│   ├── connectivity_service.dart  # wraps connectivity_plus -> Stream<NetworkStatus>
│   └── network_request_service.dart # simulates a chunked "large dataset" fetch
├── providers/
│   └── network_monitor_provider.dart # stream listener + queue + retry logic
├── screens/
│   └── network_monitor_screen.dart   # live status badge + request list
└── widgets/
    ├── network_status_badge.dart     # StatelessWidget: Wi-Fi/Cellular/Offline pill
    └── queued_request_tile.dart      # StatelessWidget: one row in the queue
```

**How it satisfies each requirement:**
- **Network Stream Listener** — `ConnectivityService.onStatusChanged` wraps
  `Connectivity().onConnectivityChanged` from `connectivity_plus` and maps it
  to a simple `NetworkStatus` enum (`wifi`, `cellular`, `offline`, `other`).
  `NetworkMonitorProvider` subscribes to this stream once in its constructor.
- **Real-time UI** — `NetworkMonitorScreen` calls
  `context.watch<NetworkMonitorProvider>()`, so `NetworkStatusBadge` re-renders
  immediately whenever the stream emits a new status — no polling, no manual
  refresh.
- **Request Queuing System** — `NetworkRequestService.simulateFetch()` mimics a
  long-running download in 5 chunks, checking connectivity before starting
  and between every chunk. If the connection is gone, it throws a
  `NetworkDroppedException` instead of letting a real socket error propagate.
  `NetworkMonitorProvider._runRequest()` catches that exception and marks the
  request `RequestStatus.queued` instead of crashing or discarding it.
- **Graceful Recovery** — `NetworkMonitorProvider._onStatusChanged()` detects
  the transition from offline → online (Wi-Fi *or* Cellular) and calls
  `_retryQueuedRequests()`, which re-runs every queued request automatically.
  A manual "Retry now" button on each queued tile is also available.

**Testing the handover on your machine:**
- **Android emulator**: Extended Controls → Cellular, or toggle Wi-Fi off in
  the emulator's quick settings while a request is in progress.
- **Physical device**: turn Wi-Fi off mid-fetch to force a fallback to
  Cellular (or vice versa), or toggle airplane mode on/off to simulate a full
  drop and recovery.
- **Chrome/web**: the browser doesn't expose real adapter switching, so use
  DevTools → Network → "Offline" throttling to simulate the drop instead.

## Activity: Network Diagnostic Dashboard

Adds a **Network Diagnostic Dashboard** screen that runs a multi-step
speed/latency test and adapts the UI (high-res vs. lightweight content)
based on the result, broadcasting the categorized health status app-wide.

```
lib/
├── models/
│   └── network_diagnostic_result.dart  # NetworkHealthTier, DiagnosticStep, result model
├── services/
│   └── network_diagnostic_service.dart # the diagnostic tool itself: idle ping ->
│                                        #   download (+ concurrent ping) -> upload (+ concurrent ping)
│                                        #   + threshold classification logic
├── providers/
│   └── network_diagnostic_provider.dart # runs the tool on a timer + on demand,
│                                         #   injects the categorized tier into global state
├── screens/
│   └── network_diagnostic_screen.dart   # stepper, results, adaptive preview
└── widgets/
    ├── network_health_badge.dart          # StatelessWidget: Excellent/Fair/Poor/Degraded pill
    ├── diagnostic_progress_stepper.dart    # StatelessWidget: idle ping -> download -> upload progress
    └── adaptive_media_placeholder.dart     # StatelessWidget: swaps high-res card <-> lightweight card
```

**How it satisfies each requirement:**
- **Diagnostic tool implementation** — `NetworkDiagnosticService` runs the
  exact required sequence: `measureIdlePing()` first (baseline, nothing else
  running), then `measureDownload()` (throughput + ping measured together),
  then `measureUpload()` (throughput + ping measured together). It's a pure
  Dart class with no Flutter imports, so it's trivial to swap the simulated
  delays for a real HTTP-based speed test later.
- **Threshold logic** — `NetworkDiagnosticService.classify()` buckets the
  result into `NetworkHealthTier.excellent` (>10 Mbps), `fair` (2–10 Mbps),
  `poor` (<2 Mbps), or `degraded` (offline or extreme idle latency, which
  overrides the bandwidth-based tiers).
- **Global state injection** — `NetworkDiagnosticProvider` (a
  `ChangeNotifier`, registered once in `main.dart`'s `MultiProvider`) re-runs
  the tool automatically every 20s and exposes `currentTier`. Both the
  diagnostics screen *and* the Home dashboard's app bar read this same
  provider via `context.watch`, proving the status broadcasts app-wide
  rather than being local to one screen.
- **Real-time adaptive UI** — `AdaptiveMediaPlaceholder` watches the current
  tier and swaps between a mock high-resolution content card (Excellent/Fair)
  and a lightweight placeholder card (Poor/Degraded) with an `AnimatedSwitcher`.

**Recording tip:** since real speed varies unpredictably, the simulated
service randomizes bandwidth/ping each run so you'll naturally see different
tiers across runs — tap "Run diagnostic now" a few times to capture the
stepper walking through Idle ping → Download → Upload, and the adaptive
card and health badge changing as the tier changes.

## Recording your demo

For the deliverable, record a short screen capture that:
1. Resizes/rotates the app (or runs it on two window sizes) to show the
   grid reflowing without overflow.
2. Opens **Settings**, toggles dark mode, and shows the Home Dashboard
   updating immediately.
3. Changes the profile name and shows the greeting on Home updating.
