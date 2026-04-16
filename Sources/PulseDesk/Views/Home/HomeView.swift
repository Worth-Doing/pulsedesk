import SwiftUI

// MARK: - Home View (Overview Dashboard)

struct HomeView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var thermalEngine: ThermalEngine
    @EnvironmentObject var processEngine: ProcessEngine
    @Binding var selectedTab: SidebarTab

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // System info header
                systemHeader

                // Quick status strip
                StatusBar()

                // Hardware metrics grid
                Text("HARDWARE METRICS")
                    .sectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    // CPU
                    MetricOverviewCard(
                        title: "CPU",
                        icon: "cpu",
                        value: String(format: "%.1f%%", metrics.cpu.totalUsage),
                        color: Color.forUsage(metrics.cpu.totalUsage),
                        sparkline: metrics.cpu.history,
                        maxValue: 100,
                        details: [
                            ("User", String(format: "%.1f%%", metrics.cpu.userUsage)),
                            ("System", String(format: "%.1f%%", metrics.cpu.systemUsage)),
                            ("Cores", "\(metrics.cpu.coreCount)")
                        ]
                    ) { selectedTab = .cpu }

                    // Memory
                    MetricOverviewCard(
                        title: "Memory",
                        icon: "memorychip",
                        value: String(format: "%.1f%%", metrics.memory.usagePercent),
                        color: Color.forUsage(metrics.memory.usagePercent),
                        sparkline: metrics.memory.history,
                        maxValue: 100,
                        details: [
                            ("Used", formatBytes(metrics.memory.used)),
                            ("Free", formatBytes(metrics.memory.free)),
                            ("Pressure", metrics.memory.pressure.rawValue)
                        ]
                    ) { selectedTab = .memory }

                    // Storage
                    MetricOverviewCard(
                        title: "Storage",
                        icon: "internaldrive",
                        value: String(format: "%.1f%%", metrics.disk.usagePercent),
                        color: Color.forUsage(metrics.disk.usagePercent),
                        sparkline: metrics.disk.readHistory,
                        maxValue: max(metrics.disk.readHistory.max() ?? 1, 1024),
                        details: [
                            ("Used", formatBytes(metrics.disk.usedSpace)),
                            ("Free", formatBytes(metrics.disk.freeSpace)),
                            ("Total", formatBytes(metrics.disk.totalSpace))
                        ]
                    ) { selectedTab = .storage }

                    // Network
                    MetricOverviewCard(
                        title: "Network",
                        icon: "network",
                        value: formatSpeed(metrics.network.downloadSpeed),
                        color: .pulseCyan,
                        sparkline: metrics.network.downloadHistory,
                        maxValue: max(metrics.network.downloadHistory.max() ?? 1, 1024),
                        details: [
                            ("Download", formatSpeed(metrics.network.downloadSpeed)),
                            ("Upload", formatSpeed(metrics.network.uploadSpeed)),
                            ("Total In", formatBytes(metrics.network.bytesReceived))
                        ]
                    ) { selectedTab = .network }

                    // GPU
                    MetricOverviewCard(
                        title: "GPU",
                        icon: "gpu",
                        value: String(format: "%.0f%%", metrics.gpu.utilization),
                        color: Color.forUsage(metrics.gpu.utilization),
                        sparkline: metrics.gpu.history,
                        maxValue: 100,
                        details: [
                            ("Utilization", String(format: "%.0f%%", metrics.gpu.utilization)),
                            ("VRAM", formatBytes(metrics.gpu.memoryUsed)),
                            ("Type", "Apple Silicon")
                        ]
                    ) { selectedTab = .gpu }

                    // Thermal
                    MetricOverviewCard(
                        title: "Thermal",
                        icon: thermalEngine.thermalIcon,
                        value: thermalEngine.thermal.thermalState.rawValue,
                        color: Color.forThermal(thermalEngine.thermal.thermalState),
                        sparkline: [],
                        maxValue: 100,
                        details: [
                            ("State", thermalEngine.thermal.thermalState.rawValue),
                            ("CPU Temp", thermalEngine.thermal.cpuTemperature.map { String(format: "%.0f°C", $0) } ?? "N/A"),
                            ("Condition", thermalEngine.thermal.thermalState == .nominal ? "Optimal" : "Elevated")
                        ]
                    ) { selectedTab = .thermal }
                }

                // System activity row
                Text("SYSTEM ACTIVITY")
                    .sectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 14) {
                    processCard
                    uptimeCard
                    loadCard
                }
            }
            .padding(18)
        }
    }

    // MARK: - System Header

    private var systemHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Host.current().localizedName ?? "Mac")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.pulseGreen)
                    .frame(width: 6, height: 6)
                Text("System Active")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.pulseGreen.opacity(0.08))
            .clipShape(Capsule())
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Bottom Cards

    private var processCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.pulseBlue)

            Text("\(processEngine.processCount)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Text("Processes")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
        .glassCardHover()
    }

    private var uptimeCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.pulsePurple)

            Text(formatUptime(metrics.uptime))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Uptime")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
        .glassCardHover()
    }

    private var loadCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.pulseOrange)

            Text(metrics.cpu.loadAverage.first.map { String(format: "%.2f", $0) } ?? "0")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Text("Load Avg (1m)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
        .glassCardHover()
    }
}

// MARK: - Metric Overview Card

struct MetricOverviewCard: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    let sparkline: [Double]
    let maxValue: Double
    let details: [(String, String)]
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(.pulseSpring) { onTap() }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(color)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.textTertiary)
                        .opacity(isHovered ? 1 : 0.4)
                }

                // Big value
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())

                // Sparkline
                if !sparkline.isEmpty {
                    LiveGraph(
                        data: sparkline,
                        maxValue: maxValue,
                        color: color,
                        showGrid: false,
                        filled: true
                    )
                    .frame(height: 35)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 35)
                }

                // Detail rows
                VStack(spacing: 3) {
                    ForEach(Array(details.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.0)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                            Spacer()
                            Text(item.1)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .padding(14)
            .glassCard()
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(color: color.opacity(isHovered ? 0.15 : 0), radius: 12)
            .animation(.pulseSpring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
