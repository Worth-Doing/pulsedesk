<p align="center">
  <img src="Assets/PulseDesk-Logo.svg" width="280" alt="PulseDesk Logo"/>
</p>

<h1 align="center">PulseDesk</h1>

<p align="center">
  <strong>Feel Your Machine. Control It Instantly.</strong>
</p>

<p align="center">
  <a href="https://github.com/Worth-Doing/pulsedesk/releases/latest"><img src="https://img.shields.io/github/v/release/Worth-Doing/pulsedesk?style=flat-square&color=4080ff&label=Version" alt="Version"/></a>
  <img src="https://img.shields.io/badge/Platform-macOS%2014+-000000?style=flat-square&logo=apple&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/Swift-6.3-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift"/>
  <img src="https://img.shields.io/badge/SwiftUI-Native-007AFF?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon-333333?style=flat-square&logo=apple&logoColor=white" alt="Apple Silicon"/>
  <img src="https://img.shields.io/badge/Xcode-Not%20Required-22863a?style=flat-square" alt="No Xcode"/>
  <img src="https://img.shields.io/badge/Notarized-Apple-000000?style=flat-square&logo=apple&logoColor=white" alt="Notarized"/>
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License"/>
</p>

<p align="center">
  <a href="https://github.com/Worth-Doing/pulsedesk/releases/latest/download/PulseDesk-2.0.0.dmg">
    <img src="https://img.shields.io/badge/Download-PulseDesk%202.0.0%20DMG-4080ff?style=for-the-badge&logo=apple&logoColor=white" alt="Download DMG"/>
  </a>
</p>

---

## What is PulseDesk?

PulseDesk is a **next-generation macOS system monitoring and control application** built entirely in **Swift + SwiftUI**. It replaces the outdated Activity Monitor with a modern, visual-first, real-time system dashboard.

This is not a passive monitoring tool. PulseDesk is an **active system control layer** that lets you understand, monitor, and optimize your Mac in real-time.

<p align="center">
  <img src="https://img.shields.io/badge/Real--Time-Monitoring-4080ff?style=flat-square" alt="Real-Time"/>
  <img src="https://img.shields.io/badge/Process-Control-9060ff?style=flat-square" alt="Process Control"/>
  <img src="https://img.shields.io/badge/One--Click-Boost-22c55e?style=flat-square" alt="Boost"/>
  <img src="https://img.shields.io/badge/Desktop-Widgets-ff9020?style=flat-square" alt="Widgets"/>
  <img src="https://img.shields.io/badge/Storage-Analysis-9060ff?style=flat-square" alt="Storage"/>
  <img src="https://img.shields.io/badge/Smart-Suggestions-ff9020?style=flat-square" alt="Smart"/>
</p>

---

## What's New in v2.0.0

PulseDesk 2.0 is a **major upgrade** — the codebase has doubled from 23 to 38 files and 3,400 to 6,700 lines of Swift.

### Multi-Page Navigation

11 dedicated pages organized in a sectioned sidebar:

| Section | Pages |
|---------|-------|
| **Overview** | Home dashboard |
| **Hardware** | CPU, Memory, Storage, Network, GPU, Thermal |
| **Tools** | Processes, Booster, Desktop Widgets |
| **System** | Settings |

Every hardware metric now has its own **full-detail page** with large time series charts, stats, and deep breakdowns.

### Desktop Floating Widgets

Pin **real-time metric widgets** directly to your macOS desktop:

- 6 widget types: CPU Gauge, Memory Gauge, Network Speed, Disk Usage, GPU Gauge, System Health
- Always-on-top, glassmorphic design with dark translucent background
- Drag to reposition — positions saved between sessions
- Appear on all desktop spaces
- Close on hover (X button) or from the management page
- Persist across app restarts

### Storage Analysis

Full disk analysis engine that scans:

- **Applications** sorted by size (all /Applications)
- **Home directories** (Desktop, Documents, Downloads, etc.) with item counts
- **Large files** (>50 MB) with file type icons
- Disk I/O time series with read/write speeds

### Enhanced Time Series Charts

New `TimeSeriesChart` component with:

- Multi-series support (e.g., User + System + Total CPU on one chart)
- Color-coded legend with live values
- Y-axis labels
- Time axis labels
- Smooth bezier curves with gradient fill

### Configurable Refresh Interval

From the Settings page, control:

- **Refresh interval**: 0.5s to 10s (slider + preset buttons)
- **History duration**: 60 to 600 data points
- Changes apply live to all engines

---

## Features

### Home Dashboard — System Overview

The Home page shows **all key metrics at a glance** in a grid of clickable cards. Each card displays the current value, a mini sparkline chart, and key sub-metrics. Click any card to navigate to the full detail page.

### Hardware Detail Pages

Each hardware component has a dedicated detail page:

| Page | Highlights |
|------|-----------|
| **CPU** | User/System/Total time series, per-core heatmap with labels, load average bars, processor info |
| **Memory** | Usage time series, composition breakdown (Active/Wired/Compressed/Inactive/Free) with visual bars, pressure gauge, swap monitoring |
| **Storage** | Disk I/O time series, app sizes, directory analysis, large file finder |
| **Network** | Dual-line download/upload time series, throughput bars, transfer totals, peak/average stats |
| **GPU** | Utilization time series, VRAM ring gauge, min/avg/max distribution |
| **Thermal** | State timeline visualization, state distribution stats, temperature gauge, recommendations |

### Process Intelligence

<p>
  <img src="https://img.shields.io/badge/Score-System-ff9020?style=flat-square" alt="Score"/>
  <img src="https://img.shields.io/badge/Runaway-Detection-ff4050?style=flat-square" alt="Runaway"/>
  <img src="https://img.shields.io/badge/Category-Filtering-9060ff?style=flat-square" alt="Filter"/>
</p>

- **Intelligent scoring** — Each process scored by weighted CPU (50%), Memory (30%), and Energy (20%)
- **Runaway detection** — Processes using >80% CPU are flagged instantly
- **Search & filter** — Case-insensitive search, filter by User/System, sort by CPU/Memory/Score/Name
- **Real CPU measurement** — Delta-time based calculation, not approximation
- **System process detection** — UID-based, not PID heuristics

### Process Actions

Right-click any process for full control:

| Action | Signal |
|--------|--------|
| Terminate | `SIGTERM` |
| Force Kill | `SIGKILL` |
| Suspend | `SIGSTOP` |
| Resume | `SIGCONT` |
| Lower Priority | `nice +10` |
| Raise Priority | `nice -5` |
| Kill Process Tree | Recursive `SIGTERM` |
| Copy PID / Name | Clipboard |

All actions provide **toast notifications** with success/failure feedback.

### System Booster

<p>
  <img src="https://img.shields.io/badge/Light-Boost-4080ff?style=flat-square" alt="Light"/>
  <img src="https://img.shields.io/badge/Aggressive-Boost-ff4050?style=flat-square" alt="Aggressive"/>
  <img src="https://img.shields.io/badge/Custom-Profile-9060ff?style=flat-square" alt="Custom"/>
</p>

One-click performance optimization with three profiles:

| Profile | CPU Threshold | Memory Threshold | Behavior |
|---------|---------------|------------------|----------|
| **Light** | 5% | 200 MB | Kill idle background processes |
| **Aggressive** | 1% | 50 MB | Aggressively free all non-essential |
| **Custom** | 3% | 100 MB | Balanced optimization |

Protected processes (Finder, Dock, WindowServer, loginwindow, etc.) are never terminated.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + 1` | Home |
| `Cmd + 2` | CPU |
| `Cmd + 3` | Memory |
| `Cmd + 4` | Storage |
| `Cmd + 5` | Network |
| `Cmd + 6` | GPU |
| `Cmd + 7` | Thermal |
| `Cmd + 8` | Processes |
| `Cmd + 9` | Booster |
| `Cmd + 0` | Widgets |
| `Cmd + R` | Refresh process list |

---

## Design

### Glassmorphism UI

PulseDesk uses a modern **glass morphism** design language:

- Ultra-thin material backdrops
- Depth-layered panels with subtle borders
- Spring-based animations throughout
- Hover micro-interactions on every panel
- Dynamic color coding based on usage levels
- Dark translucent widgets for desktop overlay

### Color System

| Color | Hex | Usage |
|-------|-----|-------|
| Blue | `#4080FF` | Primary accent, CPU |
| Purple | `#9452FF` | Memory |
| Green | `#38D17A` | GPU, healthy state |
| Cyan | `#38C7EB` | Network download |
| Orange | `#FF9433` | Upload, warnings, heavy load |
| Red | `#FF4752` | Critical, runaway, force kill |
| Yellow | `#FFD138` | Disk, elevated state |

---

## Architecture

```
PulseDesk/
├── App/
│   └── PulseDeskApp.swift                 # Entry point, environment injection, menu commands
├── Models/
│   ├── SystemMetrics.swift                # CPU, Memory, Disk, Network, GPU, Thermal models
│   ├── ProcessInfo.swift                  # Process model, scoring, categories
│   ├── BoosterMode.swift                  # Boost levels & results
│   ├── AppSettings.swift                  # User settings with persistence
│   ├── StorageInfo.swift                  # App/file/directory storage models
│   └── WidgetConfig.swift                 # Desktop widget types & configuration
├── Engine/
│   ├── MetricsEngine.swift                # Real-time system metrics (Mach/IOKit)
│   ├── ProcessEngine.swift                # Process listing, scoring, delta-time CPU
│   ├── ActionEngine.swift                 # Kill/suspend/priority + smart suggestions
│   ├── ThermalEngine.swift                # Thermal state monitoring
│   ├── NotificationEngine.swift           # Toast notification system
│   ├── StorageEngine.swift                # Disk analysis (apps, files, directories)
│   └── WidgetEngine.swift                 # Floating desktop widget management (AppKit)
├── Views/
│   ├── ContentView.swift                  # Main layout, sectioned sidebar, navigation
│   ├── Home/
│   │   └── HomeView.swift                 # Overview dashboard with metric cards
│   ├── CPU/
│   │   └── CPUDetailView.swift            # Full CPU detail page
│   ├── Memory/
│   │   └── MemoryDetailView.swift         # Full memory detail page
│   ├── Storage/
│   │   └── StorageDetailView.swift        # Disk I/O + storage analysis page
│   ├── Network/
│   │   └── NetworkDetailView.swift        # Full network detail page
│   ├── GPU/
│   │   └── GPUDetailView.swift            # Full GPU detail page
│   ├── Thermal/
│   │   └── ThermalDetailView.swift        # Full thermal detail page
│   ├── Settings/
│   │   └── SettingsView.swift             # Refresh interval, history, about
│   ├── Widgets/
│   │   ├── WidgetsManagerView.swift       # Widget management page
│   │   └── FloatingWidgetView.swift       # Floating widget views (6 types)
│   ├── Dashboard/
│   │   ├── DashboardView.swift            # Legacy dashboard grid
│   │   ├── CPUPanel.swift, MemoryPanel.swift, NetworkPanel.swift
│   │   ├── DiskPanel.swift, GPUPanel.swift
│   ├── Process/
│   │   ├── ProcessListView.swift          # Searchable list + context menus
│   │   └── ProcessCardView.swift          # Process cards + hover actions
│   ├── Booster/
│   │   └── BoosterView.swift              # Optimization profiles + activation
│   └── Components/
│       ├── LiveGraph.swift                # Bezier curve real-time graphs
│       ├── TimeSeriesChart.swift          # Enhanced chart with legend/axes
│       └── GlassCard.swift                # Design system components + toasts
└── Utils/
    └── Extensions.swift                   # Colors, animations, formatters
```

### System APIs Used

| API | Purpose |
|-----|---------|
| `host_statistics` | Overall CPU usage |
| `host_processor_info` | Real per-core CPU |
| `vm_statistics64` | Memory breakdown |
| `proc_listallpids` / `proc_pidinfo` | Process enumeration |
| `IOKit` (`IOBlockStorageDriver`) | Disk I/O metrics |
| `IOKit` (`AGXAccelerator`) | GPU utilization + VRAM |
| `ifaddrs` | Network interface stats |
| `ProcessInfo.thermalState` | Thermal monitoring |
| `sysctl` (`KERN_BOOTTIME`) | System uptime |
| `FileManager` / `URL` resource values | Storage analysis |
| `NSPanel` / `NSHostingView` | Floating desktop widgets |

---

## Requirements

<p>
  <img src="https://img.shields.io/badge/macOS-14.0%20Sonoma+-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/Chip-Apple%20Silicon-333333?style=flat-square&logo=apple&logoColor=white" alt="Apple Silicon"/>
  <img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+"/>
</p>

- **macOS 14.0** (Sonoma) or later
- **Apple Silicon** (M1/M2/M3/M4) recommended (Intel compatible but GPU metrics limited)
- No Xcode required — builds with Swift CLI toolchain

---

## Installation

### Download (Recommended)

<a href="https://github.com/Worth-Doing/pulsedesk/releases/latest/download/PulseDesk-2.0.0.dmg">
  <img src="https://img.shields.io/badge/Download-PulseDesk%202.0.0%20DMG-4080ff?style=for-the-badge&logo=apple&logoColor=white" alt="Download DMG"/>
</a>

1. Download the `.dmg` file
2. Open the DMG
3. Drag **PulseDesk** to **Applications**
4. Launch from Applications

> The app is **signed and notarized** by Apple — no Gatekeeper warnings.

### Build from Source

```bash
# Clone
git clone https://github.com/Worth-Doing/pulsedesk.git
cd pulsedesk

# Build (debug)
swift build

# Run
.build/debug/PulseDesk

# Build (release)
swift build -c release
.build/release/PulseDesk
```

---

## Performance

PulseDesk is designed to be lightweight:

| Metric | v1.0 | v2.0 |
|--------|------|------|
| CPU Usage | < 3% | < 3% |
| Memory | < 40 MB | < 50 MB |
| Binary Size | ~1.5 MB | ~3.1 MB |
| DMG Size | ~2.3 MB | ~2.8 MB |
| Source Files | 23 | 38 |
| Lines of Code | ~3,400 | ~6,700 |
| Launch Time | < 0.5s | < 0.5s |

---

## Tech Stack

<p>
  <img src="https://img.shields.io/badge/Language-Swift-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift"/>
  <img src="https://img.shields.io/badge/UI-SwiftUI-007AFF?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Framework-IOKit-333333?style=flat-square&logo=apple&logoColor=white" alt="IOKit"/>
  <img src="https://img.shields.io/badge/Framework-AppKit-333333?style=flat-square&logo=apple&logoColor=white" alt="AppKit"/>
  <img src="https://img.shields.io/badge/Framework-Combine-333333?style=flat-square&logo=apple&logoColor=white" alt="Combine"/>
  <img src="https://img.shields.io/badge/Build-Swift%20Package%20Manager-F05138?style=flat-square&logo=swift&logoColor=white" alt="SPM"/>
  <img src="https://img.shields.io/badge/Xcode-Not%20Required-22863a?style=flat-square" alt="No Xcode"/>
</p>

- **Swift + SwiftUI** — native macOS UI
- **AppKit** — floating desktop widget windows (`NSPanel`)
- **IOKit** — hardware metrics (disk I/O, GPU, thermal)
- **Combine** — reactive data binding
- **No Xcode dependency** — builds via `swift build`
- **No Electron** — pure native macOS
- **No third-party dependencies** — zero external packages

---

## Roadmap

- [x] ~~Settings/preferences panel~~ (v2.0)
- [x] ~~Multi-page navigation~~ (v2.0)
- [x] ~~Desktop floating widgets~~ (v2.0)
- [x] ~~Storage analysis~~ (v2.0)
- [x] ~~Configurable refresh interval~~ (v2.0)
- [x] ~~Enhanced time series charts~~ (v2.0)
- [ ] Menu bar extra (compact menu bar widget)
- [ ] Metric export (CSV/JSON)
- [ ] Custom boost profiles
- [ ] Plugin system
- [ ] Multi-device monitoring
- [ ] CLI tool (`pulsedesk stats`, `pulsedesk boost`)

---

## Contributing

Contributions are welcome. Please open an issue first to discuss what you'd like to change.

```bash
# Fork the repo
# Create your feature branch
git checkout -b feature/amazing-feature

# Commit your changes
git commit -m "Add amazing feature"

# Push to the branch
git push origin feature/amazing-feature

# Open a Pull Request
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>PulseDesk v2.0</strong> — What Activity Monitor should have been if it was designed in 2026.
</p>

<p align="center">
  <sub>Built with Swift + SwiftUI. No Xcode required. Signed & Notarized by Apple.</sub>
</p>
