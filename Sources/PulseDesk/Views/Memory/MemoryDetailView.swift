import SwiftUI

// MARK: - Memory Detail View

struct MemoryDetailView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var settings: AppSettings

    private var pressureColor: Color {
        Color.forPressure(metrics.memory.pressure)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                memoryHeader

                // Time series
                GlassPanel(title: "Memory Usage Over Time", icon: "chart.xyaxis.line", color: .pulsePurple) {
                    TimeSeriesChart(
                        series: [
                            ChartSeries(name: "Usage", data: metrics.memory.history, color: .pulsePurple)
                        ],
                        maxValue: 100,
                        formatValue: { String(format: "%.0f%%", $0) },
                        refreshInterval: settings.refreshInterval
                    )
                    .frame(height: 200)
                }

                // Stats row
                HStack(spacing: 14) {
                    StatBox(title: "Used", value: formatBytes(metrics.memory.used), color: .pulseOrange)
                    StatBox(title: "Active", value: formatBytes(metrics.memory.active), color: .pulseBlue)
                    StatBox(title: "Wired", value: formatBytes(metrics.memory.wired), color: .pulseRed)
                    StatBox(title: "Free", value: formatBytes(metrics.memory.free), color: .pulseGreen)
                }

                // Memory composition
                GlassPanel(title: "Memory Composition", icon: "chart.bar.fill", color: .pulsePurple) {
                    VStack(spacing: 14) {
                        // Large composition bar
                        MemoryCompositionBar(metrics: metrics.memory)
                            .frame(height: 10)

                        // Legend
                        HStack(spacing: 16) {
                            compositionLegend(label: "Active", color: .pulseOrange, bytes: metrics.memory.active)
                            compositionLegend(label: "Wired", color: .pulseRed, bytes: metrics.memory.wired)
                            compositionLegend(label: "Compressed", color: .pulsePurple, bytes: metrics.memory.compressed)
                            compositionLegend(label: "Free", color: .pulseGreen, bytes: metrics.memory.free)
                            Spacer()
                        }

                        // Breakdown rows
                        VStack(spacing: 6) {
                            compositionRow(label: "Active", bytes: metrics.memory.active, color: .pulseOrange, total: metrics.memory.total)
                            compositionRow(label: "Wired", bytes: metrics.memory.wired, color: .pulseRed, total: metrics.memory.total)
                            compositionRow(label: "Compressed", bytes: metrics.memory.compressed, color: .pulsePurple, total: metrics.memory.total)
                            compositionRow(label: "Inactive", bytes: metrics.memory.inactive, color: .pulseYellow, total: metrics.memory.total)
                            compositionRow(label: "Free", bytes: metrics.memory.free, color: .pulseGreen, total: metrics.memory.total)
                        }
                    }
                }

                // Pressure & Swap
                HStack(spacing: 14) {
                    // Pressure card
                    GlassPanel(title: "Memory Pressure", icon: "gauge.with.dots.needle.33percent", color: pressureColor) {
                        VStack(spacing: 10) {
                            Text(metrics.memory.pressure.rawValue)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(pressureColor)

                            // Pressure indicator
                            HStack(spacing: 4) {
                                ForEach(["Normal", "Warning", "Critical"], id: \.self) { level in
                                    let isActive = metrics.memory.pressure.rawValue == level
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(isActive ? pressureColor : Color.white.opacity(0.06))
                                        .frame(height: 4)
                                }
                            }

                            Text(pressureDescription)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Swap card
                    GlassPanel(title: "Swap Usage", icon: "arrow.triangle.swap", color: .pulseRed) {
                        VStack(spacing: 10) {
                            if metrics.memory.swapTotal > 0 {
                                let swapPercent = Double(metrics.memory.swapUsed) / Double(max(metrics.memory.swapTotal, 1)) * 100

                                CircularGauge(
                                    value: swapPercent,
                                    color: swapPercent > 50 ? .pulseRed : .pulseYellow,
                                    lineWidth: 6
                                )
                                .frame(width: 60, height: 60)

                                VStack(spacing: 3) {
                                    MetricRow(label: "Used", value: formatBytes(metrics.memory.swapUsed), color: .pulseRed)
                                    MetricRow(label: "Total", value: formatBytes(metrics.memory.swapTotal))
                                }
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color.pulseGreen)

                                    Text("No swap in use")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                }

                // Memory info
                GlassPanel(title: "Memory Info", icon: "info.circle", color: .textSecondary) {
                    VStack(spacing: 4) {
                        MetricRow(label: "Total Memory", value: formatBytes(metrics.memory.total))
                        MetricRow(label: "Usage", value: String(format: "%.1f%%", metrics.memory.usagePercent))
                        MetricRow(label: "Compressed Ratio", value: String(format: "%.1f%%", metrics.memory.compressedPercent))
                        if metrics.memory.swapUsed > 0 {
                            MetricRow(label: "Swap Used", value: formatBytes(metrics.memory.swapUsed), color: .pulseRed)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Header

    private var memoryHeader: some View {
        HStack(spacing: 16) {
            CircularGauge(
                value: metrics.memory.usagePercent,
                color: Color.forUsage(metrics.memory.usagePercent),
                lineWidth: 10
            )
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Memory")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text(metrics.memory.pressure.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(pressureColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(pressureColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text("\(formatBytes(metrics.memory.used)) of \(formatBytes(metrics.memory.total)) used")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                Text("\(formatBytes(metrics.memory.free)) available")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.pulseGreen)
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private func compositionLegend(label: String, color: Color, bytes: UInt64) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func compositionRow(label: String, bytes: UInt64, color: Color, total: UInt64) -> some View {
        let percent = total > 0 ? Double(bytes) / Double(total) * 100 : 0
        return HStack(spacing: 8) {
            Circle().fill(color).frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 80, alignment: .leading)

            UsageBar(value: percent, color: color, height: 5)

            Text(formatBytes(bytes))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.1f%%", percent))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var pressureDescription: String {
        switch metrics.memory.pressure {
        case .normal: return "System memory is in a healthy state"
        case .warning: return "Memory pressure is elevated — consider closing apps"
        case .critical: return "System is under high memory pressure"
        }
    }
}
