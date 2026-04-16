import SwiftUI

enum SidebarTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case processes = "Processes"
    case booster = "Booster"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .processes: return "list.bullet.rectangle"
        case .booster: return "bolt.circle"
        }
    }

    var shortcut: String {
        switch self {
        case .dashboard: return "1"
        case .processes: return "2"
        case .booster: return "3"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: SidebarTab = .dashboard
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

            // Toast notifications overlay
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
            // Ambient glow behind content
            Circle()
                .fill(accentGlow)
                .frame(width: 500, height: 500)
                .blur(radius: 180)
                .offset(x: -150, y: -150)
                .opacity(0.08)

            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .processes:
                    ProcessListView()
                case .booster:
                    BoosterView()
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
                .padding(.vertical, 18)

            Divider().background(Color.borderSubtle)

            // Navigation
            VStack(spacing: 2) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
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
            .padding(.horizontal, 10)
            .padding(.top, 10)

            Spacer()

            // Live status strip
            liveStatus
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

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
            .padding(.vertical, 8)
        }
        .frame(width: 170)
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

            Text("System Monitor")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var liveStatus: some View {
        VStack(spacing: 6) {
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
                icon: thermalEngine.thermalIcon,
                label: "Thermal",
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
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.pulseBlue : Color.textSecondary)
                    .frame(width: 18)

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)

                Spacer()

                Text(tab.shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                .frame(width: 38, alignment: .leading)

            Spacer()

            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}
