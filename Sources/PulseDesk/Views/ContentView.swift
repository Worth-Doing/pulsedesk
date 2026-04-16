import SwiftUI

// MARK: - Sidebar Tabs

enum SidebarSection: String {
    case overview = "OVERVIEW"
    case hardware = "HARDWARE"
    case tools = "TOOLS"
}

enum SidebarTab: String, CaseIterable {
    case home = "Home"
    case cpu = "CPU"
    case memory = "Memory"
    case storage = "Storage"
    case network = "Network"
    case gpu = "GPU"
    case thermal = "Thermal"
    case processes = "Processes"
    case booster = "Booster"
    case widgets = "Widgets"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .storage: return "internaldrive"
        case .network: return "network"
        case .gpu: return "gpu"
        case .thermal: return "thermometer.medium"
        case .processes: return "list.bullet.rectangle"
        case .booster: return "bolt.circle"
        case .widgets: return "widget.small"
        case .settings: return "gearshape"
        }
    }

    var shortcut: String {
        switch self {
        case .home: return "1"
        case .cpu: return "2"
        case .memory: return "3"
        case .storage: return "4"
        case .network: return "5"
        case .gpu: return "6"
        case .thermal: return "7"
        case .processes: return "8"
        case .booster: return "9"
        case .widgets: return "0"
        case .settings: return ","
        }
    }

    var section: SidebarSection {
        switch self {
        case .home: return .overview
        case .cpu, .memory, .storage, .network, .gpu, .thermal: return .hardware
        case .processes, .booster, .widgets: return .tools
        case .settings: return .tools
        }
    }

    static var grouped: [(SidebarSection, [SidebarTab])] {
        [
            (.overview, [.home]),
            (.hardware, [.cpu, .memory, .storage, .network, .gpu, .thermal]),
            (.tools, [.processes, .booster, .widgets])
        ]
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab: SidebarTab = .home
    @EnvironmentObject var metricsEngine: MetricsEngine
    @EnvironmentObject var processEngine: ProcessEngine
    @EnvironmentObject var actionEngine: ActionEngine
    @EnvironmentObject var thermalEngine: ThermalEngine
    @EnvironmentObject var notificationEngine: NotificationEngine

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView(selectedTab: $selectedTab)

                Rectangle()
                    .fill(Color.borderSubtle)
                    .frame(width: 1)

                mainContent
            }
            .background(backgroundGradient)

            ToastOverlay()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let tab = notification.object as? SidebarTab {
                withAnimation(.pulseSpring) {
                    selectedTab = tab
                }
            }
        }
        .onReceive(metricsEngine.$memory) { mem in
            actionEngine.generateSuggestions(
                processes: processEngine.processes,
                memoryPressure: mem.pressure
            )
        }
    }

    private var mainContent: some View {
        ZStack {
            Circle()
                .fill(accentGlow)
                .frame(width: 500, height: 500)
                .blur(radius: 180)
                .offset(x: -150, y: -150)
                .opacity(0.08)

            Group {
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .cpu:
                    CPUDetailView()
                case .memory:
                    MemoryDetailView()
                case .storage:
                    StorageDetailView()
                case .network:
                    NetworkDetailView()
                case .gpu:
                    GPUDetailView()
                case .thermal:
                    ThermalDetailView()
                case .processes:
                    ProcessListView()
                case .booster:
                    BoosterView()
                case .widgets:
                    WidgetsManagerView()
                case .settings:
                    SettingsView()
                }
            }
            .transition(.opacity.animation(.pulseGentle))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.055, green: 0.055, blue: 0.11),
                Color(red: 0.035, green: 0.035, blue: 0.075)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var accentGlow: RadialGradient {
        RadialGradient(
            colors: [Color.pulseBlue.opacity(0.2), .clear],
            center: .center,
            startRadius: 50,
            endRadius: 250
        )
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var thermalEngine: ThermalEngine

    var body: some View {
        VStack(spacing: 0) {
            // Branding
            branding
                .padding(.vertical, 14)

            Divider().background(Color.borderSubtle)

            // Navigation
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(SidebarTab.grouped, id: \.0) { section, tabs in
                        VStack(spacing: 2) {
                            Text(section.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.textTertiary)
                                .tracking(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.top, 12)
                                .padding(.bottom, 4)

                            ForEach(tabs, id: \.self) { tab in
                                SidebarButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab,
                                    onTap: {
                                        withAnimation(.pulseSpring) {
                                            selectedTab = tab
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }

            Spacer()

            // Settings button (always visible at bottom)
            VStack(spacing: 0) {
                Divider().background(Color.borderSubtle)

                SidebarButton(
                    tab: .settings,
                    isSelected: selectedTab == .settings,
                    onTap: {
                        withAnimation(.pulseSpring) {
                            selectedTab = .settings
                        }
                    }
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }

            // Live status strip
            liveStatus
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            Divider().background(Color.borderSubtle)

            // Uptime
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.textTertiary)
                Text(formatUptime(metrics.uptime))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.vertical, 6)
        }
        .frame(width: 180)
        .background(.ultraThinMaterial)
    }

    private var branding: some View {
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.pulseBlue)

                Text("PulseDesk")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
            }

            Text("v2.0 — System Monitor")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var liveStatus: some View {
        VStack(spacing: 5) {
            MiniStatusItem(
                icon: "cpu",
                label: "CPU",
                value: String(format: "%.0f%%", metrics.cpu.totalUsage),
                color: Color.forUsage(metrics.cpu.totalUsage)
            )
            MiniStatusItem(
                icon: "memorychip",
                label: "RAM",
                value: String(format: "%.0f%%", metrics.memory.usagePercent),
                color: Color.forUsage(metrics.memory.usagePercent)
            )
            MiniStatusItem(
                icon: "internaldrive",
                label: "Disk",
                value: String(format: "%.0f%%", metrics.disk.usagePercent),
                color: Color.forUsage(metrics.disk.usagePercent)
            )
            MiniStatusItem(
                icon: thermalEngine.thermalIcon,
                label: "Temp",
                value: thermalEngine.thermal.thermalState.rawValue,
                color: Color.forThermal(thermalEngine.thermal.thermalState)
            )
        }
    }
}

// MARK: - Sidebar Button

struct SidebarButton: View {
    let tab: SidebarTab
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 9) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.pulseBlue : Color.textSecondary)
                    .frame(width: 16)

                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)

                Spacer()

                Text(tab.shortcut)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.pulseBlue.opacity(0.12) : isHovered ? Color.surfaceHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.pulseSnap, value: isSelected)
        .animation(.pulseSnap, value: isHovered)
    }
}

// MARK: - Mini Status Item

struct MiniStatusItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 30, alignment: .leading)

            Spacer()

            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}
