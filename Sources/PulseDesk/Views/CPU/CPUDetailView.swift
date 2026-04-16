import SwiftUI

// MARK: - CPU Detail View

struct CPUDetailView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                cpuHeader

                // Main time series
                GlassPanel(title: "CPU Usage Over Time", icon: "chart.xyaxis.line", color: .pulseBlue) {
                    TimeSeriesChart(
                        series: [
                            ChartSeries(name: "User", data: metrics.cpu.userHistory, color: .pulseBlue),
                            ChartSeries(name: "System", data: metrics.cpu.systemHistory, color: .pulseOrange),
                            ChartSeries(name: "Total", data: metrics.cpu.history, color: .pulseGreen)
                        ],
                        maxValue: 100,
                        formatValue: { String(format: "%.0f%%", $0) },
                        refreshInterval: settings.refreshInterval
                    )
                    .frame(height: 200)
                }

                // Stats row
                HStack(spacing: 14) {
                    StatBox(title: "Total", value: String(format: "%.1f%%", metrics.cpu.totalUsage), color: Color.forUsage(metrics.cpu.totalUsage))
                    StatBox(title: "User", value: String(format: "%.1f%%", metrics.cpu.userUsage), color: .pulseBlue)
                    StatBox(title: "System", value: String(format: "%.1f%%", metrics.cpu.systemUsage), color: .pulseOrange)
                    StatBox(title: "Idle", value: String(format: "%.1f%%", metrics.cpu.idleUsage), color: .pulseGreen)
                }

                // Load average
                GlassPanel(title: "Load Average", icon: "chart.bar.fill", color: .pulseOrange) {
                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            loadAverageItem(label: "1 min", value: metrics.cpu.loadAverage[safe: 0] ?? 0)
                            loadAverageItem(label: "5 min", value: metrics.cpu.loadAverage[safe: 1] ?? 0)
                            loadAverageItem(label: "15 min", value: metrics.cpu.loadAverage[safe: 2] ?? 0)
                            Spacer()
                        }

                        // Load bars
                        VStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                let val = metrics.cpu.loadAverage[safe: i] ?? 0
                                let labels = ["1m", "5m", "15m"]
                                let maxLoad = Double(metrics.cpu.coreCount)
                                HStack(spacing: 8) {
                                    Text(labels[i])
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color.textTertiary)
                                        .frame(width: 20, alignment: .trailing)

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white.opacity(0.04))

                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.forUsage(val / maxLoad * 100))
                                                .frame(width: geo.size.width * min(CGFloat(val / maxLoad), 1.0))
                                                .animation(.pulseSpring, value: val)
                                        }
                                    }
                                    .frame(height: 6)

                                    Text(String(format: "%.2f", val))
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color.textSecondary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                            }
                        }
                    }
                }

                // Per-core heatmap
                if !metrics.cpu.perCoreUsage.isEmpty {
                    GlassPanel(title: "Per-Core Usage", icon: "square.grid.3x3.fill", color: .pulsePurple) {
                        VStack(spacing: 8) {
                            let columns = min(metrics.cpu.coreCount, 10)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: columns), spacing: 3) {
                                ForEach(0..<metrics.cpu.perCoreUsage.count, id: \.self) { i in
                                    VStack(spacing: 2) {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.forUsage(metrics.cpu.perCoreUsage[i]).opacity(max(0.15, metrics.cpu.perCoreUsage[i] / 100)))
                                            .frame(height: 24)
                                            .overlay(
                                                Text(String(format: "%.0f", metrics.cpu.perCoreUsage[i]))
                                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                    .foregroundStyle(.white.opacity(metrics.cpu.perCoreUsage[i] > 15 ? 0.9 : 0.3))
                                            )
                                            .animation(.pulseGentle, value: metrics.cpu.perCoreUsage[i])

                                        Text("C\(i)")
                                            .font(.system(size: 7, weight: .medium))
                                            .foregroundStyle(Color.textTertiary)
                                    }
                                }
                            }

                            // Summary
                            HStack(spacing: 16) {
                                MetricRow(label: "Active Cores", value: "\(metrics.cpu.perCoreUsage.filter { $0 > 5 }.count) / \(metrics.cpu.coreCount)")
                                Spacer()
                                MetricRow(label: "Max Core", value: String(format: "%.0f%%", metrics.cpu.perCoreUsage.max() ?? 0))
                                Spacer()
                                MetricRow(label: "Avg Core", value: String(format: "%.0f%%", metrics.cpu.perCoreUsage.isEmpty ? 0 : metrics.cpu.perCoreUsage.reduce(0, +) / Double(metrics.cpu.perCoreUsage.count)))
                            }
                        }
                    }
                }

                // CPU info
                GlassPanel(title: "Processor Info", icon: "info.circle", color: .textSecondary) {
                    VStack(spacing: 4) {
                        MetricRow(label: "Physical Cores", value: "\(metrics.cpu.coreCount)")
                        MetricRow(label: "Logical Cores", value: "\(metrics.cpu.threadCount)")
                        MetricRow(label: "Architecture", value: "ARM64")
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Header

    private var cpuHeader: some View {
        HStack(spacing: 16) {
            CircularGauge(
                value: metrics.cpu.totalUsage,
                color: Color.forUsage(metrics.cpu.totalUsage),
                lineWidth: 10
            )
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text("CPU")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 12) {
                    Label("\(metrics.cpu.coreCount) cores", systemImage: "cpu")
                    Label("\(metrics.cpu.threadCount) threads", systemImage: "point.3.connected.trianglepath.dotted")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)

                if metrics.cpu.history.count > 2 {
                    HStack(spacing: 4) {
                        TrendIndicator(
                            current: metrics.cpu.totalUsage,
                            previous: metrics.cpu.history.dropLast().last ?? 0
                        )
                        Text("vs previous")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private func loadAverageItem(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.2f", value))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.forUsage(value / Double(max(metrics.cpu.coreCount, 1)) * 100))
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
